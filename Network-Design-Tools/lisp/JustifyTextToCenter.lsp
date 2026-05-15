; Written by Alex McTeague
(defun c:justify_text_to_middle_center ()
  (setq ss (ssget '((0 . "*TEXT") (8 . "PDF*_Text"))))
  (if ss
    (progn
      (setq i 0)
      (while (setq txt (ssname ss i))
        (setq txtobj (vlax-ename->vla-object txt))
        (vla-put-justification txtobj acTextMiddleCenter)
        (vla-put-height txtobj (vla-get-height txtobj))
        (vla-update txtobj)
        (setq i (1+ i))
      )
    )
  )
  (princ)
)