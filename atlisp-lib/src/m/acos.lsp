(defun m:acos (x)
    "arccos,arcos,º∆À„∑¥”‡œ“÷µ"
    (if (<= -1.0 x 1.0)
        (atan (sqrt (- 1.0 (* x x)))
            x)))
