(defun list:rtrim (lst m)
    "É¾³ı±íÎ²mÏî"
    (reverse (list:ltrim (reverse lst)
            m)))
