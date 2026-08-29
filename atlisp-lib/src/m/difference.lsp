(defun m:difference (lst1 lst2 / lst)
    "ÁÐ±í²î¼¯"
    (vl-remove-if (quote (lambda (x)
                (member x lst2)))
        lst1))
