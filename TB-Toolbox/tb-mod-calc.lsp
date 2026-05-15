;;; tb-mod-calc.lsp — 测量计算模块
;;; 累计长度、累计面积、数字求和、实体信息查询。
;;; 组合 curve:* sel:* entity:* 库函数

;; ============================================================================
;; 累计长度 c:lcd
;; ============================================================================

(defun c:lcd (/ ss total)
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
  (princ))


;; ============================================================================
;; 累计面积 c:lmj
;; ============================================================================

(defun c:lmj (/ ss total)
  "选择闭合区域，计算累计总面积。"
  (if (setq ss (ssget '((0 . "LWPOLYLINE,POLYLINE,CIRCLE,ELLIPSE,HATCH"))))
    (progn
      (setq total 0.0)
      (sel:for-each ss
        '(lambda (e)
           (setq total (+ total (curve:area e)))))
      (princ (strcat "\n累计面积: " (rtos total 2 2) " mm²"
                     "  (" (rtos (/ total 1000000.0) 2 3) " m²)"))
      (if (setq pt (getpoint "\n文字插入点（回车跳过）: "))
        (entity:make-text
          (strcat "A=" (rtos (/ total 1000000.0) 2 3) "m²")
          pt (* 350 (sys:get '*SYS:DWG-SCALE*))
          (sys:get '*SYS:TEXT-STYLE*) (getvar "CLAYER")))))
  (princ))


;; ============================================================================
;; 数字求和 c:qh
;; ============================================================================

(defun c:qh (/ ss total)
  "提取所选文字/标注中的数字并求和。"
  (if (setq ss (ssget '((0 . "TEXT,MTEXT,DIMENSION"))))
    (progn
      (setq total 0.0)
      (sel:for-each ss
        '(lambda (e / str val)
           (setq str (cond
                       ((= (entity:get-type e) "DIMENSION")
                        (rtos (entity:get-dxf e 42) 2 2))
                       (t (entity:get-dxf e 1))))
           (setq val (atof str))
           (if (not (zerop val))
             (setq total (+ total val))))))
    (princ (strcat "\n数字求和: " (rtos total 2 2))))
  (princ))


;; ============================================================================
;; DXF 查询 c:Tn
;; ============================================================================

(defun c:Tn (/ e)
  "查看所选实体的全部 DXF 组码。"
  (if (setq e (car (entsel "\n选择实体查看DXF: ")))
    (progn
      (princ "\n--- DXF 组码列表 ---")
      (foreach pair (entget e)
        (princ (strcat "\n  " (itoa (car pair)) "  =  "
                       (vl-princ-to-string (cdr pair)))))
      (princ "\n--- 结束 ---")))
  (princ))


(princ "\n[TB] 测量计算模块加载完成 (calc: 4命令)")
(princ)
