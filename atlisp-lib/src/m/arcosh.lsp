(defun m:arcosh (x)
    "arccosh,aconsh,¼ÆËã·´Ë«ÇúÓàÏÒÖµ"
    (if (<= 1.0 x)
        (log (+ x (sqrt (1- (* x x)))))))
