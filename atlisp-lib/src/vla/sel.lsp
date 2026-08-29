(defun vla:sel (/ ent)
  "单选对象，返回 vla-object 或 nil（用户取消时）。"
  (if (setq ent (car (entsel)))
    (e2o ent)
    nil))
