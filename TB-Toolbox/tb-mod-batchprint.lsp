;;; tb-mod-batchprint.lsp — 批量打印模块
;;; 整合 BatchPlot/MSteel/源泉/SmartBatchPlot 的优点
;;; 提供：图框检测、纸张匹配、比例识别、属性命名、批量输出
;;; 命令: BPT (批量打印) / BPSET (设置)

;; ============================================================================
;; 常量定义
;; ============================================================================

;; 标准纸张尺寸 (mm) — 短边在前（portrait），长边在后
(setq *BP:PAPER-SIZES*
  '(("A4"      . (210.0 297.0))
    ("A3"      . (297.0 420.0))
    ("A2"      . (420.0 594.0))
    ("A1"      . (594.0 841.0))
    ("A0"      . (841.0 1189.0))
    ("A3+"     . (297.0 440.0))
    ("A2+"     . (420.0 620.0))
    ("A1+"     . (594.0 880.0))
    ("A0+"     . (841.0 1240.0))
    ("B5"      . (176.0 250.0))
    ("B4"      . (250.0 353.0))
    ("B3"      . (353.0 500.0))
    ("B2"      . (500.0 707.0))
    ("B1"      . (707.0 1000.0))))

;; 图框识别方式
(setq *BP:FRAME-TYPES*
  '(("图块识别（按图块名）"  . "BLOCK")
    ("多段线识别（按图层）"   . "PLINE")
    ("布局空间"              . "LAYOUT")))

;; 比例模式
(setq *BP:SCALE-MODES*
  '(("自动识别比例"      . "AUTO")
    ("布满图纸"          . "FIT")
    ("自定义比例"        . "CUSTOM")))

;; 输出方式
(setq *BP:OUTPUT-MODES*
  '(("打印到打印机"      . "PRINTER")
    ("输出为 PDF"        . "PDF")
    ("输出为 PLT"        . "PLT")
    ("输出为 DWF"        . "DWF")))

;; 颜色模式
(setq *BP:COLOR-MODES*
  '(("彩色"  . "C")
    ("灰度"  . "G")
    ("黑白"  . "M")))

;; 命名规则标记说明
(setq *BP:NAME-TOKENS*
  '(("{图号}"   . 1)
    ("{图名}"   . 2)
    ("{比例}"   . 3)
    ("{日期}"   . 4)
    ("{序号}"   . 5)))


;; ============================================================================
;; 图纸列表管理
;; ============================================================================

