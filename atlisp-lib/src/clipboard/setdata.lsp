(defun clipboard:setdata (str / cb)
  "ÉèÖÃ¼ôÌù°åÄÚÈİÎª str."
  "-1"
  "(clipboard:setdata \"the string in clipboard.\")"
  (clipboard:init)
  (vlax-invoke @:*clipboard* (quote setdata)
    "text"
    str))
