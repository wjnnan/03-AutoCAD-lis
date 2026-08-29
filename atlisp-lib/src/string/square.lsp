(defun string:square (int str)
  "×Ö·û´®×Ô³Ë"
  (if (zerop int)
    str (strcat str (string:square (1- int)
        str))))
