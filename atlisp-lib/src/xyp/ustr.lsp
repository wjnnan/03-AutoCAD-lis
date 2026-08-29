(defun xyp:Ustr (bit msg def spflag / inp nval)
  "×Ö·û´®ÊäÈë¸ñÊ½»¯"
  "string"
  "(setq txt1 (Ustr 1 \"×Ö·û´®\" txt1 nil))"
  (if (and def (/= def ""))
    (setq msg (strcat "\n" msg "<" def ">: ")
	  inp (getstring msg spflag)
	  inp (if (= inp "")def inp)
    )
    (progn
      (setq msg (strcat "\n" msg ": "))
      (if (= bit 1)
	(while (= "" (setq inp (getstring msg spflag))))
	(setq inp (getstring msg spflag))
      )
    )
  )
  (if inp inp def)
)
