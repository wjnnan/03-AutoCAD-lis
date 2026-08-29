(defun vectra:confirm (msg default / r)
  (initget "Y N ")
  (if (null (setq r (getkword (strcat msg "
            [ÊÇ(Y)/·ñ(N)] <"
            default ">:"))))
    (setq r default))
  r)
