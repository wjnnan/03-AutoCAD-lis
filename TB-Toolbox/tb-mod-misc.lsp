;;; tb-mod-misc.lsp — 辅助绘图工具模块
;;; 折断线、焊管缝、施工缝、云朵、绘图辅助等。
;;; 组合 entity:* point:* curve:* lay:* 库函数

;; ============================================================================
;; 折断线 c:dx / c:dxx
;; ============================================================================

(defun c:dx (/ p1 p2 ang mid p3 p4 scale)
  "单折断线。绘制单条 Z 字形折断线。"
  (setq scale (sys:get '*SYS:DWG-SCALE*))
  (if (and (setq p1 (getpoint "\n折断线起点: "))
           (setq p2 (getpoint p1 "\n折断线终点: ")))
    (progn
      (setq ang (point:angle p1 p2)
            mid (point:mid p1 p2))
      ;; Z 字折线
      (entity:make-pline
        (list p1
              (point:polar mid (+ ang (* pi 0.3)) (* 50 scale))
              (point:polar mid (- ang (* pi 0.3)) (* 50 scale))
              p2)
        nil (getvar "CLAYER"))))
  (princ))

(defun c:dxx (/ p1 p2 ang off dist scale)
  "双折断线。在单折断线基础上偏移生成两条。"
  (setq scale (sys:get '*SYS:DWG-SCALE*))
  (if (and (setq p1 (getpoint "\n双折断线起点: "))
           (setq p2 (getpoint p1 "\n双折断线终点: ")))
    (progn
      (setq ang  (point:angle p1 p2)
            dist (point:dist p1 p2)
            off  (* 30 scale))
      (c:dx)  ; 第一条
      ;; 偏移第二条
      (command "_.OFFSET" off (entlast)
        (point:polar p1 (+ ang (* pi 0.5)) off) "")))
  (princ))


;; ============================================================================
;; 水平/竖直断点 c:dd / c:ddd
;; ============================================================================

(defun c:dd (/ pt scale)
  "水平断点符号（V字形）。"
  (setq scale (sys:get '*SYS:DWG-SCALE*))
  (if (setq pt (getpoint "\n断点中心: "))
    (entity:make-pline
      (list (point:polar pt 0 (* -50 scale))
            pt
            (point:polar pt (* pi 0.25) (* -50 scale))
            pt
            (point:polar pt pi (* -50 scale)))
      nil (getvar "CLAYER")))
  (princ))

(defun c:ddd (/ pt scale)
  "竖直断点符号（V字形）。"
  (setq scale (sys:get '*SYS:DWG-SCALE*))
  (if (setq pt (getpoint "\n断点中心: "))
    (entity:make-pline
      (list (point:polar pt (* pi 0.5) (* -50 scale))
            pt
            (point:polar pt (* pi 0.75) (* -50 scale))
            pt
            (point:polar pt (* pi -0.5) (* -50 scale)))
      nil (getvar "CLAYER")))
  (princ))


;; ============================================================================
;; 焊管缝 c:hgf
;; ============================================================================

(defun c:hgf (/ p1 p2 p3 r)
  "焊管缝线——绘制弧-弧焊接缝符号。"
  (if (and (setq p1 (getpoint "\n第一点: "))
           (setq p2 (getpoint p1 "\n第二点: ")))
    (progn
      (setq r (* 0.15 (point:dist p1 p2)))
      (entity:make-arc
        (point:mid p1 p2) r
        (point:angle (point:mid p1 p2) p1)
        (point:angle (point:mid p1 p2) p2)
        "THIN")))
  (princ))


;; ============================================================================
;; 绘图辅助
;; ============================================================================

(defun c:nn nil
  "设置常用对象捕捉组合（端点+中点+圆心+交点+垂足+最近点）。"
  (setvar "osmode" 4791)
  (princ "\n捕捉模式: 端点/中点/圆心/交点/垂足/最近点")
  (princ))

(defun c:qq nil
  "图纸清理：Purge 全部 + 范围缩放 + Audit。"
  (command "_.PURGE" "_A" "" "_N")
  (command "_.AUDIT" "_Y")
  (command "_.ZOOM" "_E")
  (princ "\n图纸已清理。")
  (princ))


;; ============================================================================
;; 说明标签 c:sy
;; ============================================================================

(defun c:sy (/ pt label scale h)
  "图纸说明标签。画水平线 + 圆端 + 文字。"
  (setq scale (sys:get '*SYS:DWG-SCALE*)
        h     (* 350 scale))
  (if (setq pt (getpoint "\n标签插入点: "))
    (progn
      (setq label (getstring T "\n标签文字: "))
      (entity:make-line pt (point:polar pt 0 (* 800 scale)) "说明")
      (entity:make-circle
        (point:polar pt 0 (* 400 scale))
        (* 30 scale) "说明")
      (if (and label (/= label ""))
        (entity:make-text label
          (point:polar pt (* pi 0.5) (* 100 scale))
          h "TSSD_Rein" "说明"))))
  (princ))


(princ "\n[TB] 辅助绘图工具模块加载完成 (misc: 8命令)")
(princ)
