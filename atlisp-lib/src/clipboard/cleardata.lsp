(defun clipboard:cleardata (/ cb)
  "Çå¿Õ¼ôÌù°åÄÚÈİ"
  "-1"
  "(clipboard:cleardata)"
  (clipboard:init)
  (vlax-invoke @:*clipboard* (quote cleardata)
    "text"))
