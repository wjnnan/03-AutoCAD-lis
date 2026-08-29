(defun matrix:rotation-z (rz / crz srz)
  "¹¹ÔìzÖáĞı×ª¾ØÕó"
  (list
   (list (setq crz(cos rz))(setq srz(sin rz)) 0 0)
   (list (- srz) crz 0 0)
   (list 0 0 1 0)
   (list 0 0 0 1)
   ))
