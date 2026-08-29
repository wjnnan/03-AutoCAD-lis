;;; tb-mod-cloud.lsp — 修订云线与箭头模块
;;; 组合 point:* curve:* entity:* lay:* txt:* 库函数。
;;; 原文件来源：F:\结构插件\常用.lsp (c:rt, c:jt, c:xd)
;;; 重写：去掉 vla-getboundingbox/vla-IntersectWith → 用纯 Lisp 替代

;; ============================================================================
;; 修订云线 c:rt
;; ============================================================================

(defun c:rt (/ p1 p3 ss pts lst en cloud-en mpt pt1 pt2 ang
              in_pt leader-en text-en textlst ds textpt)
  (uc:guard-begin '())
  "修订云线标注工具。选择闭合多段线或指定矩形 → 创建云线 → 引线 → 文字。
全局参数：*SYS:CLOUD-LAYER* *SYS:CLOUD-ARC* *SYS:DWG-SCALE* *SYS:TEXT-STYLE*"

  ;; 确保图层和样式存在
  (lay:make (sys:get '*SYS:CLOUD-LAYER*) (sys:get '*SYS:CLOUD-COLOR*))
  (txt:make-style (sys:get '*SYS:TEXT-STYLE*)
                  (sys:get '*SYS:TEXT-FONT*)
                  (sys:get '*SYS:TEXT-BIGFONT*)
                  (sys:get '*SYS:TEXT-WIDTH*))

  ;; 获取边界：多段线 或 两点矩形
  (initget "S")
  (if (setq p1 (getpoint
        (strcat "\n第一点 / <S选择闭合多段线>（比例 1:"
                (rtos (sys:get '*SYS:DWG-SCALE*) 2 0) "）: ")))
    (if (= p1 "S")
      ;; 选择模式
      (if (setq ss (ssget ":E:S" '((0 . "LWPOLYLINE"))))
        (setq pts (curve:vertices (ssname ss 0)))
        (progn (princ "\n未选择有效多段线。") (quit)))
      ;; 两点模式
      (if (setq p3 (getcorner p1 "\n对角点: "))
        (setq pts (point:rect-pts p1 p3))
        (progn (princ "\n未指定对角点。") (quit))))
    ;; 空回车退出
    (progn (princ "\n已取消。") (quit)))

  ;; 创建云线（用 REVCLOUD 命令产生云线外观）
  (setq cloud-en (entity:make-pline pts T (sys:get '*SYS:CLOUD-LAYER*)))
  (if cloud-en
    (command "_.REVCLOUD" "_A"
      (* (sys:get '*SYS:CLOUD-ARC*) (sys:get '*SYS:DWG-SCALE*)) ""
      "_O" cloud-en "_N"))

  ;; 获取云线包围盒中心
  (setq mpt (point:center pts))

  ;; 引线
  (if (and cloud-en (setq pt1 (getpoint mpt "\n引线起点（指向云线）: ")))
    (progn
      ;; 引线起点在云线边界上
      (setq in_pt (curve:closest-pt cloud-en pt1))
      (entity:make-line (point:mid mpt pt1) in_pt (sys:get '*SYS:CLOUD-LAYER*))

      ;; 文字方向
      (if (setq pt2 (getpoint pt1 "\n文字位置: "))
        (progn
          (setq ang (angle pt1 pt2))
          ;; 文字
          (entity:make-text "修改说明"
            (point:polar pt1 (+ ang (* pi 0.5)) (* 0.625 (sys:get '*SYS:DWG-SCALE*)))
            (* (sys:get '*SYS:TEXT-HEIGHT*) (sys:get '*SYS:DWG-SCALE*))
            (sys:get '*SYS:TEXT-STYLE*)
            (sys:get '*SYS:CLOUD-LAYER*))
          ;; 引线
          (command "_.LEADER" pt1 pt2 "" "_N")
          (princ "\n请用 ddedit 修改文字内容。"))
        (princ "\n未指定文字位置。"))))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 实心箭头 c:jt
;; ============================================================================

(defun c:jt (/ pt0 pt1 dis ang w pt2)
  (uc:guard-begin '())
  "绘制实心箭头（锥形多段线）。起点宽度0 → 箭头尖。"
  (if (setq pt0 (getpoint "\n箭头起点: "))
    (if (setq pt1 (getpoint pt0 "\n箭头终点: "))
      (progn
        (setq dis (point:dist pt0 pt1)
              ang (point:angle pt0 pt1)
              w   (* dis 0.25)           ; 箭头宽 = 1/4 长度
              pt2 (point:polar pt0 ang (* 0.8 dis)))  ; 变宽点
        ;; 用变宽多段线
        (command "_.PLINE" pt0 "_W" 0 w pt1 ""))))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 比例设置 c:xd
;; ============================================================================

(defun c:xd (/ s)
  (uc:guard-begin '())
  "设置云线出图比例。"
  (setq s (getint (strcat "\n出图比例 1: <" (itoa (sys:get '*SYS:DWG-SCALE*)) ">: ")))
  (if (and s (> s 0))
    (sys:set '*SYS:DWG-SCALE* s))
  (princ (strcat "\n当前出图比例: 1:" (itoa (sys:get '*SYS:DWG-SCALE*))))
  (princ)
  (uc:guard-end))


(princ "\n[TB] 云线箭头模块加载完成 (cloud: 3命令)")
(princ)
