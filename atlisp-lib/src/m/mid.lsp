(defun m:mid (x y / a b)
    "º∆À„÷–µ„"
    (mapcar (quote (lambda (a b)
                (* (+ a b)
                    0.5)))
        x y))
