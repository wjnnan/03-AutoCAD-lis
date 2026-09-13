;;; tb-mod-calc.lsp — 测量计算模块
;;; 累计长度、累计面积、数字求和、实体信息查询。
;;; 组合 curve:* sel:* entity:* 库函数

;; ============================================================================
;; 累计长度 c:lcd
;; ============================================================================

(defun c:lcd (/ ss total)
  (uc:guard-begin '())
  "选择线条，计算累计总长度。支持 LINE, LWPOLYLINE, POLYLINE, ARC, SPLINE。"
  (if (setq ss (ssget '((0 . "LINE,LWPOLYLINE,POLYLINE,ARC,SPLINE,CIRCLE"))))
    (progn
      (setq total 0.0)
      (sel:for-each ss
        '(lambda (e)
           (setq total (+ total (curve:length e)))))
      (princ (strcat "\n累计长度: " (rtos total 2 2) " mm"
                     "  (" (rtos (/ total 1000.0) 2 2) " m)"))
      ;; 在图纸上写入文字
      (if (setq pt (getpoint "\n文字插入点（回车跳过）: "))
        (entity:make-text
          (strcat "L=" (rtos (/ total 1000.0) 2 2) "m")
          pt (* 350 (sys:get '*SYS:DWG-SCALE*))
          (sys:get '*SYS:TEXT-STYLE*) (getvar "CLAYER")))))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 累计面积 c:lmj
;; ============================================================================

(defun c:lmj (/ ss total)
  (uc:guard-begin '())
  "选择闭合区域，计算累计总面积。"
  (if (setq ss (ssget '((0 . "LWPOLYLINE,POLYLINE,CIRCLE,ELLIPSE,HATCH"))))
    (progn
      (setq total 0.0)
      (sel:for-each ss
        '(lambda (e / typ)
           (setq typ (entity:get-type e))
           ;; 只计算闭合区域：圆/椭圆/填充，或闭合多段线
           (if (or (= typ "CIRCLE") (= typ "ELLIPSE") (= typ "HATCH")
                   (and (wcmatch typ "LWPOLYLINE,POLYLINE") (curve:closed? e)))
             (setq total (+ total (curve:area e))))))
      (princ (strcat "\n累计面积: " (rtos total 2 2) " mm^2"
                     "  (" (rtos (/ total 1000000.0) 2 3) " m^2)"))
      (if (setq pt (getpoint "\n文字插入点（回车跳过）: "))
        (entity:make-text
          (strcat "A=" (rtos (/ total 1000000.0) 2 3) "m^2")
          pt (* 350 (sys:get '*SYS:DWG-SCALE*))
          (sys:get '*SYS:TEXT-STYLE*) (getvar "CLAYER")))))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 数字求和 c:qh
;; ============================================================================

(defun c:qh (/ ss total)
  (uc:guard-begin '())
  "提取所选文字/标注中的数字并求和。"
  (setq total 0.0)
  (if (setq ss (ssget '((0 . "TEXT,MTEXT,DIMENSION"))))
    (sel:for-each ss
        '(lambda (e / str val i num-str)
           (setq str (cond
                       ((= (entity:get-type e) "DIMENSION")
                        (rtos (entity:get-dxf e 42) 2 2))
                       (t (entity:get-dxf e 1))))
           ;; 提取字符串中第一个连续数字（支持 "L=12.5"、"间距300"）
           (setq i 1 num-str "")
           (while (and (<= i (strlen str)) (= num-str ""))
             (if (wcmatch (substr str i 1) "[0-9]")
               (progn
                 (while (and (<= i (strlen str))
                             (wcmatch (substr str i 1) "[0-9.]"))
                   (setq num-str (strcat num-str (substr str i 1))
                         i (1+ i)))))
             (setq i (1+ i)))
           (setq val (if (= num-str "") 0.0 (atof num-str)))
           (if (not (zerop val))
             (setq total (+ total val))))))
  ;; 无论是否选中都输出结果。原实现只把输出放在 else 分支：
  ;; 选中对象时静默无结果，未选中时 total 为 nil，(rtos nil 2 2) 直接报错。
  (princ (strcat "\n数字求和: " (rtos total 2 2)))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; DXF 查询 c:Tn
;; ============================================================================

(defun c:Tn (/ e)
  (uc:guard-begin '())
  "查看所选实体的全部 DXF 组码。"
  (if (setq e (car (entsel "\n选择实体查看DXF: ")))
    (progn
      (princ "\n--- DXF 组码列表 ---")
      (foreach pair (entget e)
        (princ (strcat "\n  " (itoa (car pair)) "  =  "
                       (vl-princ-to-string (cdr pair)))))
      (princ "\n--- 结束 ---")))
  (princ)
  (uc:guard-end))


(princ "\n[TB] 测量计算模块加载完成 (calc: 4命令)")
(princ)
