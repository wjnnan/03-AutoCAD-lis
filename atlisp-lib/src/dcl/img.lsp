(defun dcl:img (key width height)
  "dcl Í¼Ïñ¿Ø¼þ¡£"
  ""
  "(dcl:img \"img1 10 5)"
  (write-line (strcat ":image{key=\""
      key "\";width="
      (rtos width 2)
      ";height="
      (rtos height 2)
      ";color=152;}")
    dcl-fp))
