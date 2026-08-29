(defun block:list (/ res name)
  "ÁĞ¿éµÄÃû³Æ"
  "list"
  (if (setq name (cdr (assoc 2 (tblnext "block" t))))
      (setq res (cons name nil)))
  (while (setq name (tblnext "block"))
    (setq res (cons (cdr (assoc 2 name)) res)))
  res)
