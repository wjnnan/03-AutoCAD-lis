;;; tb-mod-batchprint.lsp — 批量打印模块（重写版 v2.0）
;;; 引擎：ActiveX vla-PlotToFile 优先（AutoCAD），无 COM 平台降级 -PLOT 兜底
;;; 图框识别：块(INSERT) / 闭合多段线 / 布局 三通道
;;; 输出格式：PDF / DWF / PLT / 直接打印（由打印机名 + 写文件开关决定）
;;; 依赖：uc:* entity:* point:* sel:* curve:* sys:*
;;; 命令：BPT (批量打印) / BPSET (打印设置)

;; ============================================================================
;; 常量
;; ============================================================================

;; 标准纸张尺寸 (mm)，短边在前（竖放），长边在后
(setq *BP:PAPER-SIZES*
  '(("A4" . (210.0 297.0))
    ("A3" . (297.0 420.0))
    ("A2" . (420.0 594.0))
    ("A1" . (594.0 841.0))
    ("A0" . (841.0 1189.0))
    ("A3+" . (297.0 440.0))
    ("A2+" . (420.0 620.0))
    ("A1+" . (594.0 880.0))
    ("A0+" . (841.0 1240.0))))

;; 标准比例档（工程制图常用）
(setq *BP:STANDARD-SCALES*
  '(1 1.5 2 2.5 3 4 5 10 15 20 25 30 40 50 100 150 200 250 300 400 500 1000))

;; 图框识别方式
(setq *BP:FRAME-TYPES*
  '(("图框块（按块名）" . "BLOCK")
    ("图框多段线（按图层）" . "PLINE")
    ("布局空间" . "LAYOUT")))

;; 比例模式
(setq *BP:SCALE-MODES*
  '(("自动匹配比例" . "AUTO")
    ("布满图纸" . "FIT")
    ("自定义比例" . "CUSTOM")))

;; 输出格式（决定默认打印机 + 扩展名 + 是否写文件）
(setq *BP:OUTPUT-MODES*
  '(("输出为 PDF" . "PDF")
    ("输出为 DWF" . "DWF")
    ("输出为 PLT" . "PLT")
    ("直接打印到打印机" . "PRINTER")))

;; 颜色模式（经 CTB 打印样式表控制）
(setq *BP:COLOR-MODES*
  '(("彩色" . "C")
    ("灰度" . "G")
    ("黑白" . "M")))

;; 颜色模式 -> CTB 映射
(setq *BP:COLOR-CTB*
  '(("C" . "acad.ctb")
    ("G" . "Grayscale.ctb")
    ("M" . "monochrome.ctb")))

;; AcPlotType 枚举值（ActiveX，跨版本可能微调）
(setq *BP:AC-DISPLAY* 0
      *BP:AC-EXTENTS* 1
      *BP:AC-LIMITS*  2
      *BP:AC-VIEW*    3
      *BP:AC-WINDOW*  4
      *BP:AC-LAYOUT*  5)

;; 当前打印机对应的纸张 canonical 名列表（动态）
(setq *BP:CURRENT-PAPERS* nil)

;; ============================================================================
;; 图纸记录数据结构
;; ============================================================================