(defun bp:make-drawing (handle center w h scale paper draw-num draw-name date rotation)
  "创建图纸记录。"
  (list
    (cons 'handle  handle)
    (cons 'center  center)
    (cons 'width   w)
    (cons 'height  h)
    (cons 'scale   scale)
    (cons 'paper   paper)
    (cons 'draw-num   draw-num)
    (cons 'draw-name  draw-name)
    (cons 'date    date)
    (cons 'rotation rotation)))

(defun bp:drawing-prop (drawing key)
  "获取图纸记录属性。"
  (cdr (assoc key drawing)))


;; ============================================================================
;; 纸张匹配
;; ============================================================================

(defun bp:match-paper (w h / best-name best-diff diff size ww hh swap-w swap-h)
  "根据图框尺寸匹配最接近的标准纸张。
  返回: 纸张名称 (如 \"A2\")"
  (setq best-name "自定义"
        best-diff 1e308)
  (foreach paper *BP:PAPER-SIZES*
    (setq size (cdr paper)
          ww   (car size)
          hh   (cadr size))
    ;; 比较两种方向
    (setq diff (min (+ (abs (- w ww)) (abs (- h hh)))
                    (+ (abs (- w hh)) (abs (- h ww)))))
    (if (< diff best-diff)
      (setq best-diff diff
            best-name (car paper))))
  ;; 如果图框与最接近纸张差 10% 以上，返回自定义
  (if (< best-diff (* w 0.1))
    best-name
    "自定义"))


;; ============================================================================
;; 比例识别
;; ============================================================================

(defun bp:detect-scale (frame-w frame-h paper-w paper-h / scale-w scale-h avg)
  "根据图框尺寸和纸张尺寸反推比例。
  frame: 图框实际尺寸(绘图单位)  paper: 纸张尺寸(mm)
  例: 图框=42000mm, 纸张=420mm → 比例=1:100"
  (if (and frame-w frame-h paper-w paper-h (> paper-w 0))
    (progn
      (setq scale-w (/ frame-w paper-w)
            scale-h (/ frame-h paper-h)
            avg (/ (+ frame-w frame-h) (+ paper-w paper-h)))
      ;; 取最接近的整数比例
      (fix (+ 0.5 avg)))
    100))


;; ============================================================================
;; 图框检测 — 块模式
;; ============================================================================

(defun bp:detect-blocks (block-name / ss blocks result)
  "检测指定名称的图框块（支持通配符 *）。"
  (if (setq ss (ssget "_X" (list '(0 . "INSERT") (cons 2 block-name))))
    (progn
      (setq blocks nil)
      (sel:for-each ss
        '(lambda (e / bbox attrs inspt w h draw-num draw-name scale-val date)
           (setq bbox   (entity:get-bbox e)
                 inspt  (entity:get-dxf e 10))
           (if bbox
             (progn
               (setq w (abs (- (caadr bbox) (caar bbox)))
                     h (abs (- (cadadr bbox) (cadar bbox)))
                     center (point:mid (car bbox) (cadr bbox)))
               ;; 提取属性
               (setq attrs (bp:get-block-attrs e))
               (setq draw-num  (bp:attr-val attrs '("图号" "编号" "DRAWING_NO" "DWG_NO" "TUH")))
               (setq draw-name (bp:attr-val attrs '("图名" "图纸名称" "DRAWING_NAME" "TUM")))
               (setq scale-val (bp:attr-val attrs '("比例" "SCALE" "BL")))
               (setq date      (bp:attr-val attrs '("日期" "DATE" "RQ")))
               ;; 比例处理
               (if scale-val
                 (progn
                   (if (wcmatch scale-val "1:*")
                     (progn
                       (setq scale-val (atoi (substr scale-val 3)))
                       (if (zerop scale-val) (setq scale-val nil))))
                   (if (and scale-val (not (numberp scale-val)))
                     (setq scale-val (atoi scale-val)))
                   (if (or (not scale-val) (not (numberp scale-val)) (zerop scale-val))
                     (setq scale-val nil))))
               ;; 创建记录
               (setq blocks (cons
                 (bp:make-drawing (entity:handle e)
                   center w h (or scale-val (bp:detect-scale w h 420 594))
                   (bp:match-paper w h)
                   draw-num draw-name date 0.0)
                 blocks))))))
      (reverse blocks))))


(defun bp:get-block-attrs (e / result)
  "获取块引用的属性表 → ((tag . value) ...)。"
  (if (and (= (entity:get-type e) "INSERT")
           (= (entity:get-dxf e 66) 1))  ; 有属性跟随
    (progn
      (setq e (entnext e))
      (while (and e (= (entity:get-type e) "ATTRIB"))
        (setq result (cons
          (cons (entity:get-dxf e 2) (entity:get-dxf e 1))
          result))
        (setq e (entnext e)))
      (reverse result))))

(defun bp:attr-val (attrs tags)
  "从属性表中匹配标签名，返回第一个匹配的值。"
  (if (not attrs) nil
    (car (vl-remove nil
      (mapcar '(lambda (tag)
        (cdr (assoc (strcase tag) (mapcar '(lambda (a) (cons (strcase (car a)) (cdr a))) attrs))))
        (mapcar 'strcase tags))))))


;; ============================================================================
;; 图框检测 — 多段线模式
;; ============================================================================

(defun bp:detect-plines (layer-name / ss result)
  "检测指定图层的闭合多段线作为图框。"
  (if (setq ss (ssget "_X" (list '(0 . "LWPOLYLINE") (cons 8 layer-name))))
    (progn
      (setq result nil)
      (sel:for-each ss
        '(lambda (e / bbox w h)
           (setq bbox (entity:get-bbox e))
           (if bbox
             (progn
               (setq w (abs (- (caadr bbox) (caar bbox)))
                     h (abs (- (cadadr bbox) (cadar bbox))))
               (setq result (cons
                 (bp:make-drawing (entity:handle e)
                   (point:mid (car bbox) (cadr bbox))
                   w h (bp:detect-scale w h 420 594)
                   (bp:match-paper w h) nil nil nil 0.0)
                 result))))))
      (reverse result))))


;; ============================================================================
;; 图框检测 — 布局模式
;; ============================================================================

(defun bp:detect-layouts (/ result lay-name)
  "获取所有已初始化的布局（纯 AutoLISP，跨平台）。"
  (setq result nil)
  ;; 遍历布局表，跳过 "Model"
  (setq lay-name (cdr (assoc 2 (tblnext "LAYOUT" T))))
  (while lay-name
    (if (not (= (strcase lay-name) "MODEL"))
      (setq result (cons
        (bp:make-drawing nil nil 0 0 100 "A3"
          lay-name lay-name nil 0.0)
        result)))
    (setq lay-name (cdr (assoc 2 (tblnext "LAYOUT")))))
  (reverse result))


;; ============================================================================
;; 检测入口（统一调度）
;; ============================================================================

(defun bp:detect-frames (frame-type frame-value include-model include-layouts
                         / drawings)
  "根据设置检测所有图框。返回图纸列表。"
  (setq drawings nil)
  (cond
    ((= frame-type "BLOCK")
     (setq drawings (bp:detect-blocks frame-value)))
    ((= frame-type "PLINE")
     (setq drawings (bp:detect-plines frame-value)))
    ((= frame-type "LAYOUT")
     (setq drawings (bp:detect-layouts))))
  drawings)


;; ============================================================================
;; 图纸列表排序
;; ============================================================================

(defun bp:sort-by-x (drawings)
  "按 X 坐标从左到右排序。vl-sort 可能去重，先 copy。"
  (vl-sort (append drawings nil)
    '(lambda (a b) (< (car (bp:drawing-prop a 'center))
                      (car (bp:drawing-prop b 'center))))))

(defun bp:sort-by-y (drawings)
  "按 Y 坐标从上到下排序。vl-sort 可能去重，先 copy。"
  (vl-sort (append drawings nil)
    '(lambda (a b) (> (cadr (bp:drawing-prop a 'center))
                      (cadr (bp:drawing-prop b 'center))))))

(defun bp:sort-drawings (drawings method)
  "排序图纸列表。method: 'X 或 'Y"
  (cond
    ((eq method 'X) (bp:sort-by-x drawings))
    ((eq method 'Y) (bp:sort-by-y drawings))
    (t drawings)))


;; ============================================================================
;; 重号检测
;; ============================================================================

(defun bp:check-duplicates (drawings / seen dups draw-num)
  "检测图号重复，返回重复的图号列表。"
  (setq seen nil dups nil)
  (foreach d drawings
    (setq draw-num (bp:drawing-prop d 'draw-num))
    (if draw-num
      (if (member draw-num seen)
        (if (not (member draw-num dups))
          (setq dups (cons draw-num dups)))
        (setq seen (cons draw-num seen)))))
  (reverse dups))


;; ============================================================================
;; 文件命名
;; ============================================================================

(defun bp:make-filename (drawing rule index / num name scale date result)
  "根据命名规则生成文件名。
  rule: 如 \"{图号}_{图名}\" 或 \"{序号}_{图号}\""
  (setq num   (or (bp:drawing-prop drawing 'draw-num) "")
        name  (or (bp:drawing-prop drawing 'draw-name) "")
        scale (itoa (bp:drawing-prop drawing 'scale))
        date  (or (bp:drawing-prop drawing 'date) ""))
  (setq result rule)
  (setq result (vl-string-subst (itoa index) "{序号}" result))
  (setq result (vl-string-subst num  "{图号}" result))
  (setq result (vl-string-subst name "{图名}" result))
  (setq result (vl-string-subst scale "{比例}" result))
  (setq result (vl-string-subst date "{日期}" result))
  result)


;; ============================================================================
;; 打印执行
;; ============================================================================

(defun bp:plot-one (drawing printer paper scale-mode custom-scale
                    ctb color-mode output-mode output-path filename
                    auto-rotate auto-center
                    / center w h rot min-pt max-pt plot-scale orientation)
  "打印单张图纸。使用 -PLOT 命令。"
  (setq center   (bp:drawing-prop drawing 'center)
        w        (bp:drawing-prop drawing 'width)
        h        (bp:drawing-prop drawing 'height)
        rot      (bp:drawing-prop drawing 'rotation)
        min-pt   (list (- (car center) (* w 0.5))
                        (- (cadr center) (* h 0.5)))
        max-pt   (list (+ (car center) (* w 0.5))
                        (+ (cadr center) (* h 0.5)))
        plot-scale "FIT"
        orientation "LANDSCAPE")
    ;; 方向判断
    (if auto-rotate
      (setq orientation (if (> w h) "LANDSCAPE" "PORTRAIT")))
    ;; 比例处理
    (cond
      ((= scale-mode "FIT")
       (setq plot-scale "FIT"))
      ((= scale-mode "CUSTOM")
       (setq plot-scale (strcat "1:" (itoa custom-scale))))
      ((= scale-mode "AUTO")
       (setq plot-scale (strcat "1:" (itoa (bp:drawing-prop drawing 'scale))))))
    ;; 输出文件
    (if (= output-mode "PRINTER")
      ;; 直接打印
      (command "_.-PLOT"
        "Y"                   ; 详细配置
        "Model"               ; 布局名（始终从模型空间打印）
        printer               ; 打印机
        paper                 ; 纸张
        "M"                   ; 毫米
        orientation           ; 方向
        "N"                   ; 反向打印
        "W"                   ; 窗口
        min-pt max-pt         ; 打印窗口
        plot-scale            ; 比例
        (if auto-center "C" "0,0")  ; 居中
        "Y"                   ; 使用打印样式
        (if ctb ctb "monochrome.ctb")
        "Y"                   ; 按样式打印
        color-mode            ; 彩色/灰度/黑白
        "N"                   ; 不保存更改
        "N"                   ; 是否继续
        "Y")                  ; 确认
      ;; 输出到文件
      (command "_.-PLOT"
        "Y"
        "Model"
        printer
        paper
        "M"
        orientation
        "N"
        "W"
        min-pt max-pt
        plot-scale
        (if auto-center "C" "0,0")
        "Y"
        (if ctb ctb "monochrome.ctb")
        "Y"
        color-mode
        "Y"                   ; 输出到文件
        "N"                   ; 不保存更改
        (strcat output-path "\\" filename)
        "N"
        "Y")))

;; ============================================================================
;; 配置保存/加载
;; ============================================================================

(defun bp:save-config (cfg-file settings / fp)
  "保存打印配置到文件。"
  (if (setq fp (open cfg-file "w"))
    (progn
      (foreach pair settings
        (write-line (strcat (car pair) "=" (cdr pair)) fp))
      (close fp)
      (princ (strcat "\n配置已保存: " cfg-file)))
    (princ "\n无法保存配置文件。")))

(defun bp:load-config (cfg-file / fp line pos key val settings)
  "从文件加载打印配置。"
  (if (setq fp (open cfg-file "r"))
    (progn
      (while (setq line (read-line fp))
        (if (setq pos (vl-string-search "=" line))
          (setq key (substr line 1 pos)
                val (substr line (+ pos 2))
                settings (cons (cons key val) settings))))
      (close fp)
      (reverse settings))
    nil))


;; ============================================================================
;; DCL 对话框
;; ============================================================================

(defun bp:init-dialog (dcl-id / printers)
  "初始化对话框控件。"
  ;; 图框类型列表
  (start_list "frame_type")
  (foreach ft *BP:FRAME-TYPES*
    (add_list (car ft)))
  (end_list)
  (set_tile "frame_type" "0")
  (set_tile "frame_value" "A1,A2,A0,TK-*,图框*")

  ;; 打印机列表
  (start_list "printer")
  (add_list "DWG To PDF.pc3")
  (add_list "Default Windows System Printer.pc3")
  (add_list "Adobe PDF.pc3")
  (end_list)
  (set_tile "printer" "0")

  ;; 纸张列表
  (start_list "paper")
  (foreach p *BP:PAPER-SIZES*
    (add_list (car p)))
  (end_list)
  (set_tile "paper" "3")  ; 默认 A1

  ;; 比例模式
  (start_list "scale_mode")
  (foreach sm *BP:SCALE-MODES*
    (add_list (car sm)))
  (end_list)
  (set_tile "scale_mode" "0")

  ;; 打印样式
  (start_list "ctb")
  (add_list "monochrome.ctb")
  (add_list "acad.ctb")
  (add_list "Grayscale.ctb")
  (add_list "DWF Virtual Pens.ctb")
  (end_list)
  (set_tile "ctb" "0")

  ;; 输出方式
  (start_list "output_mode")
  (foreach om *BP:OUTPUT-MODES*
    (add_list (car om)))
  (end_list)
  (set_tile "output_mode" "1")  ; PDF

  ;; 颜色模式
  (start_list "color_mode")
  (foreach cm *BP:COLOR-MODES*
    (add_list (car cm)))
  (end_list)
  (set_tile "color_mode" "2")  ; 黑白

  ;; 输出路径（默认桌面）
  (set_tile "output_path" (getvar "DWGPREFIX"))
  (set_tile "name_rule" "{图号}_{图名}"))

(defun bp:get-settings (/ ft-idx sm-idx om-idx cm-idx)
  "从对话框获取当前设置。"
  (setq ft-idx (atoi (get_tile "frame_type"))
        sm-idx (atoi (get_tile "scale_mode"))
        om-idx (atoi (get_tile "output_mode"))
        cm-idx (atoi (get_tile "color_mode")))
    (list
      (cons 'frame_type      (cdr (nth ft-idx *BP:FRAME-TYPES*)))
      (cons 'frame_value     (get_tile "frame_value"))
      (cons 'include_model   (get_tile "include_model"))
      (cons 'include_layouts (get_tile "include_layouts"))
      (cons 'auto_rotate     (get_tile "auto_rotate"))
      (cons 'auto_center     (get_tile "auto_center"))
      (cons 'printer         (nth (atoi (get_tile "printer"))
                                  '("DWG To PDF.pc3" "Default Windows System Printer.pc3" "Adobe PDF.pc3")))
      (cons 'paper           (get_tile "paper"))
      (cons 'scale_mode      (cdr (nth sm-idx *BP:SCALE-MODES*)))
      (cons 'custom_scale    (atoi (get_tile "custom_scale")))
      (cons 'ctb             (nth (atoi (get_tile "ctb"))
                                  '("monochrome.ctb" "acad.ctb" "Grayscale.ctb" "DWF Virtual Pens.ctb")))
      (cons 'color_mode      (cdr (nth cm-idx *BP:COLOR-MODES*)))
      (cons 'output_mode     (cdr (nth om-idx *BP:OUTPUT-MODES*)))
      (cons 'output_path     (get_tile "output_path"))
      (cons 'name_rule       (get_tile "name_rule"))
      (cons 'merge_pdf       (get_tile "merge_pdf"))))

(defun bp:update-list (drawings duplicates)
  "更新图纸列表显示。重复图号标 [!] 前缀。"
  (start_list "drawing_list")
  (mapcar 'add_list
    (mapcar
      '(lambda (d / num name scale paper dup-mark)
         (setq num   (or (bp:drawing-prop d 'draw-num) "—")
               name  (or (bp:drawing-prop d 'draw-name) "未命名")
               scale (itoa (bp:drawing-prop d 'scale))
               paper (or (bp:drawing-prop d 'paper) "?"))
         (if (member num duplicates)
           (setq dup-mark "[!] ")
           (setq dup-mark ""))
         (strcat dup-mark num "  " name "  1:" scale "  " paper))
      drawings))
  (end_list))


;; ============================================================================
;; 命令: BPT — 批量打印
;; ============================================================================

(defun c:BPT (/ dcl-fn dcl-id result done drawings settings
               duplicates frame-type frame-value)
  "批量打印主命令。"
  (setq dcl-fn (findfile "tb-dcl-batchprint.dcl"))
  (if (not dcl-fn)
    (if (sys:get '*SYS:LOAD-PATH*)
      (setq dcl-fn (strcat (sys:get '*SYS:LOAD-PATH*) "tb-dcl-batchprint.dcl"))))

  (if (not (and dcl-fn (setq dcl-id (load_dialog dcl-fn))))
    (princ "\n[批量打印] 找不到 DCL 文件。")
    (if (not (new_dialog "bp_main" dcl-id))
      (princ "\n[批量打印] 无法初始化对话框。")
      (progn
        (bp:init-dialog dcl-id)
        (setq drawings nil
              done nil)

        ;; === 事件绑定 ===
        (action_tile "btn_pick"
          "(progn
             (setq pick-ent (car (entsel \"\\n拾取图框块: \")))
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
             (set_tile \"status\"
               (strcat \"检测到 \" (itoa (length drawings)) \" 张图纸\"
                       (if duplicates (strcat \"，[!] \" (itoa (length duplicates)) \" 个重号\") \"\")))))")

        (action_tile "btn_sort_x"
          "(if drawings
             (progn
               (setq drawings (bp:sort-drawings drawings 'X))
               (bp:update-list drawings duplicates)
               (set_tile \"status\" \"已按X方向排序（左→右）。\")))")

        (action_tile "btn_sort_y"
          "(if drawings
             (progn
               (setq drawings (bp:sort-drawings drawings 'Y))
               (bp:update-list drawings duplicates)
               (set_tile \"status\" \"已按Y方向排序（上→下）。\")))")

        (action_tile "btn_remove"
          "(if drawings
             (progn
               (setq sel-idx (atoi (get_tile \"drawing_list\")))
               (if (nth sel-idx drawings)
                 (progn
                   (setq drawings (vl-remove (nth sel-idx drawings) drawings))
                   (setq duplicates (bp:check-duplicates drawings))
                   (bp:update-list drawings duplicates)
                   (set_tile \"status\" \"已移除选中图纸。\"))))))")

        (action_tile "btn_clear"
          "(progn (setq drawings nil duplicates nil)
                  (bp:update-list nil nil)
                  (set_tile \"status\" \"列表已清空。\"))")

        (action_tile "btn_preview"
          "(if drawings
             (progn
               (setq settings (bp:get-settings))
               ;; 对第一张进行预览（缩放窗口到第一个图纸位置）
               (setq d0 (car drawings)
                     c0 (bp:drawing-prop d0 'center)
                     w0 (bp:drawing-prop d0 'width)
                     h0 (bp:drawing-prop d0 'height))
               (command \"_.ZOOM\" \"_W\"
                 (list (- (car c0) (* w0 0.8)) (- (cadr c0) (* h0 0.8)))
                 (list (+ (car c0) (* w0 0.8)) (+ (cadr c0) (* h0 0.8))))
               (set_tile \"status\" (strcat \"预览第1张（缩放窗口）\"))))")

        (action_tile "btn_path"
          "(progn (setq p (getfiled \"选择输出文件夹\" (get_tile \"output_path\") \"\" 33))
             (if p (set_tile \"output_path\" p)))")

        (action_tile "btn_save_cfg"
          "(progn (setq cfg-file (getfiled \"保存配置\" \"\" \"cfg\" 1))
             (if cfg-file
               (progn
                 (setq settings (bp:get-settings))
                 (bp:save-config cfg-file
                   (mapcar '(lambda (x) (cons (car x) (cdr x))) settings))
                 (set_tile \"status\" (strcat \"配置已保存: \" cfg-file))))))")

        (action_tile "btn_load_cfg"
          "(progn (setq cfg-file (getfiled \"加载配置\" \"\" \"cfg\" 4))
             (if cfg-file
               (progn
                 (setq cfg (bp:load-config cfg-file))
                 (if cfg
                   (progn
                     (foreach pair cfg
                       (set_tile (car pair) (cdr pair)))
                     (set_tile \"status\" (strcat \"配置已加载: \" cfg-file))))))))")

        (action_tile "btn_help"
          "(progn
             (alert \"批量打印帮助:\\n\\n图框识别:\\n  BLOCK - 按图块名(支持通配符*)\\n  PLINE - 按图层名\\n  LAYOUT - 使用已有布局\\n\\n命名规则标记:\\n  {图号} {图名} {比例} {日期} {序号}\\n\\n排序: X=左→右 Y=上→下\\n\\n重号检测: 重复图号标[!]前缀\"))")

        (action_tile "btn_print"
          "(progn
             (if (not drawings)
               (set_tile \"status\" \"错误: 请先检测图框。\")
               (progn
                 (setq settings (bp:get-settings))
                 (done_dialog 1))))")

        (action_tile "cancel" "(done_dialog 0)")

        ;; 启动对话框
        (setq result (start_dialog))
        (unload_dialog dcl-id)

        ;; 执行打印
        (if (and (= result 1) drawings settings)
          (bp:execute-print drawings settings)))))
  (princ))


;; ============================================================================
;; 执行打印
;; ============================================================================

(defun bp:execute-print (drawings settings / printer paper scale-mode custom-scale
                          ctb color-mode output-mode output-path name-rule
                          auto-rotate auto-center merge-pdf i total filename)
  "执行批量打印。"
  (setq printer     (cdr (assoc 'printer settings))
        paper       (cdr (assoc 'paper settings))
        scale-mode  (cdr (assoc 'scale_mode settings))
        custom-scale (cdr (assoc 'custom_scale settings))
        ctb         (cdr (assoc 'ctb settings))
        color-mode  (cdr (assoc 'color_mode settings))
        output-mode (cdr (assoc 'output_mode settings))
        output-path (cdr (assoc 'output_path settings))
        name-rule   (cdr (assoc 'name_rule settings))
        auto-rotate (= (cdr (assoc 'auto_rotate settings)) "1")
        auto-center (= (cdr (assoc 'auto_center settings)) "1")
        merge-pdf   (= (cdr (assoc 'merge_pdf settings)) "1")
        total       (length drawings)
        i 0)

  (princ (strcat "\n═════════════════════"
                 "\n  批量打印开始 - 共 " (itoa total) " 张"
                 "\n═════════════════════"))

  ;; 创建输出目录
  (if (and (/= output-mode "PRINTER") (not (findfile output-path)))
    (vl-mkdir output-path))

  (foreach d drawings
    (setq i (1+ i)
          filename (bp:make-filename d name-rule i))
    ;; 根据输出方式设置扩展名
    (cond
      ((= output-mode "PDF") (setq filename (strcat filename ".pdf")))
      ((= output-mode "PLT") (setq filename (strcat filename ".plt")))
      ((= output-mode "DWF") (setq filename (strcat filename ".dwf"))))

    (princ (strcat "\n[" (itoa i) "/" (itoa total) "] "
                   filename "  (1:" (itoa (bp:drawing-prop d 'scale)) ")"))

    (bp:plot-one d printer paper scale-mode custom-scale
                 ctb color-mode output-mode output-path filename
                 auto-rotate auto-center))

  (princ (strcat "\n═════════════════════"
                 "\n  打印完成: " (itoa total) " 张 → " output-path
                 "\n═════════════════════"))
  (princ))


;; ============================================================================
;; 命令: BPSET — 快速设置
;; ============================================================================

(defun c:BPSET nil
  "快速打开批量打印设置（等同于 BPT）。"
  (c:BPT))


(princ "\n[TB] 批量打印模块加载完成 (c:BPT, c:BPSET)")
(princ)
