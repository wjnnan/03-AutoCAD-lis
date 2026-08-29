;;; tb-mod-beam.lsp — 梁平法工具模块
;;; 梁截面符号、剖切符号、图名线。
;;; 组合 point:* curve:* entity:* txt:* lay:* 库函数

;; ============================================================================
;; 图名线 c:tml
;; ============================================================================

(defun c:tml (/ e pts ang w p1 p2 inspt en1 en2)
  (uc:guard-begin '())
  "图名线：在所选文字下方绘制双下划线。"
  (if (setq e (car (entsel "\n选择图名字: ")))
    (if (wcmatch (entity:get-type e) "TEXT")
      (progn
        (setq pts   (entity:get-bbox e 0)
              ang   (txt:get-rotation e)
              inspt (txt:get-inspt e)
              w     (- (caadr pts) (caar pts))   ; 文字宽度
              p1    (point:polar inspt (- ang (* pi 0.5)) 50)  ; 线下偏移
              p2    (point:polar p1 ang w))
        ;; 第一道线（粗）
        (if (setq en1 (entity:make-pline (list p1 p2) nil (entity:get-layer e)))
          (command "_.PEDIT" en1 "_W" 30 ""))
        ;; 第二道线（细）
        (setq p1 (point:polar p1 (+ ang (* pi 0.5)) 60)
              p2 (point:polar p1 ang w))
        (entity:make-pline (list p1 p2) nil (entity:get-layer e)))
      (princ "\n所选不是单行文字。")))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 剖切符号 c:pq
;; ============================================================================

(defun c:pq (/ p1 p2 ang mid label scale en0 en1 en2 en3)
  (uc:guard-begin '())
  "剖切符号。选择剖切位置，自动生成剖面编号和方向线。"
  (setq scale (sys:get '*SYS:DWG-SCALE*))
  (if (setq p1 (getpoint "\n剖切起点: "))
    (if (setq p2 (getpoint p1 "\n剖切终点: "))
      (progn
        (setq ang  (point:angle p1 p2)
              mid  (point:mid p1 p2))

        ;; 剖切位置线（p1→p2 粗线）
        (if (setq en0 (entity:make-pline (list p1 p2) nil (getvar "CLAYER")))
          (command "_.PEDIT" en0 "_W" (* 2 scale) ""))

        ;; 两端方向线（垂直于剖切位置的短粗线）
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
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 平面号 c:pmh
;; ============================================================================

(defun c:pmh (/ pt label h scale en base)
  (uc:guard-begin '())
  "平面号标注：在指定位置绘制标高/平面号符号。"
  (setq scale (sys:get '*SYS:DWG-SCALE*)
        h     (* 350 scale))
  (if (setq pt (getpoint "\n符号插入点: "))
    (progn
      (setq label (getstring T "\n楼层标签（如 3F）: ")
            base  (point:polar pt (* pi 0.5) (* 300 scale)))
      ;; 倒三角
      (if (setq en (entity:make-pline
            (list pt
                  (point:polar base pi (* 200 scale))
                  (point:polar base 0  (* 200 scale)))
            T (getvar "CLAYER")))
        (command "_.PEDIT" en "_W" 0 ""))
      ;; 文字
      (if (and label (/= label ""))
        (entity:make-text label
          (point:polar pt (* pi 0.5) (* 100 scale))
          h (sys:get '*SYS:TEXT-STYLE*) (getvar "CLAYER")))))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 画结构洞口（吸收张和平工具箱"画洞口"）
;; ============================================================================

(defun c:HOLE (/ ms p1 p3 x1 y1 x3 y3 p2 p4 x5 y5 p5)
  "画结构洞口（矩形+对角线）。A开洞/B不开洞/C开洞并填充。"
  (uc:guard-begin '("OSMODE" "BLIPMODE" "CMDECHO" "CLAYER"))
  (setvar "cmdecho" 0)
  (setvar "blipmode" 0)
  (setq ms (getstring "\n(A)开洞(默认)/(B)不开洞/(C)开洞并填充: "))
  (if (= ms "") (setq ms "A"))
  (if (and (setq p1 (getpoint "\n输入矩形洞口角点: "))
           (setq p3 (getcorner p1 "\n输入另一角点: ")))
    (progn
      (setq x1 (car p1) y1 (cadr p1) x3 (car p3) y3 (cadr p3)
            p2 (list x3 y1) p4 (list x1 y3)
            x5 (+ x1 (* 0.15 (- x3 x1)))
            y5 (+ y1 (* 0.85 (- y3 y1)))
            p5 (list x5 y5))
      (setvar "osmode" 0)
      (cond
        ((or (= ms "A") (= ms "a")) (lay:make "结洞口实" 7 "continuous"))
        ((or (= ms "B") (= ms "b")) (lay:make "结洞口虚" 7 "dash"))
        (t (lay:make "结洞口实" 7 "continuous")))
      (command "line" p1 p2 p3 p4 p1 "")
      (command "line" p1 p5 p3 "")
      (if (or (= ms "C") (= ms "c"))
        (command "solid" p1 p4 p5 p3 ""))))
  (uc:guard-end)
  (princ))

(princ "\n[TB] 梁平法工具模块加载完成 (beam: 4命令)")
(princ)
