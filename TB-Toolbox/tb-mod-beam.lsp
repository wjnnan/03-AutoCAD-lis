;;; tb-mod-beam.lsp — 梁平法工具模块
;;; 梁截面符号、剖切符号、图名线。
;;; 组合 point:* curve:* entity:* txt:* lay:* 库函数

;; ============================================================================
;; 图名线 c:tml
;; ============================================================================

(defun c:tml (/ e pts ang w p1 p2 inspt en1 en2)
  "图名线：在所选文字下方绘制双下划线。"
  (if (setq e (car (entsel "\n选择图名字: ")))
    (if (wcmatch (entity:get-type e) "TEXT")
      (progn
        (setq pts   (entity:get-bbox e 0)
              ang   (txt:get-rotation e)
              inspt (txt:get-inspt e)
              w     (- (caadr pts) (caar pts))   ; 文字宽度
              p1    (point:polar inspt (+ ang (* pi 0.5)) 50)  ; 线下偏移
              p2    (point:polar p1 ang w))
        ;; 第一道线（粗）
        (if (setq en1 (entity:make-pline (list p1 p2) nil (entity:get-layer e)))
          (command "_.PEDIT" en1 "_W" 30 ""))
        ;; 第二道线（细）
        (setq p1 (point:polar p1 (+ ang (* pi 0.5)) 60)
              p2 (point:polar p1 ang w))
        (entity:make-pline (list p1 p2) nil (entity:get-layer e)))
      (princ "\n所选不是单行文字。")))
  (princ))


;; ============================================================================
;; 剖切符号 c:pq
;; ============================================================================

(defun c:pq (/ p1 p2 ang mid label scale en1 en2 en3)
  "剖切符号。选择剖切位置，自动生成剖面编号和方向线。"
  (setq scale (sys:get '*SYS:DWG-SCALE*))
  (if (setq p1 (getpoint "\n剖切起点: "))
    (if (setq p2 (getpoint p1 "\n剖切终点: "))
      (progn
        (setq ang  (point:angle p1 p2)
              mid  (point:mid p1 p2))

        ;; 剖切线（粗线）
        (if (setq en1 (entity:make-pline
              (list p1 (point:polar p1 (+ ang (* pi 0.5)) (* 100 scale)))
              nil (getvar "CLAYER")))
          (command "_.PEDIT" en1 "_W" (* 2 scale) ""))

        (if (setq en2 (entity:make-pline
              (list mid (point:polar mid (+ ang (* pi 0.5)) (* 100 scale)))
              nil (getvar "CLAYER")))
          (command "_.PEDIT" en2 "_W" (* 2 scale) ""))

        (if (setq en3 (entity:make-pline
              (list p2 (point:polar p2 (+ ang (* pi 0.5)) (* 100 scale)))
              nil (getvar "CLAYER")))
          (command "_.PEDIT" en3 "_W" (* 2 scale) ""))

        ;; 方向箭头
        (command "_.LEADER" mid
          (point:polar mid (+ ang (* pi 0.5)) (* 500 scale)) "" "_N")

        ;; 文字标签
        (entity:make-text "A"
          (point:polar mid (- ang (* pi 0.5)) (* 80 scale))
          (* 350 scale) (sys:get '*SYS:TEXT-STYLE*) (getvar "CLAYER")))))
  (princ))


;; ============================================================================
;; 平面号 c:pmh
;; ============================================================================

(defun c:pmh (/ pt label h scale en)
  "平面号标注：在指定位置绘制标高/平面号符号。"
  (setq scale (sys:get '*SYS:DWG-SCALE*)
        h     (* 350 scale))
  (if (setq pt (getpoint "\n符号插入点: "))
    (progn
      (setq label (getstring T "\n楼层标签（如 3F）: "))
      ;; 倒三角
      (if (setq en (entity:make-pline
            (list pt
                  (point:polar pt pi (* 200 scale))
                  (point:polar pt 0  (* 200 scale)))
            T (getvar "CLAYER")))
        (command "_.PEDIT" en "_W" 0 ""))
      ;; 文字
      (if (and label (/= label ""))
        (entity:make-text label
          (point:polar pt (* pi 0.5) (* 100 scale))
          h (sys:get '*SYS:TEXT-STYLE*) (getvar "CLAYER")))))
  (princ))


(princ "\n[TB] 梁平法工具模块加载完成 (beam: 3命令)")
(princ)
