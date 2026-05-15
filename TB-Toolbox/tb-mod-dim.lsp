;;; tb-mod-dim.lsp — 标注处理模块
;;; 组合 dim:* entity:* sel:* 库函数。
;;; 原文件来源：F:\结构插件\标注.lsp（8命令）— 去重改写

;; ============================================================================
;; 标注归位
;; ============================================================================

(defun c:fw (/ ss)
  "标注复位：将选中标注文字回到默认位置。"
  (if (setq ss (ssget '((0 . "DIMENSION"))))
    (dim:home-selection ss))
  (princ "\n标注已复位。")
  (princ))


;; ============================================================================
;; 标注取齐
;; ============================================================================

(defun c:bbq (/ ss p0 p00)
  "标注取齐：将标注线对齐到指定位置。
第一次点击=标注线位置，第二次点击=尺寸界线位置。"
  (if (setq ss (ssget '((0 . "DIMENSION"))))
    (progn
      (if (setq p0 (getpoint "\n标注线对齐位置（回车跳过）: "))
        (sel:for-each ss
          '(lambda (e / p10 p11 ent)
             (setq ent (entget e)
                   p10 (cdr (assoc 10 ent))
                   p11 (cdr (assoc 11 ent)))
             (entity:set-dxf e 10 (list (car p10) (cadr p0) 0.0))
             (entity:set-dxf e 11 (list (car p11) (cadr p0) 0.0)))))
      (if (setq p00 (getpoint "\n尺寸界线位置（回车跳过）: "))
        (sel:for-each ss
          '(lambda (e / p13 p14 ent)
             (setq ent (entget e)
                   p13 (cdr (assoc 13 ent))
                   p14 (cdr (assoc 14 ent)))
             (entity:set-dxf e 13 (list (car p13) (cadr p00) 0.0))
             (entity:set-dxf e 14 (list (car p14) (cadr p00) 0.0)))))))
  (princ))


;; ============================================================================
;; 标注等分
;; ============================================================================

(defun c:bbf (/ ss parts-val)
  "将标注文字显示为等分格式。例：3000 → 3000/2=1500。"
  (setq parts-val (max 2 (safe:get-int "等分数" (sys:ifnil *TMP:LAST-DIM-DIV* 2))))
  (setq *TMP:LAST-DIM-DIV* parts-val)
  (if (setq ss (ssget '((0 . "DIMENSION"))))
    (sel:for-each ss
      '(lambda (e / meas)
         (setq meas (dim:get-measurement e))
         (dim:set-text e
           (strcat (rtos meas 2 (sys:get '*SYS:DIM-PRECISION*))
                   "/" (itoa parts-val)
                   "=" (rtos (/ meas parts-val) 2 (sys:get '*SYS:DIM-PRECISION*)))))))
  (princ))


;; ============================================================================
;; 标注层/样式管理
;; ============================================================================

(defun c:bgc (/ ss layer)
  "标注归层：将所有标注移到 S_DIM 图层。"
  (setq layer (or (sys:get '*PRJ:DIM-LAYER*) "S_DIM"))
  (lay:make layer 3)  ; 绿色
  (if (setq ss (ssget '((0 . "DIMENSION"))))
    (lay:move-selection ss layer))
  (princ (strcat "\n标注已移至图层: " layer))
  (princ))

(defun c:ggb (/ ss h)
  "修改标注文字高度。"
  (if (setq ss (ssget '((0 . "DIMENSION"))))
    (progn
      (setq h (safe:get-real "标注文字高度" (sys:ifnil *TMP:LAST-DIM-H* 350)))
      (setq *TMP:LAST-DIM-H* h)
      (sel:for-each ss '(lambda (e) (dim:set-height e h)))))
  (princ))

(defun c:gbb (/ ss val)
  "修改标注文字值（覆写）。"
  (setq val (getstring T "\n新文字值（回车恢复默认）: "))
  (if (setq ss (ssget '((0 . "DIMENSION"))))
    (if (= val "")
      (sel:for-each ss 'dim:reset-text)
      (sel:for-each ss '(lambda (e) (dim:set-text e val)))))
  (princ))


;; ============================================================================
;; 坐标标注
;; ============================================================================

(defun c:zb (/ pt h)
  "在指定点创建坐标标注（X,Y）。"
  (entity:make-style "TSSD_Rein" "tssdeng.shx" "hztxt.shx" 0.7)
  (setq h  (or (sys:get '*SYS:TEXT-HEIGHT*) 350)
        pt (getpoint "\n标注点: "))
  (if pt
    (progn
      (entity:make-text
        (strcat "X=" (rtos (car pt) 2 0) "\nY=" (rtos (cadr pt) 2 0))
        pt h "TSSD_Rein" (getvar "CLAYER"))))
  (princ))


(princ "\n[TB] 标注处理模块加载完成 (dim: 7命令)")
(princ)
