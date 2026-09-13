;;; tb-mod-column.lsp — 墙柱工具模块
;;; 柱截面、柱表、墙身大样。
;;; 组合 entity:* point:* curve:* lay:* txt:* 库函数

;; ============================================================================
;; 柱截面 c:dk
;; ============================================================================

(defun c:dk (/ p1 p3 w h scale layer)
  (uc:guard-begin '())
  "绘制矩形柱截面（填充 SOLID 图案）。"
  (setq scale (sys:get '*SYS:DWG-SCALE*)
        layer (sys:get '*PRJ:COLUMN-LAYER*))
  (lay:make layer 4 "Continuous")  ; 青色
  (if (or (and (setq p1 (getpoint "\n柱角点: "))
              (if (setq p3 (getcorner p1 "\n对角点: "))
                T
                (progn (princ "\n未指定对角点。") nil)))
          (and (setq p1 (getpoint "\n柱角点: "))
               (setq w (safe:get-real "柱宽" 400))
               (setq h (safe:get-real "柱高" 400))
               (setq p3 (list (+ (car p1) w) (+ (cadr p1) h) 0.0))))
    (progn
      ;; 绘制柱轮廓及填充
      (entity:make-pline (point:rect-2pt->4pt p1 p3) T layer)
      (command "_.-HATCH" "_S" "_L" "" "_P" "SOLID" "")
      (princ "\n柱截面已绘制。")))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 圆形柱截面 c:dkk
;; ============================================================================

(defun c:dkk (/ pt r layer)
  (uc:guard-begin '())
  "绘制圆形柱截面。"
  (setq layer (sys:get '*PRJ:COLUMN-LAYER*))
  (lay:make layer 4 "Continuous")
  (if (and (setq pt (getpoint "\n圆心: "))
           (setq r  (safe:get-real "半径" 200)))
    (progn
      (entity:make-circle pt r layer)
      (command "_.-HATCH" "_S" "_L" "" "_P" "SOLID" "")
      (princ "\n圆形柱截面已绘制。")))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 墙身大样 c:sg
;; ============================================================================

(defun c:sg (/ p1 p2 wall-thk len ang h)
  (uc:guard-begin '())
  "绘制墙身施工缝符号（中心虚线 + 实线边）。"
  (if (and (setq p1 (getpoint "\n墙起点: "))
           (setq p2 (getpoint p1 "\n墙终点: ")))
    (progn
      (setq wall-thk (safe:get-real "墙厚" 200)
            len      (point:dist p1 p2)
            h        (* 0.5 wall-thk)  ; 半墙厚
            ang      (point:angle p1 p2))

      ;; 先创建图层（否则 entmake 引用不存在的图层会失败）
      (lay:make "施工缝中心线" 8 "CENTER")
      (lay:make "管边" 7 "Continuous")
      ;; 中心虚线
      (entity:make-line p1 p2 "施工缝中心线")
      (command "_.CHPROP" "_L" "" "_LT" "CENTER" "_C" 8 "")

      ;; 两侧实线
      (entity:make-line
        (point:polar p1 (- ang (* pi 0.5)) h)
        (point:polar p2 (- ang (* pi 0.5)) h) "管边")
      (entity:make-line
        (point:polar p1 (+ ang (* pi 0.5)) h)
        (point:polar p2 (+ ang (* pi 0.5)) h) "管边")
      (princ "\n墙身大样已绘制。")))
  (princ)
  (uc:guard-end))


(princ "\n[TB] 墙柱工具模块加载完成 (column: 3命令)")
(princ)
