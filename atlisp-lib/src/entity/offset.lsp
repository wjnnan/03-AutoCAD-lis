(defun entity:offset (obj dis / offsetobj)
  "偏移对象"
  (if (p:enamep obj)
    (setq obj (vlax-ename->vla-object obj)))
  (setq offsetresult-6 (vl-catch-all-apply 'vla-offset (list obj dis)))
  (if (vl-catch-all-error-p offsetresult-6)
    (setq offsetobj nil)
    (setq offsetobj offsetresult-6)))
