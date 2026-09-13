;;; tb-mod-rebar.lsp — 钢筋绘制命令模块
;;; 组合 rebar:* entity:* point:* sel:* lay:* txt:* 库函数
;;; 提供：画钢筋、画箍筋、加弯钩、删弯钩、线变钢筋、钢筋标注

;; ============================================================================
;; c:RB — 画任意钢筋
;; ============================================================================

(defun c:RB (/ d grade hs he hdir pt pts width layer)
  (uc:guard-begin '())
  "画任意钢筋（点取路径，自动加弯钩）。"
  ;; 参数输入
  (setq d     (safe:get-real "钢筋直径(mm)" (sys:get '*SYS:REBAR-DIAMETER*))
        grade (safe:get-int  "钢筋等级(1=HPB300 2=HRB335 3=HRB400)"
                (sys:get '*SYS:REBAR-GRADE*)))
  (initget "0 1 2 3")
  (setq hs (getint (strcat "\n起始弯钩 [0无/1圆钩180°/2斜钩135°/3直钩90°] <"
                           (itoa (sys:get '*SYS:REBAR-HOOK*)) ">: ")))
  (if (not hs) (setq hs (sys:get '*SYS:REBAR-HOOK*)))
  (initget "0 1 2 3")
  (setq he (getint (strcat "\n末端弯钩 [0无/1圆钩180°/2斜钩135°/3直钩90°] <"
                           (itoa (sys:get '*SYS:REBAR-HOOK*)) ">: ")))
  (if (not he) (setq he (sys:get '*SYS:REBAR-HOOK*)))
  (initget "L R")
  (setq hdir-str (getkword "\n弯钩方向 [L左/R右] <L>: "))
  (setq hdir (if (or (not hdir-str) (= hdir-str "L")) 1 -1))

  ;; 保存为默认值
  (sys:set '*SYS:REBAR-DIAMETER* d)
  (sys:set '*SYS:REBAR-GRADE* grade)
  (sys:set '*SYS:REBAR-HOOK* (max hs he))

  ;; 取点
  (setq width (* d (sys:get '*SYS:DWG-SCALE*) 0.01)
        layer (sys:get '*SYS:REBAR-LAYER*))
  (princ "\n取钢筋路径点（回车结束）:")
  (setq pt (getpoint "\n第1点: "))
  (while pt
    (setq pts (cons pt pts))
    ;; 预览
    (if (> (length pts) 1)
      (grdraw (cadr pts) (car pts) 1 1))
    (setq pt (getpoint (if pt pt '(0 0 0)) "\n下一点（回车结束）: ")))
  (setq pts (reverse pts))

  (if (>= (length pts) 2)
    (progn
      (rebar:make-bar pts hs he d grade hdir width layer)
      (princ (strcat "\n钢筋已绘制。D=" (rtos d 2 0) " 等级=" (itoa grade)
                     " 弯钩: 始=" (nth hs '("无" "圆" "斜" "直"))
                     " 末=" (nth he '("无" "圆" "斜" "直")))))
    (princ "\n至少需要2个点。"))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; c:RS — 画箍筋
;; ============================================================================

(defun c:RS (/ d grade hook-type hdir mode p1 p3 e boundary-pts width layer)
  (uc:guard-begin '())
  "画箍筋（矩形对角点或选闭合多段线边界）。"
  (setq d         (safe:get-real "箍筋直径(mm)" (sys:get '*SYS:REBAR-DIAMETER*))
        grade     (safe:get-int  "钢筋等级(1/2/3)" (sys:get '*SYS:REBAR-GRADE*)))
  (initget "0 1 2 3")
  (setq hook-type (getint (strcat "\n弯钩类型 [0无/1圆钩/2斜钩/3直钩] <"
                                  (itoa (sys:get '*SYS:REBAR-HOOK*)) ">: ")))
  (if (not hook-type) (setq hook-type (sys:get '*SYS:REBAR-HOOK*)))
  (initget "L R")
  (setq hdir-str (getkword "\n弯钩方向 [L左/R右] <L>: "))
  (setq hdir (if (or (not hdir-str) (= hdir-str "L")) 1 -1))

  (initget "R P")
  (setq mode (getkword "\n选择方式 [R矩形对角/P选多段线边界] <R>: "))
  (if (not mode) (setq mode "R"))

  (setq width (* d (sys:get '*SYS:DWG-SCALE*) 0.01)
        layer (sys:get '*SYS:STIRRUP-LAYER*))

  (cond
    ((= mode "R")
     (if (and (setq p1 (getpoint "\n箍筋左下角: "))
              (setq p3 (getcorner p1 "\n箍筋右上角: ")))
       (progn
         (rebar:make-stirrup p1 p3 hook-type d grade hdir width layer)
         (princ (strcat "\n矩形箍筋已绘制。D=" (rtos d 2 0)
                        " 弯钩=" (nth hook-type '("无" "圆钩" "斜钩" "直钩")))))))

    ((= mode "P")
     (if (setq e (car (entsel "\n选择闭合多段线作为箍筋边界: ")))
       (if (curve:closed? e)
         (progn
           (setq boundary-pts (curve:vertices e))
           (rebar:make-poly-stirrup boundary-pts hook-type d grade hdir width layer)
           (princ (strcat "\n多边形箍筋已绘制。D=" (rtos d 2 0))))
         (princ "\n所选多段线未闭合。")))))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; c:RH — 添加弯钩
;; ============================================================================

(defun c:RH (/ ss i e hook-type hdir d grade end-str end)
  (uc:guard-begin '())
  "为所选钢筋批量添加或修改弯钩（支持框选）。"
  (if (setq ss (ssget '((0 . "LWPOLYLINE"))))
    (progn
      (initget "0 1 2 3")
      (setq hook-type (getint "\n弯钩类型 [0=删除 1=圆钩 2=斜钩 3=直钩] <2>: "))
      (if (not hook-type) (setq hook-type 2))

      (initget "S E")
      (setq end-str (getkword "\n加在哪端 [S起点/E终点] <E>: "))
      (setq end (if (or (not end-str) (= end-str "E")) 'end 'start))

      (initget "L R")
      (setq hdir-str (getkword "\n弯钩方向 [L左/R右] <L>: "))
      (setq hdir (if (or (not hdir-str) (= hdir-str "L")) 1 -1))

      (setq d (safe:get-real "钢筋直径(mm)" (sys:get '*SYS:REBAR-DIAMETER*))
            grade (safe:get-int "钢筋等级(1/2/3)" (sys:get '*SYS:REBAR-GRADE*)))

      (setq i 0)
      (repeat (sslength ss)
        (setq e (ssname ss i))
        (if (rebar:is-rebar? e)
          (if (= hook-type 0)
            (if (> (rebar:detect-hook-end e end) 0)
              (rebar:remove-hook e end))
            (rebar:add-hook e end hook-type hdir d grade)))
        (setq i (1+ i)))
      (princ (strcat "\n已处理 " (itoa (sslength ss)) " 根钢筋。")))
    (princ "\n未选择钢筋。"))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; c:RDH — 删除弯钩
;; ============================================================================

(defun c:RDH (/ ss i e end-str end)
  (uc:guard-begin '())
  "批量删除钢筋指定端的弯钩（支持框选）。"
  (if (setq ss (ssget '((0 . "LWPOLYLINE"))))
    (progn
      (initget "S E B")
      (setq end-str (getkword "\n删除哪端 [S起点/E终点/B两端] <B>: "))
      (setq end (cond ((= end-str "S") 'start)
                      ((= end-str "E") 'end)
                      (t 'both)))
      (setq i 0)
      (repeat (sslength ss)
        (setq e (ssname ss i))
        (if (rebar:is-rebar? e)
          (if (= end 'both)
            (progn
              (setq e (rebar:remove-hook e 'start))
              (rebar:remove-hook e 'end))
            (rebar:remove-hook e end)))
        (setq i (1+ i)))
      (princ (strcat "\n已处理 " (itoa (sslength ss)) " 根钢筋。")))
    (princ "\n未选择钢筋。"))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; c:RW — 改钢筋线宽
;; ============================================================================

(defun c:RW (/ ss w)
  (uc:guard-begin '())
  "修改所选钢筋的多段线宽。"
  (if (setq ss (ssget '((0 . "LWPOLYLINE"))))
    (progn
      (setq w (safe:get-real "新线宽(mm)" 0.5))
      (sel:for-each ss
        '(lambda (e)
           (if (rebar:is-rebar? e)
             (rebar:set-width e w)))))
    (princ "\n未选择钢筋。"))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; c:RO — 偏移钢筋
;; ============================================================================

(defun c:RO (/ ss dist pt)
  (uc:guard-begin '())
  "批量偏移钢筋（保持钢筋属性，支持框选）。"
  (if (setq ss (ssget '((0 . "LWPOLYLINE"))))
    (progn
      (setq dist (safe:get-real "偏移距离(mm)" 100)
            pt   (getpoint "\n偏移方向点: "))
      (if pt
        (progn
          (if (vl-catch-all-error-p
                (vl-catch-all-apply (quote (lambda nil (command "_.OFFSET" dist ss "" pt "")))))
            (princ "\n偏移失败，请检查钢筋和偏移距离。")
            (princ (strcat "\n已偏移 " (itoa (sslength ss)) " 根钢筋。"))))
        (princ "\n未指定偏移方向。"))))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; c:RL — 线变钢筋
;; ============================================================================

(defun c:RL (/ ss d grade hs he hdir width layer pts e ent new-e)
  (uc:guard-begin '())
  "将 LINE/LWPOLYLINE 转换为钢筋（添加线宽和可选弯钩）。"
  (if (setq ss (ssget '((0 . "LINE,LWPOLYLINE,POLYLINE"))))
    (progn
      (setq d     (safe:get-real "钢筋直径(mm)" (sys:get '*SYS:REBAR-DIAMETER*))
            grade (safe:get-int  "钢筋等级(1/2/3)" (sys:get '*SYS:REBAR-GRADE*)))
      (initget "0 1 2 3")
      (setq hs (getint (strcat "\n起始弯钩 [0无/1圆钩/2斜钩/3直钩] <"
                               (itoa (sys:get '*SYS:REBAR-HOOK*)) ">: ")))
      (if (not hs) (setq hs (sys:get '*SYS:REBAR-HOOK*)))
      (initget "0 1 2 3")
      (setq he (getint (strcat "\n末端弯钩 [0无/1圆钩/2斜钩/3直钩] <"
                               (itoa (sys:get '*SYS:REBAR-HOOK*)) ">: ")))
      (if (not he) (setq he (sys:get '*SYS:REBAR-HOOK*)))
      (initget "L R")
      (setq hdir-str (getkword "\n弯钩方向 [L左/R右] <L>: "))
      (setq hdir (if (or (not hdir-str) (= hdir-str "L")) 1 -1))

      (setq width (* d (sys:get '*SYS:DWG-SCALE*) 0.01)
            layer (sys:get '*SYS:REBAR-LAYER*))
      (lay:make layer 1 "Continuous")

      (sel:for-each ss
        '(lambda (e / typ pts)
           (setq typ (entity:get-type e))
           (setq pts (cond
             ((= typ "LINE")
              (list (entity:get-dxf e 10) (entity:get-dxf e 11)))
             (t (curve:vertices e))))
           (if (>= (length pts) 2)
             (if (rebar:make-bar pts hs he d grade hdir width layer)
               (entdel e)))))  ; 仅在新钢筋创建成功后删除原线
      (princ (strcat "\n已转换 " (itoa (sel:count ss)) " 条线为钢筋。")))
    (princ "\n未选择线条。"))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; c:RD — 钢筋标注
;; ============================================================================

(defun c:RD (/ e d grade grade-sym pt num-str spacing-str text-h text-str)
  (uc:guard-begin '())
  "钢筋标注：在钢筋上标注直径、数量、间距。"
  (if (setq e (car (entsel "\n选择要标注的钢筋: ")))
    (progn
      (setq d         (safe:get-real "钢筋直径(mm)" (sys:get '*SYS:REBAR-DIAMETER*))
            grade     (safe:get-int "钢筋等级(1/2/3)" (sys:get '*SYS:REBAR-GRADE*))
            grade-sym (nth (1- (if grade grade (sys:get '*SYS:REBAR-GRADE*))) '("%%130" "%%131" "%%132"))
            text-h    (* (or (sys:get '*SYS:TEXT-HEIGHT*) 350) (or (sys:get '*SYS:DWG-SCALE*) 100) 0.01))

      (setq num-str (getstring (strcat "\n钢筋根数（回车跳过）: ")))
      (setq spacing-str (getstring "\n间距@（回车跳过）: "))
      (setq pt (getpoint "\n文字插入点: "))

      ;; 构造标注文字
      (setq text-str (strcat
        (if (and num-str (/= num-str "")) (strcat num-str grade-sym) "")
        (rtos d 2 0)
        (if (and spacing-str (/= spacing-str "")) (strcat "@" spacing-str) "")))

      (if pt
        (progn
          (entity:make-text text-str pt text-h
            (sys:get '*SYS:TEXT-STYLE*)
            (sys:get '*SYS:REBAR-TEXT-LAYER*))
          (princ (strcat "\n钢筋标注: " text-str)))))
    (princ "\n未选择实体。"))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; c:RCC — 钢筋编号
;; ============================================================================

(defun c:RCC (/ ss num count text-h layer ents sort-dir)
  (uc:guard-begin '())
  "框选钢筋，按空间顺序自动编号。"
  (if (setq ss (ssget '((0 . "LWPOLYLINE"))))
    (progn
      (setq num    (safe:get-int "起始编号" 1)
            count  0
            text-h (* (or (sys:get '*SYS:TEXT-HEIGHT*) 350) (or (sys:get '*SYS:DWG-SCALE*) 100) 0.01)
            layer  (sys:get '*SYS:REBAR-TEXT-LAYER*))
      (lay:make layer 2 "Continuous")  ; 黄色

      ;; 排序方向
      (initget "X Y")
      (setq sort-dir (getkword "\n排序方向 [X水平/Y垂直] <X>: "))
      (if (not sort-dir) (setq sort-dir "X"))
      ;; 按坐标排序（替代选择集顺序，保证编号空间有序）
      (setq ents
        (vl-sort (append (sel:to-list ss) nil)
          (if (= sort-dir "X")
            '(lambda (a b) (< (car (curve:midpt a)) (car (curve:midpt b))))
            '(lambda (a b) (> (cadr (curve:midpt a)) (cadr (curve:midpt b)))))))
      (foreach e ents
        (if (rebar:is-rebar? e)
          (progn
            (setq midpt (curve:midpt e))
            (entity:make-text
              (strcat (itoa num) "#")
              (point:polar midpt (* pi 0.5) (* 0.5 text-h))
              text-h (sys:get '*SYS:TEXT-STYLE*) layer)
            (setq num (1+ num)
                  count (1+ count)))))
      (princ (strcat "\n已编号 " (itoa count) " 根钢筋。")))
    (princ "\n未选择钢筋。"))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; c:RBR — 板底筋
;; ============================================================================

(defun c:RBR (/ p1 p3 d spacing grade pts n-pts width layer x1 y1 x3 y3 y x count)
  (uc:guard-begin '())
  "绘制板底筋区域。选择矩形区域，自动生成分布筋。"
  (setq d       (safe:get-real "钢筋直径(mm)" (sys:get '*SYS:REBAR-DIAMETER*))
        spacing (max 1 (safe:get-real "钢筋间距(mm)" 200))
        grade   (safe:get-int  "钢筋等级(1/2/3)" (sys:get '*SYS:REBAR-GRADE*)))

  (if (and (setq p1 (getpoint "\n板筋区域左下角: "))
           (setq p3 (getcorner p1 "\n板筋区域右上角: ")))
    (progn
      (setq width  (* d (sys:get '*SYS:DWG-SCALE*) 0.01)
            layer  (sys:get '*SYS:REBAR-LAYER*)
            x1 (car p1) y1 (cadr p1)
            x3 (car p3) y3 (cadr p3)
            y y1
            count 0)
      (lay:make layer 1 "Continuous")
      ;; 水平底筋（X 向），从下到上
      (while (and (<= y y3) (< count 5000))
        (rebar:make-bar
          (list (list x1 y 0.0) (list x3 y 0.0))
          0 0 d grade 1 width layer)  ; 无弯钩
        (setq y (+ y spacing)
              count (1+ count)))
      ;; 垂直底筋（Y 向），从左到右（板底筋为双向网片）
      (setq x x1)
      (while (and (<= x x3) (< count 10000))
        (rebar:make-bar
          (list (list x y1 0.0) (list x y3 0.0))
          0 0 d grade 1 width layer)  ; 无弯钩
        (setq x (+ x spacing)
              count (1+ count)))
      (princ (strcat "\n板底筋已绘制。D=" (rtos d 2 0) "@" (rtos spacing 2 0)
                     " 共 " (itoa count) " 根"))))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; c:RBF — 板负筋
;; ============================================================================

(defun c:RBF (/ p1 p2 d spacing grade left-len right-len hdir hook-type
               ang width layer count perp-dir p-start p-end dist len base-pt)
  (uc:guard-begin '())
  "绘制板支座负筋。选择支座线，输入左右伸出长度。"
  (setq d         (safe:get-real "钢筋直径(mm)" (sys:get '*SYS:REBAR-DIAMETER*))
        spacing   (max 1 (safe:get-real "钢筋间距(mm)" 200))
        grade     (safe:get-int  "钢筋等级(1/2/3)" (sys:get '*SYS:REBAR-GRADE*))
        left-len  (safe:get-real "左侧伸出长度(mm)" 1000)
        right-len (safe:get-real "右侧伸出长度(mm)" 1000))
  (initget "0 1 2 3")
  (setq hook-type (getint (strcat "\n弯钩类型 [0无/1圆钩/2斜钩/3直钩] <"
                                  (itoa (sys:get '*SYS:REBAR-HOOK*)) ">: ")))
  (if (not hook-type) (setq hook-type 3))  ; 负筋默认直钩
  (initget "L R")
  (setq hdir-str (getkword "\n弯钩方向 [L左/R右] <L>: "))
  (setq hdir (if (or (not hdir-str) (= hdir-str "L")) 1 -1))

  (if (and (setq p1 (getpoint "\n支座线起点: "))
           (setq p2 (getpoint p1 "\n支座线终点: ")))
    (progn
      (setq ang    (point:angle p1 p2)
            width  (* d (sys:get '*SYS:DWG-SCALE*) 0.01)
            layer  (sys:get '*SYS:REBAR-LAYER*)
            perp-dir (+ ang (* pi 0.5))
            count  0)
      (lay:make layer 1 "Continuous")

      ;; 沿支座线每隔 spacing 放一根负筋
      (setq dist 0.0
            len (point:dist p1 p2))
      (while (and (<= dist len) (< count 5000))
        (setq base-pt (point:polar p1 ang dist)
              ;; 负筋从左端到右端
              p-start (point:polar base-pt (+ perp-dir pi) left-len)
              p-end   (point:polar base-pt perp-dir right-len))
        (rebar:make-bar
          (list p-start base-pt p-end)
          hook-type hook-type d grade hdir width layer)
        (setq dist (+ dist spacing)
              count (1+ count)))
      (princ (strcat "\n板负筋已绘制。D=" (rtos d 2 0) "@" (rtos spacing 2 0)
                     " 左=" (rtos left-len 2 0) " 右=" (rtos right-len 2 0)
                     " 共 " (itoa count) " 根"))))
  (princ)
  (uc:guard-end))


(princ "\n[TB] 钢筋命令模块加载完成 (rebar: 9命令)")
(princ)