(defun bp:make-drawing (handle center w h scale paper draw-num draw-name date rotation layout)
  "构造图纸记录 alist。layout 非 nil 表示布局打印，center/w/h 忽略。"
  (list
    (cons 'handle handle)
    (cons 'center center)
    (cons 'width w)
    (cons 'height h)
    (cons 'scale scale)
    (cons 'paper paper)
    (cons 'draw-num draw-num)
    (cons 'draw-name draw-name)
    (cons 'date date)
    (cons 'rotation rotation)
    (cons 'layout layout)))

(defun bp:drawing-prop (drawing key)
  "读取图纸记录属性。"
  (cdr (assoc key drawing)))

;; ============================================================================
;; 纸张匹配与比例
;; ============================================================================

(defun bp:match-paper (w h / best-name best-diff diff size ww hh)
  "按图框尺寸匹配最接近的标准纸张名。"
  (setq best-name "自定义" best-diff 1e308)
  (foreach paper *BP:PAPER-SIZES*
    (setq size (cdr paper) ww (car size) hh (cadr size))
    ;; 允许横竖两种方向
    (setq diff (min (+ (abs (- w ww)) (abs (- h hh)))
                    (+ (abs (- w hh)) (abs (- h ww)))))
    (if (< diff best-diff)
      (setq best-diff diff best-name (car paper))))
  (if (< best-diff (* (max w h) 0.15)) best-name "自定义"))

(defun bp:nearest-standard-scale (raw / best best-diff diff s)
  "把原始比例向下取到最近的标准比例档（保证不溢出）。"
  (setq best 1 best-diff 1e308)
  (foreach s *BP:STANDARD-SCALES*
    (if (>= s raw)
      (setq diff (- s raw))
      (setq diff (* 2 (- raw s))))  ; 向下优先
    (if (< diff best-diff)
      (setq best-diff diff best s)))
  best)

(defun bp:detect-scale (frame-w frame-h paper-w paper-h / scale-w scale-h)
  "图框尺寸 ÷ 纸张尺寸反推比例（1:N）。"
  (if (and frame-w frame-h paper-w paper-h (> paper-w 0) (> paper-h 0))
    (progn
      (setq scale-w (/ frame-w paper-w)
            scale-h (/ frame-h paper-h))
      (bp:nearest-standard-scale (max scale-w scale-h)))
    100))

;; ============================================================================
;; 图框识别
;; ============================================================================

(defun bp:get-block-bbox (e)
  "取块引用的包围盒。ActiveX 优先，无 COM 走纯 Lisp 递归。"
  (if *SYS:HAS-ACTIVEX*
    (entity:get-bbox e 0.0)      ; 第二参数为偏移量，此处不需要留边距
    (entity:block-bbox-pure e)))

(defun bp:attr-val (attrs tags)
  "从属性表按标签名（多个候选）取第一个匹配值。"
  (if (not attrs) nil
    (car (vl-remove nil
      (mapcar
        '(lambda (tag)
           (cdr (assoc (strcase tag)
                  (mapcar '(lambda (a) (cons (strcase (car a)) (cdr a))) attrs))))
        (mapcar 'strcase tags))))))

(defun bp:detect-blocks (block-name / ss result)
  "按块名（支持通配符）选 INSERT 识别图框，读属性。"
  (if (setq ss (ssget "_X" (list '(0 . "INSERT") (cons 2 block-name))))
    (progn
      (setq result nil)
      (sel:for-each ss
        '(lambda (e / bbox attrs w h center draw-num draw-name scale-val date paper-name)
           (setq bbox (bp:get-block-bbox e))
           (if (and bbox (> (distance (car bbox) (cadr bbox)) 1.0))
             (progn
               (setq w (abs (- (caadr bbox) (caar bbox)))
                     h (abs (- (cadadr bbox) (cadar bbox)))
                     center (point:mid (car bbox) (cadr bbox)))
               ;; 读图框属性（图号/图名/比例/日期）
               (setq attrs (entity:get-attribs e))
               (setq draw-num  (bp:attr-val attrs '("图号" "图名" "DRAWING_NO" "DWG_NO" "TUH")))
               (setq draw-name (bp:attr-val attrs '("图名" "图纸名称" "DRAWING_NAME" "TUM")))
               (setq scale-val (bp:attr-val attrs '("比例" "SCALE" "BL")))
               (setq date      (bp:attr-val attrs '("日期" "DATE" "RQ")))
               ;; 解析比例属性 "1:100" -> 100
               (if scale-val
                 (progn
                   (if (wcmatch scale-val "1:*")
                     (setq scale-val (atoi (substr scale-val 3))))
                   (if (and scale-val (not (numberp scale-val)))
                     (setq scale-val (atoi scale-val)))
                   (if (or (not scale-val) (zerop scale-val))
                     (setq scale-val nil))))
               (setq paper-name (bp:match-paper w h))
               (setq result (cons
                 (bp:make-drawing (entity:handle e)
                   center w h
                   (if scale-val scale-val (bp:detect-scale w h
                     (cadr (assoc paper-name *BP:PAPER-SIZES*))
                     (caddr (assoc paper-name *BP:PAPER-SIZES*))))
                   paper-name
                   draw-num draw-name date 0.0 nil)
                 result))))))
      (reverse result))))

(defun bp:detect-plines (layer-name / ss result)
  "按图层选闭合 4 顶点多段线作为图框。"
  (if (setq ss (ssget "_X" (list '(0 . "LWPOLYLINE") (cons 8 layer-name) '(70 . 1) '(90 . 4))))
    (progn
      (setq result nil)
      (sel:for-each ss
        '(lambda (e / bbox w h center paper-name)
           (setq bbox (entity:get-bbox e 0.0))   ; 第二参数为偏移量，此处不需要留边距
           (if (and bbox (> (distance (car bbox) (cadr bbox)) 1.0))
             (progn
               (setq w (abs (- (caadr bbox) (caar bbox)))
                     h (abs (- (cadadr bbox) (cadar bbox)))
                     center (point:mid (car bbox) (cadr bbox))
                     paper-name (bp:match-paper w h))
               (setq result (cons
                 (bp:make-drawing (entity:handle e)
                   center w h
                   (bp:detect-scale w h
                     (if (assoc paper-name *BP:PAPER-SIZES*)
                       (cadr (assoc paper-name *BP:PAPER-SIZES*)) 420)
                     (if (assoc paper-name *BP:PAPER-SIZES*)
                       (caddr (assoc paper-name *BP:PAPER-SIZES*)) 594))
                   paper-name nil nil nil 0.0 nil)
                 result))))))
      (reverse result))))

(defun bp:detect-layouts (/ result lay-name)
  "遍历布局表，产出布局打印记录（非 Model）。"
  (setq result nil)
  (setq lay-name (cdr (assoc 2 (tblnext "LAYOUT" T))))
  (while lay-name
    (if (not (= (strcase lay-name) "MODEL"))
      (setq result (cons
        (bp:make-drawing nil nil 0 0 100 "A3" lay-name lay-name nil 0.0 lay-name)
        result)))
    (setq lay-name (cdr (assoc 2 (tblnext "LAYOUT")))))
  (reverse result))

(defun bp:detect-frames (frame-type frame-value include-model include-layouts / drawings)
  "按设置检测图框，返回图纸列表。"
  (setq drawings nil)
  (if include-model
    (cond
      ((= frame-type "BLOCK") (setq drawings (bp:detect-blocks frame-value)))
      ((= frame-type "PLINE") (setq drawings (bp:detect-plines frame-value)))))
  (if include-layouts
    (setq drawings (append drawings (bp:detect-layouts))))
  drawings)

;; ============================================================================
;; 排序（X / Y 蛇形）
;; ============================================================================

(defun bp:sort-serpentine (drawings / row-tol rows row sorted i result)
  "行优先排序：Y 降序分行（半图框高容差），行内 X 升序，偶数行反转（蛇形）。"
  (if (not drawings) nil
    (progn
      ;; 行容差 = 首图框高度的一半
      (setq row-tol (* 0.5
        (cond ((bp:drawing-prop (car drawings) 'height))
              ((bp:drawing-prop (car drawings) 'width))
              (0.0))))
      (if (< row-tol 1.0) (setq row-tol 1.0))
      ;; 先按 Y 降序、X 升序粗排
      (setq sorted
        (vl-sort (append drawings nil)
          '(lambda (a b)
             (if (and (bp:drawing-prop a 'center) (bp:drawing-prop b 'center))
               (if (> (abs (- (cadr (bp:drawing-prop a 'center))
                              (cadr (bp:drawing-prop b 'center)))) row-tol)
                 (> (cadr (bp:drawing-prop a 'center)) (cadr (bp:drawing-prop b 'center)))
                 (< (car (bp:drawing-prop a 'center)) (car (bp:drawing-prop b 'center))))
               T))))
      ;; 分组到行
      (setq rows nil)
      (foreach d sorted
        (if (and rows
                 (bp:drawing-prop d 'center)
                 (bp:drawing-prop (caar rows) 'center)
                 (<= (abs (- (cadr (bp:drawing-prop d 'center))
                             (cadr (bp:drawing-prop (caar rows) 'center)))) row-tol))
          (setq rows (cons (append (car rows) (list d)) (cdr rows)))
          (setq rows (cons (list d) rows))))
      (setq rows (reverse rows))
      ;; 偶数行（从 0 起）反转 X 实现蛇形
      (setq result nil)
      (setq i 0)
      (foreach row rows
        (if (= (rem i 2) 1)
          (setq row (reverse row)))
        (foreach d row (setq result (cons d result)))
        (setq i (1+ i)))
      (reverse result))))

(defun bp:sort-drawings (drawings method)
  "排序分发。method: 'X 简单左到右，'Y 上到下，'S 蛇形。"
  (cond
    ((eq method 'X)
     (vl-sort (append drawings nil)
       '(lambda (a b)
          (if (and (bp:drawing-prop a 'center) (bp:drawing-prop b 'center))
            (< (car (bp:drawing-prop a 'center)) (car (bp:drawing-prop b 'center)))
            T))))
    ((eq method 'Y)
     (vl-sort (append drawings nil)
       '(lambda (a b)
          (if (and (bp:drawing-prop a 'center) (bp:drawing-prop b 'center))
            (> (cadr (bp:drawing-prop a 'center)) (cadr (bp:drawing-prop b 'center)))
            T))))
    ((eq method 'S) (bp:sort-serpentine drawings))
    (t drawings)))

;; ============================================================================
;; 命名
;; ============================================================================

(defun bp:zero-pad (n width)
  "整数零填充到指定宽度。"
  (setq n (itoa n))
  (while (< (strlen n) width) (setq n (strcat "0" n)))
  n)

(defun bp:make-filename (drawing rule index / num name scale date result)
  "按命名规则生成文件名。{序号} 零填充 3 位。"
  (setq num   (if (bp:drawing-prop drawing 'draw-num) (bp:drawing-prop drawing 'draw-num) "")
        name  (if (bp:drawing-prop drawing 'draw-name) (bp:drawing-prop drawing 'draw-name) "")
        scale (itoa (if (bp:drawing-prop drawing 'scale) (bp:drawing-prop drawing 'scale) 100))
        date  (if (bp:drawing-prop drawing 'date) (bp:drawing-prop drawing 'date) ""))
  ;; 基础名：图号-图名，缺项回退序号
  (setq result
    (cond
      ((and (/= num "") (/= name "")) (strcat num "-" name))
      ((/= num "") num)
      ((/= name "") name)
      (t (strcat "图纸_" (bp:zero-pad index 3)))))
  ;; 用户自定义规则（含 {token} 时覆盖）
  (if (and rule (/= rule "") (wcmatch rule "*{*"))
    (progn
      (setq result rule)
      (setq result (vl-string-subst (bp:zero-pad index 3) "{序号}" result))
      (setq result (vl-string-subst num "{图号}" result))
      (setq result (vl-string-subst name "{图名}" result))
      (setq result (vl-string-subst scale "{比例}" result))
      (setq result (vl-string-subst date "{日期}" result))))
  result)

(defun bp:check-duplicates (drawings / seen dups draw-num)
  "检测重复图号。"
  (setq seen nil dups nil)
  (foreach d drawings
    (setq draw-num (bp:drawing-prop d 'draw-num))
    (if draw-num
      (if (member draw-num seen)
        (if (not (member draw-num dups)) (setq dups (cons draw-num dups)))
        (setq seen (cons draw-num seen)))))
  (reverse dups))

;; ============================================================================
;; 设备 / 纸张枚举（消除硬编码）
;; ============================================================================

(defun bp:get-printers (/ doc layout lst)
  "枚举本机打印设备（含虚拟 PDF/DWF 打印机）。"
  (setq lst nil)
  (if (and *SYS:HAS-ACTIVEX* (uc:com-available-p))
    (progn
      (setq doc (vla-get-activedocument (vlax-get-acad-object))
            layout (vla-get-activelayout doc))
      (setq lst (vl-catch-all-apply
        '(lambda nil
           (vlax-safearray->list (vlax-variant-value (vla-GetPlotDeviceNames layout))))))
      (if (vl-catch-all-error-p lst) (setq lst nil))))
  (if (not lst)
    (setq lst '("DWG To PDF.pc3" "DWF6 ePlot.pc3" "Default Windows System Printer.pc3")))
  lst)

(defun bp:get-papers (printer / doc layout lst)
  "枚举指定打印机的纸张（canonical 名）。"
  (setq lst nil)
  (if (and *SYS:HAS-ACTIVEX* (uc:com-available-p))
    (progn
      (setq doc (vla-get-activedocument (vlax-get-acad-object))
            layout (vla-get-activelayout doc))
      (if (and printer (/= printer ""))
        (progn
          (vla-put-configname layout printer)
          (vl-catch-all-apply 'vla-RefreshPlotDeviceInfo (list layout))
          (setq lst (vl-catch-all-apply
            '(lambda nil
               (vlax-safearray->list (vlax-variant-value (vla-GetCanonicalMediaNames layout))))))
          (if (vl-catch-all-error-p lst) (setq lst nil))))))
  ;; 回退：标准纸张名
  (if (not lst)
    (setq lst (mapcar 'car *BP:PAPER-SIZES*)))
  lst)

;; ============================================================================
;; 打印执行
;; ============================================================================

(defun bp:plottype (key)
  "AcPlotType 常量，兼容 boundp 探测。"
  (cond
    ((= key 'window) (if (and (boundp 'acWindow) (numberp acWindow)) acWindow *BP:AC-WINDOW*))
    ((= key 'layout) (if (and (boundp 'acLayout) (numberp acLayout)) acLayout *BP:AC-LAYOUT*))
    (t *BP:AC-WINDOW*)))

(defun bp:plot-activex (drawing settings filename / doc layout plot printer paper
                         scale-mode custom-scale ctb updown center w h rot
                         min-pt max-pt target-layout)
  "ActiveX 打印单张图纸（vla-PlotToFile / PlotToDevice）。"
  (setq doc    (vla-get-activedocument (vlax-get-acad-object))
        layout (vla-get-activelayout doc)
        plot   (vla-get-plot doc))
  (setq printer     (cdr (assoc 'printer settings))
        paper       (cdr (assoc 'paper settings))
        scale-mode  (cdr (assoc 'scale_mode settings))
        custom-scale (cdr (assoc 'custom_scale settings))
        ctb         (cdr (assoc 'ctb settings))
        updown      (= (cdr (assoc 'plot_upside_down settings)) "1"))
  ;; 配置打印机（必须 RefreshPlotDeviceInfo）
  (vla-put-configname layout printer)
  (vl-catch-all-apply 'vla-RefreshPlotDeviceInfo (list layout))
  ;; 纸张（canonical 名）
  (if (and paper (/= paper ""))
    (vl-catch-all-apply 'vla-put-canonicalmedianename (list layout paper)))
  ;; 方向
  (if (bp:drawing-prop drawing 'layout)
    (vla-put-plotrotation layout (if updown 2 0))
    (progn
      (setq w (bp:drawing-prop drawing 'width)
            h (bp:drawing-prop drawing 'height))
      (setq rot (if (> w h) 0 1))  ; 横 0 / 竖 90
      (if updown (setq rot (+ rot 2)))
      (vla-put-plotrotation layout rot)))
  ;; 居中 / 线宽 / 样式
  (vla-put-centerplot layout :vlax-true)
  (vla-put-plotwithlineweights layout :vlax-true)
  (vla-put-plotwithplotstyles layout :vlax-true)
  (if (and ctb (/= ctb "") (/= (strcase ctb) "NONE"))
    (vl-catch-all-apply 'vla-put-stylesheet (list layout ctb)))
  ;; 比例
  (cond
    ((= scale-mode "FIT")
     (vla-put-usestandardscale layout :vlax-true)
     (vla-put-standardscale layout 0))  ; acScaleToFit = 0
    ((= scale-mode "CUSTOM")
     (vla-put-usestandardscale layout :vlax-false)
     (vla-SetCustomScale layout 1.0 (if custom-scale custom-scale 100)))
    ((= scale-mode "AUTO")
     (vla-put-usestandardscale layout :vlax-false)
     (vla-SetCustomScale layout 1.0 (bp:drawing-prop drawing 'scale))))
  ;; 打印区域：布局 vs 窗口
  (if (bp:drawing-prop drawing 'layout)
    ;; 布局打印：acLayout 类型，切到该布局
    (progn
      (vla-put-plottype layout (bp:plottype 'layout))
      (setq target-layout (vl-catch-all-apply 'vla-item
        (list (vla-get-layouts doc) (bp:drawing-prop drawing 'layout))))
      (if (and target-layout (not (vl-catch-all-error-p target-layout)))
        (vl-catch-all-apply 'vla-put-activelayout (list doc target-layout))))
    ;; 窗口打印：每帧单独设窗口
    (progn
      (setq center (bp:drawing-prop drawing 'center)
            w (bp:drawing-prop drawing 'width)
            h (bp:drawing-prop drawing 'height))
      (setq min-pt (list (- (car center) (* w 0.5)) (- (cadr center) (* h 0.5)))
            max-pt (list (+ (car center) (* w 0.5)) (+ (cadr center) (* h 0.5))))
      (vla-SetWindowToPlot layout (vlax-3d-point min-pt) (vlax-3d-point max-pt))
      (vla-put-plottype layout (bp:plottype 'window))))
  ;; 输出：写文件 vs 直接打印
  (if (and filename (/= filename ""))
    (vla-PlotToFile plot filename)
    (vla-PlotToDevice plot)))

(defun bp:plot-command (drawing settings filename / printer paper orientation
                         center w h min-pt max-pt plot-scale ctb updown)
  "-PLOT 命令兜底（无 COM 平台）。简化序列，布局打印不支持。"
  (setq printer (cdr (assoc 'printer settings))
        paper   (cdr (assoc 'paper settings))
        center  (bp:drawing-prop drawing 'center)
        w       (bp:drawing-prop drawing 'width)
        h       (bp:drawing-prop drawing 'height)
        orientation (if (> w h) "LANDSCAPE" "PORTRAIT")
        plot-scale (if (= (cdr (assoc 'scale_mode settings)) "FIT")
                     "FIT"
                     (strcat "1:" (itoa (bp:drawing-prop drawing 'scale))))
        ctb     (cdr (assoc 'ctb settings))
        updown  (if (= (cdr (assoc 'plot_upside_down settings)) "1") "Y" "N"))
  (if (and center w h)
    (progn
      (setq min-pt (list (- (car center) (* w 0.5)) (- (cadr center) (* h 0.5)))
            max-pt (list (+ (car center) (* w 0.5)) (+ (cadr center) (* h 0.5))))
      (if (and filename (/= filename ""))
        (command "_.-PLOT" "Y" "Model" printer paper "M" orientation updown
          "W" min-pt max-pt plot-scale "C" "Y" (if ctb ctb "monochrome.ctb")
          "Y" "A" "Y" filename "N" "Y")
        (command "_.-PLOT" "Y" "Model" printer paper "M" orientation updown
          "W" min-pt max-pt plot-scale "C" "Y" (if ctb ctb "monochrome.ctb")
          "Y" "A" "N" "N" "Y")))))

(defun bp:plot-one (drawing settings filename)
  "打印单张图纸。有 COM 走 ActiveX，无 COM 走 -PLOT 兜底。"
  (if (and *SYS:HAS-ACTIVEX* (uc:com-available-p))
    (bp:plot-activex drawing settings filename)
    (bp:plot-command drawing settings filename)))

(defun bp:execute-print (drawings settings / printer paper scale-mode custom-scale
                          ctb output-mode output-path name-rule updown i total
                          filename pdf-list bg-old ext)
  "批量打印主循环。"
  (setq printer (cdr (assoc 'printer settings))
        paper   (cdr (assoc 'paper settings))
        scale-mode (cdr (assoc 'scale_mode settings))
        custom-scale (cdr (assoc 'custom_scale settings))
        ctb      (cdr (assoc 'ctb settings))
        output-mode (cdr (assoc 'output_mode settings))
        output-path (cdr (assoc 'output_path settings))
        name-rule (cdr (assoc 'name_rule settings))
        updown   (= (cdr (assoc 'plot_upside_down settings)) "1")
        total    (length drawings)
        i 0
        pdf-list nil)
  ;; 输出目录
  (if (and (not (= output-mode "PRINTER")) output-path (/= output-path "")
           (not (findfile output-path)))
    (vl-catch-all-apply 'vl-mkdir (list output-path)))
  ;; 关后台打印（避免异步并发覆盖文件），结束后恢复
  (setq bg-old (getvar "BACKGROUNDPLOT"))
  (setvar "BACKGROUNDPLOT" 0)
  (princ (strcat "\n[批量打印] 开始，共 " (itoa total) " 张..."))
  (foreach d drawings
    (setq i (1+ i))
    ;; 文件扩展名
    (cond
      ((= output-mode "PDF") (setq ext ".pdf"))
      ((= output-mode "DWF") (setq ext ".dwf"))
      ((= output-mode "PLT") (setq ext ".plt"))
      (t (setq ext "")))
    ;; 文件名与完整路径
    (setq filename
      (if (= output-mode "PRINTER")
        ""  ; 直接打印不写文件
        (strcat output-path "\\" (bp:make-filename d name-rule i) ext)))
    (princ (strcat "\n  [" (itoa i) "/" (itoa total) "] "
                   (if (= filename "") "(直接打印)" filename)))
    ;; 收集 PDF 用于合并
    (if (= output-mode "PDF") (setq pdf-list (cons filename pdf-list)))
    ;; 打印（错误隔离：单张失败不中断整批）
    (vl-catch-all-apply 'bp:plot-one (list d settings filename)))
  (setvar "BACKGROUNDPLOT" bg-old)
  ;; 合并 PDF
  (if (and (= output-mode "PDF") (= (cdr (assoc 'merge_pdf settings)) "1")
           pdf-list (> (length pdf-list) 1))
    (if (bp:merge-pdfs (reverse pdf-list) (strcat output-path "\\全部图纸.pdf"))
      (princ "\n[批量打印] 已合并为 全部图纸.pdf")
      (princ "\n[批量打印] PDF 合并失败（需安装 pdftk）")))
  (princ (strcat "\n[批量打印] 完成，共 " (itoa total) " 张。"))
  (princ))

;; ============================================================================
;; 配置保存 / 加载
;; ============================================================================

(defun bp:save-config (cfg-file settings / fp)
  "保存打印配置到文件（key=value，值经 vl-princ-to-string 可 read 还原）。"
  (if (setq fp (open cfg-file "w"))
    (progn
      (foreach pair settings
        (write-line (strcat (vl-symbol-name (car pair)) "="
                            (vl-princ-to-string (cdr pair))) fp))
      (close fp)
      (princ (strcat "\n配置已保存: " cfg-file)))
    (princ "\n无法保存配置文件。")))

(defun bp:load-config (cfg-file / fp line pos key val settings)
  "从文件读配置，值经 read 还原类型。"
  (if (setq fp (open cfg-file "r"))
    (progn
      (setq settings nil)
      (while (setq line (read-line fp))
        (if (setq pos (vl-string-search "=" line))
          (progn
            (setq key (substr line 1 pos)
                  val (vl-catch-all-apply 'read (list (substr line (+ pos 2)))))
            (if (vl-catch-all-error-p val)
              (setq val (substr line (+ pos 2))))
            (setq settings (cons (cons key val) settings)))))
      (close fp)
      (reverse settings))
    nil))

;; ============================================================================
;; PDF 合并（依赖 pdftk）
;; ============================================================================

(defun bp:merge-pdfs (pdf-files output-file / pdftk-exe cmd n)
  "用 pdftk 合并多个 PDF。"
  (setq cmd (strcat
              (apply 'strcat (mapcar '(lambda (f) (strcat "\"" f "\" ")) pdf-files))
              "cat output \"" output-file "\""))
  (setq pdftk-exe
    (cond
      ((findfile "pdftk.exe"))
      ((findfile "C:\\Program Files (x86)\\PDFtk Server\\bin\\pdftk.exe"))
      ((findfile "C:\\Program Files\\PDFtk Server\\bin\\pdftk.exe"))
      (t "pdftk")))
  (startapp "cmd.exe" (strcat "/c \"" pdftk-exe "\" " cmd))
  (setq n 0)
  (while (and (not (findfile output-file)) (< n 300))
    (vl-catch-all-apply 'command (list "_.DELAY" 100))
    (setq n (1+ n)))
  (if (findfile output-file) T nil))

;; ============================================================================
;; DCL 对话框
;; ============================================================================

(defun bp:val-to-index (val lst / i result)
  "在 alist 中找 cdr=val 的索引（字符串）。"
  (setq i 0 result "0")
  (foreach item lst
    (if (equal (cdr item) val) (setq result (itoa i)))
    (setq i (1+ i)))
  result)

(defun bp:init-dialog (dcl-id / printers)
  "初始化对话框控件。"
  ;; 图框识别方式
  (start_list "frame_type")
  (foreach ft *BP:FRAME-TYPES* (add_list (car ft)))
  (end_list)
  (set_tile "frame_type" "0")
  (set_tile "frame_value" "TK-*")
  ;; 打印机（动态枚举）
  (start_list "printer")
  (foreach p (bp:get-printers) (add_list p))
  (end_list)
  (set_tile "printer" "0")
  ;; 纸张（初始为标准 A 系列，切换打印机后动态刷新）
  (setq *BP:CURRENT-PAPERS* (bp:get-papers (car (bp:get-printers))))
  (start_list "paper")
  (foreach p *BP:CURRENT-PAPERS* (add_list p))
  (end_list)
  (set_tile "paper" "2")  ; 默认 A2
  ;; 比例模式
  (start_list "scale_mode")
  (foreach sm *BP:SCALE-MODES* (add_list (car sm)))
  (end_list)
  (set_tile "scale_mode" "0")
  ;; 打印样式（CTB）
  (start_list "ctb")
  (add_list "monochrome.ctb")
  (add_list "Grayscale.ctb")
  (add_list "acad.ctb")
  (add_list "None")
  (end_list)
  (set_tile "ctb" "0")
  ;; 输出格式
  (start_list "output_mode")
  (foreach om *BP:OUTPUT-MODES* (add_list (car om)))
  (end_list)
  (set_tile "output_mode" "0")
  (bp:select-printer "DWG To PDF")  ; PDF
  ;; 颜色模式
  (start_list "color_mode")
  (foreach cm *BP:COLOR-MODES* (add_list (car cm)))
  (end_list)
  (set_tile "color_mode" "2")  ; 黑白
  ;; 输出路径与命名
  (set_tile "output_path" (getvar "DWGPREFIX"))
  (set_tile "name_rule" "")
  ;; 排序方式
  (start_list "sort_mode")
  (add_list "X排序（左到右）")
  (add_list "Y排序（上到下）")
  (add_list "蛇形排序")
  (end_list)
  (set_tile "sort_mode" "0")
  (set_tile "custom_scale" "100"))

(defun bp:get-settings (/ ft-idx sm-idx om-idx cm-idx printer-idx paper-idx ctb-idx)
  "从对话框读取当前设置。"
  (setq ft-idx (atoi (get_tile "frame_type"))
        sm-idx (atoi (get_tile "scale_mode"))
        om-idx (atoi (get_tile "output_mode"))
        cm-idx (atoi (get_tile "color_mode"))
        printer-idx (atoi (get_tile "printer"))
        paper-idx (atoi (get_tile "paper"))
        ctb-idx (atoi (get_tile "ctb")))
  (list
    (cons 'frame_type  (cdr (nth ft-idx *BP:FRAME-TYPES*)))
    (cons 'frame_value (get_tile "frame_value"))
    (cons 'include_model   (get_tile "include_model"))
    (cons 'include_layouts (get_tile "include_layouts"))
    (cons 'plot_upside_down (get_tile "plot_upside_down"))
    (cons 'printer (nth printer-idx (bp:get-printers)))
    (cons 'paper   (nth paper-idx *BP:CURRENT-PAPERS*))
    (cons 'scale_mode (cdr (nth sm-idx *BP:SCALE-MODES*)))
    (cons 'custom_scale (atoi (get_tile "custom_scale")))
    (cons 'ctb (nth ctb-idx '("monochrome.ctb" "Grayscale.ctb" "acad.ctb" "None")))
    (cons 'color_mode (cdr (nth cm-idx *BP:COLOR-MODES*)))
    (cons 'output_mode (cdr (nth om-idx *BP:OUTPUT-MODES*)))
    (cons 'output_path (get_tile "output_path"))
    (cons 'name_rule (get_tile "name_rule"))
    (cons 'merge_pdf (get_tile "merge_pdf"))))

(defun bp:update-list (drawings duplicates)
  "刷新图纸列表显示，重号加 [!] 前缀。"
  (start_list "drawing_list")
  (mapcar 'add_list
    (mapcar
      '(lambda (d / num name scale paper dup-mark)
         (setq num (if (bp:drawing-prop d 'draw-num) (bp:drawing-prop d 'draw-num) "-")
               name (if (bp:drawing-prop d 'draw-name) (bp:drawing-prop d 'draw-name)
                        (if (bp:drawing-prop d 'layout) (bp:drawing-prop d 'layout) "未命名"))
               scale (itoa (if (bp:drawing-prop d 'scale) (bp:drawing-prop d 'scale) 100))
               paper (if (bp:drawing-prop d 'paper) (bp:drawing-prop d 'paper) "?"))
         (if (member num duplicates) (setq dup-mark "[!] ") (setq dup-mark ""))
         (strcat dup-mark num "  " name "  1:" scale "  " paper))
      drawings))
  (end_list))

;; ============================================================================
;; 命令
;; ============================================================================

(defun c:BPT (/ dcl-fn dcl-id result done drawings settings duplicates
               frame-type frame-value d0 c0 w0 h0)
  "批量打印主命令。"
  (uc:guard-begin '("BACKGROUNDPLOT"))
  (setq dcl-fn (findfile "tb-dcl-batchprint.dcl"))
  (if (not dcl-fn)
    (if (sys:get '*SYS:LOAD-PATH*)
      (setq dcl-fn (uc:path-join (sys:get '*SYS:LOAD-PATH*) "tb-dcl-batchprint.dcl"))))
  (if (not (and dcl-fn (setq dcl-id (load_dialog dcl-fn))))
    (princ "\n[批量打印] 找不到 DCL 文件。")
    (if (not (new_dialog "bp_main" dcl-id))
      (progn (unload_dialog dcl-id) (princ "\n[批量打印] 无法初始化对话框。"))
      (progn
        (bp:init-dialog dcl-id)
        (setq drawings nil done nil)
        (action_tile "btn_pick"
          "(progn
             (setq pick-ent (car (entsel \"\\n拾取图框: \")))
             (if pick-ent
               (progn
                 (setq pick-name (entity:get-name pick-ent))
                 (if (not pick-name) (setq pick-name \"\"))
                 (set_tile \"frame_value\" pick-name))))")
        (action_tile "btn_detect"
          "(progn
             (setq settings (bp:get-settings)
                   frame-type (cdr (assoc 'frame_type settings))
                   frame-value (cdr (assoc 'frame_value settings)))
             (setq drawings (bp:detect-frames frame-type frame-value
                               (= (cdr (assoc 'include_model settings)) \"1\")
                               (= (cdr (assoc 'include_layouts settings)) \"1\")))
             (setq duplicates (bp:check-duplicates drawings))
             (bp:update-list drawings duplicates)
             (set_tile \"status\" (strcat \"检测到 \" (itoa (length drawings)) \" 张图纸\")))")
        (action_tile "btn_sort"
          "(if drawings
             (progn
               (setq drawings (bp:sort-drawings drawings (nth (atoi (get_tile \"sort_mode\")) '(X Y S))))
               (bp:update-list drawings duplicates)
               (set_tile \"status\" \"已按所选方式排序\")))")
        (action_tile "btn_remove"
          "(if drawings
             (progn
               (setq sel-idx (atoi (get_tile \"drawing_list\")))
               (if (nth sel-idx drawings)
                 (progn (setq drawings (vl-remove (nth sel-idx drawings) drawings))
                        (setq duplicates (bp:check-duplicates drawings))
                        (bp:update-list drawings duplicates)))))")
        (action_tile "btn_clear" "(progn (setq drawings nil duplicates nil) (bp:update-list nil nil) (set_tile \"status\" \"列表已清空\"))")
        (action_tile "btn_preview"
          "(if drawings
             (done_dialog 3)
             (set_tile \"status\" \"请先检测图框\"))")
        (action_tile "btn_path"
          "(progn (setq p (getfiled \"选择输出文件夹\" (get_tile \"output_path\") \"\" 33))
             (if p (set_tile \"output_path\" p)))")
        (action_tile "btn_save_cfg"
          "(progn (setq cfg-file (getfiled \"保存配置\" \"\" \"cfg\" 1))
             (if cfg-file (bp:save-config cfg-file (bp:get-settings))))")
        (action_tile "btn_load_cfg"
          "(progn (setq cfg-file (getfiled \"加载配置\" \"\" \"cfg\" 4))
             (if cfg-file
               (progn
                 (setq cfg (bp:load-config cfg-file))
                 (if cfg
                   (foreach pair cfg
                     (if (bp:tile-list (car pair)) (set_tile (car pair) (bp:val-to-index (cdr pair) (bp:tile-list (car pair)))) (set_tile (car pair) (vl-princ-to-string (cdr pair)))))))))")
        (action_tile "printer"
          "(progn
             (setq p (nth (atoi (get_tile \"printer\")) (bp:get-printers)))
             (if p
               (progn
                 (setq *BP:CURRENT-PAPERS* (bp:get-papers p))
                 (start_list \"paper\")
                 (mapcar 'add_list *BP:CURRENT-PAPERS*)
                 (end_list)
                 (set_tile \"paper\" \"0\"))))")
        (action_tile "output_mode"
          "(progn
             (setq om (nth (atoi (get_tile \"output_mode\")) *BP:OUTPUT-MODES*))
             (cond
               ((= (cdr om) \"PDF\") (bp:select-printer \"DWG To PDF\"))
               ((= (cdr om) \"DWF\") (bp:select-printer \"DWF6 ePlot\"))))")
        (action_tile "color_mode"
          "(progn
             (setq cm (nth (atoi (get_tile \"color_mode\")) *BP:COLOR-MODES*))
             (setq ctb-name (cdr (assoc (cdr cm) *BP:COLOR-CTB*)))
             (if ctb-name
               (progn
                 (setq ctb-list '(\"monochrome.ctb\" \"Grayscale.ctb\" \"acad.ctb\" \"None\"))
                 (set_tile \"ctb\" (bp:val-to-index ctb-name
                   (mapcar '(lambda (x) (cons x x)) ctb-list))))))")
        (action_tile "btn_help"
          "(alert \"批量打印 v2.0\\n\\n图框识别:\\n  BLOCK - 按图框块名（支持通配符 *）\\n  PLINE - 按图层闭合多段线\\n  LAYOUT - 布局空间\\n\\n输出格式: PDF / DWF / PLT / 直接打印\\n\\n命名规则(可选，含 {token} 才生效):\\n  {序号} {图号} {图名} {比例} {日期}\")")
        (action_tile "btn_print"
          "(progn
             (if (not drawings)
               (set_tile \"status\" \"请先检测图框\")
               (progn (setq settings (bp:get-settings)) (done_dialog 1))))")
        (action_tile "cancel" "(done_dialog 0)")
        (setq result (start_dialog))
        (unload_dialog dcl-id)
        ;; 预览
        (if (and (= result 3) drawings)
          (progn
            (setq d0 (car drawings)
                  c0 (bp:drawing-prop d0 'center)
                  w0 (bp:drawing-prop d0 'width)
                  h0 (bp:drawing-prop d0 'height))
            (if (and c0 w0 h0)
              (command "_.ZOOM" "_W"
                (list (- (car c0) (* w0 0.8)) (- (cadr c0) (* h0 0.8)))
                (list (+ (car c0) (* w0 0.8)) (+ (cadr c0) (* h0 0.8)))))))
        ;; 执行打印
        (if (and (= result 1) drawings settings)
          (bp:execute-print drawings settings)))))
  (uc:guard-end)
  (princ))

(defun bp:tile-list (key)
  "返回 popup 对应的候选列表（用于配置回填）。"
  (cond
    ((= key "frame_type") *BP:FRAME-TYPES*)
    ((= key "scale_mode") *BP:SCALE-MODES*)
    ((= key "output_mode") *BP:OUTPUT-MODES*)
    ((= key "color_mode") *BP:COLOR-MODES*)
    ((= key "paper") (mapcar '(lambda (x) (cons (car x) (car x))) *BP:PAPER-SIZES*))
    ((= key "printer") (mapcar '(lambda (x) (cons x x)) (bp:get-printers)))
    (t nil)))

(defun bp:select-printer (pattern / printers i p)
  "按模式（模糊匹配）选中打印机下拉项。"
  (setq printers (bp:get-printers) i 0)
  (foreach p printers
    (if (wcmatch (strcase p) (strcat "*" (strcase pattern) "*"))
      (set_tile "printer" (itoa i)))
    (setq i (1+ i))))

(defun c:BPSET nil
  "打开批量打印设置。"
  (c:BPT)
  (princ))

(princ "\n[TB] 批量打印模块加载完成 (c:BPT, c:BPSET)")
(princ)
