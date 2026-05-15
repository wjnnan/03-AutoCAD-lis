;;; tb-lib-lay.lsp - layer operations library
;;; Uses entmod/table operations for cross-host compatibility.

;; ============================================================================
;; Layer table helpers
;; ============================================================================

(defun lay:get-entry (name)
  "Return the DXF data for a layer table entry, or nil if missing."
  (if (tblobjname "LAYER" name)
    (entget (tblobjname "LAYER" name))))

(defun lay:set-dxf (name code value / entry old)
  "Update a DXF code in the layer table entry."
  (setq entry (lay:get-entry name))
  (if entry
    (progn
      (setq old (assoc code entry))
      (if old
        (entmod (subst (cons code value) old entry))
        (entmod (append entry (list (cons code value))))))))


;; ============================================================================
;; Layer create / query
;; ============================================================================

(defun lay:make (name color linetype)
  "Create a layer or update its shared core-managed properties."
  (uc:ensure-layer name color linetype))

(defun lay:exists? (name)
  "Return T when a layer exists."
  (cond
    ((null name) nil)
    ((and (uc:function-defined-p 'uc:layer-exists-p) name)
     (uc:layer-exists-p name))
    (t
     (and (tblobjname "LAYER" name) T))))

(defun lay:current (name)
  "Set the current layer."
  (setvar "CLAYER" name))

(defun lay:get-current nil
  "Get the current layer name."
  (getvar "CLAYER"))


;; ============================================================================
;; Layer on / off (DXF 62: positive = on, negative = off)
;; ============================================================================

(defun lay:off (name / entry color)
  "关闭指定图层。处理颜色 0(BYBLOCK)/nil 等边界情况。"
  (if (setq entry (lay:get-entry name))
    (progn
      (setq color (cdr (assoc 62 entry)))
      (if (or (null color) (zerop color)) (setq color 7))
      (lay:set-dxf name 62 (- (abs color))))))

(defun lay:on (name / entry color)
  "打开指定图层。"
  (if (setq entry (lay:get-entry name))
    (progn
      (setq color (cdr (assoc 62 entry)))
      (if (null color) (setq color 7))
      (lay:set-dxf name 62 (abs color)))))

(defun lay:off-all-except (except-names)
  "Turn off all layers except those in except-names."
  (lay:foreach
    '(lambda (layname)
       (if (not (member layname except-names))
         (lay:off layname)))))


;; ============================================================================
;; Freeze / thaw (DXF 70, bit 0 = frozen)
;; ============================================================================

(defun lay:freeze (name / entry flags)
  "冻结指定图层（当前图层除外）。使用位或操作，防止重复冻结破坏其他标志位。"
  (if (and (setq entry (lay:get-entry name))
           (not (= name (getvar "CLAYER"))))
    (progn
      (setq flags (cdr (assoc 70 entry)))
      (if (null flags) (setq flags 0))
      (lay:set-dxf name 70 (logior flags 1)))))

(defun lay:thaw (name / entry flags)
  "解冻指定图层。使用位与操作清除冻结位。"
  (if (setq entry (lay:get-entry name))
    (progn
      (setq flags (cdr (assoc 70 entry)))
      (if (null flags) (setq flags 0))
      (lay:set-dxf name 70 (logand flags (~ 1))))))

(defun lay:thaw-all nil
  "解冻所有图层。"
  (lay:foreach '(lambda (layname) (lay:thaw layname))))


;; ============================================================================
;; Lock / unlock (DXF 70, bit 2 = locked)
;; ============================================================================

(defun lay:lock (name / entry flags)
  "锁定指定图层。使用位或操作设置锁定位。"
  (if (setq entry (lay:get-entry name))
    (progn
      (setq flags (cdr (assoc 70 entry)))
      (if (null flags) (setq flags 0))
      (lay:set-dxf name 70 (logior flags 4)))))

(defun lay:unlock (name / entry flags)
  "解锁指定图层。使用位与操作清除锁定位。"
  (if (setq entry (lay:get-entry name))
    (progn
      (setq flags (cdr (assoc 70 entry)))
      (if (null flags) (setq flags 0))
      (lay:set-dxf name 70 (logand flags (~ 4))))))

(defun lay:unlock-all nil
  "Unlock all layers."
  (lay:foreach '(lambda (layname) (lay:unlock layname))))


;; ============================================================================
;; Layer iteration
;; ============================================================================

(defun lay:foreach (callback / layname)
  "Iterate every layer name in the current drawing."
  (while (setq layname (tblnext "LAYER" (not layname)))
    (apply callback (list (cdr (assoc 2 layname))))))

(defun lay:list nil / lst
  "List all layer names."
  (setq lst nil)
  (lay:foreach '(lambda (name) (setq lst (cons name lst))))
  (reverse lst))


;; ============================================================================
;; Entity layer helpers
;; ============================================================================

(defun lay:get-from-entity (ename)
  "Get the layer name from an entity."
  (cdr (assoc 8 (entget ename))))

(defun lay:set-to-entity (ename layname)
  "Move an entity to the specified layer."
  (entmod (subst (cons 8 layname) (assoc 8 (entget ename)) (entget ename))))

(defun lay:move-selection (ss layname)
  "Move every entity in a selection set to the specified layer."
  (sel:for-each ss '(lambda (e) (lay:set-to-entity e layname))))


(princ "\n[TB] layer library loaded (lay:*)")
(princ)
