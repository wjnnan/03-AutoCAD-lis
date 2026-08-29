(defun clipboard:getdata (/ cb)
  "»ñÈ¡¼ôÌù°åÄÚÈİ"
  "string or nil"
  "(clipboard:getdata)"
  (clipboard:init)
  (vlax-invoke @:*clipboard* (quote getdata)
    "TEXT"))
