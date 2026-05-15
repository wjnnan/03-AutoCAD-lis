;;; tb-lib-dim.lsp — 标注操作库
;;; 标注实体的查询与修改。
;;; 依赖：tb-core.lsp, tb-lib-entity.lsp

;; ============================================================================
;; 标注查询
;; ============================================================================

(defun dim:get-text (ename / override)
  "获取标注的文字内容（覆写文字或默认测量值）。"
  (setq override (entity:get-dxf ename 1))
  (if (and override (/= override ""))
    override
    (if (setq override (entity:get-dxf ename 42))
      (rtos override 2 0)
      "")))

(defun dim:set-text (ename str)
  "设置标注覆写文字。str 为 \"\" 则恢复默认测量值。"
  (entity:set-dxf ename 1 str))

(defun dim:get-measurement (ename)
  "获取标注的实际测量值（组码 42）。"
  (entity:get-dxf ename 42))

(defun dim:get-height (ename)
  "获取标注文字高度。"
  (entity:get-dxf ename 140))

(defun dim:set-height (ename h)
  "设置标注文字高度。"
  (entity:set-dxf ename 140 h))

(defun dim:get-style (ename)
  "获取标注样式名。"
  (entity:get-dxf ename 3))

(defun dim:set-style (ename style)
  "设置标注样式。"
  (entity:set-dxf ename 3 style))


;; ============================================================================
;; 标注状态
;; ============================================================================

(defun dim:is-overridden? (ename)
  "检查标注是否有文字覆写（假注检测）。DXF 1 缺失或空串均视为未覆写。"
  (not (member (entity:get-dxf ename 1) '(nil ""))))

(defun dim:reset-text (ename)
  "清除标注文字覆写，恢复默认测量值。"
  (entity:set-dxf ename 1 ""))


;; ============================================================================
;; 标注归位
;; ============================================================================

(defun dim:home (ename)
  "将标注文字回到原位。等价于 dimtedit → Home。"
  (uc:command-safe (list "_.DIMTEDIT" ename "_H")))

(defun dim:home-selection (ss)
  "将选择集中所有标注文字归位。"
  (sel:for-each ss 'dim:home))


;; ============================================================================
;; 标注创建
;; ============================================================================

(defun dim:make-rotated (pt1 pt2 pt3 style)
  "创建旋转标注（对齐两点后旋转到指定方向）。
pt1: 第一点 pt2: 第二点 pt3: 标注线位置。"
  (entmakex
    (list '(0 . "DIMENSION")
          '(100 . "AcDbEntity")
          '(100 . "AcDbDimension")
          (cons 3 (if style style (getvar "DIMSTYLE")))
          (cons 10 pt3)      ; 标注线位置
          (cons 13 pt1)      ; 第一尺寸界线起点
          (cons 14 pt2)      ; 第二尺寸界线起点
          '(70 . 33))))       ; 旋转标注标志


(princ "\n[TB] 标注操作库加载完成 (dim:*)")
(princ)
