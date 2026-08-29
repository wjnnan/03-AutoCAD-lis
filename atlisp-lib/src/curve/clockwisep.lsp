(defun curve:clockwisep (ent / fx offsetobj offsetresult plineobj)
  "判断多段线方向"
  "顺时针返回t，反之nil"
  "(curve:clockwisep (car(entsel)))"
  (setq plineobj (vlax-ename->vla-object ent))
  (setq offsetresult (vl-catch-all-apply 'vla-offset (list plineobj 0.0001)))
  (if (vl-catch-all-error-p offsetresult)
    nil  ; 自交多段线等无法偏移
    (progn
      (setq offsetplineobj (car (vlax-safearray->list (vlax-variant-value offsetresult))))
      (if (> (vlax-curve-getdistatparam plineobj (vlax-curve-getendparam plineobj))
             (vlax-curve-getdistatparam offsetplineobj (vlax-curve-getendparam offsetplineobj)))
        (setq fx t)
        (setq fx nil))
      (vla-delete offsetplineobj)
      fx)))
