; Written by Alex McTeague
(defun c:CenterText ( / txtset i ename)
  (print "Select entire import")
  (setq txtset (ssget '((0 . "*TEXT") (8 . "PDF*_Text"))))
  (if txtset
    (progn
      (setq i 0)
      (while (setq ename (ssname txtset i))
        (command "_JUSTIFYTEXT" ename "" "MC")
        (setq i (1+ i))
      )
    )
  )
)