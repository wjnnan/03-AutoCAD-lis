  
; Helper Functions
(defun XBreak_StartEnd (obj fromProp addZ / coords coordsLen startPt endPt)
  (setq coords (vlax-safearray->list (vlax-variant-value (vlax-get-property obj fromProp))));coords
  (setq coordsLen (- (length coords) 1))
  (if addZ
    (progn
      (setq startPt (trans
        (list (nth 0 coords) (nth 1 coords) 0.0)
        (vlax-vla-object->ename obj) 1)
      )
      (setq endPt (trans
        (list
          (nth (- coordsLen 1) coords)
          (nth coordsLen coords)
          0.0
        )
        (vlax-vla-object->ename obj) 1)
      )
    )
    (progn
      (setq startPt (trans
        (list (nth 0 coords) (nth 1 coords) (nth 2 coords))
        (vlax-vla-object->ename obj) 1)
      )
      (setq endPt (trans
        (list
          (nth (- coordsLen 2) coords)
          (nth (- coordsLen 1) coords)
          (nth coordsLen coords)
        )
        (vlax-vla-object->ename obj) 1)
      )
    )
  )
  (list startPt endPt)
)

(defun XBreak_Pnt_in_Bndry (testPt bndryPt1 bndryPt2 / minX maxX minY maxY)
  (if (< (car bndryPt1) (car bndryPt2))
    (progn (setq minX (car bndryPt1)) (setq maxX (car bndryPt2)))
    (progn (setq minX (car bndryPt2)) (setq maxX (car bndryPt1)))
  )
  (if (< (cadr bndryPt1) (cadr bndryPt2))
    (progn (setq minY (cadr bndryPt1)) (setq maxY (cadr bndryPt2)))
    (progn (setq minY (cadr bndryPt2)) (setq maxY (cadr bndryPt1)))
  )
  (if
    (and
      (>= (car testPt) minX)
      (<= (car testPt) maxX)
      (>= (cadr testPt) minY)
      (<= (cadr testPt) maxY)
    )
    T
    nil
  )
)