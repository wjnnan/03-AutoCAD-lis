; Written by Alex McTeague
(defun c:InsertNAP (/ hc portnum blockname insertionpoint scale rotation)
  (setq insertionpoint (getpoint "\nPick insertion point: "))
  (if (null insertionpoint) (progn (princ "\nNo point selected -- aborting.") (quit)))
  
  ; Ask for a single object
  (print "Select house count text")
  (setq enameTxt (car (entsel "\nSelect house count text: ")))
  (if (null enameTxt) (progn (princ "\nNo object selected -- aborting.") (quit)))
  (setq entTxt (entget enameTxt))
  
  ; Check if the selected object is a text object
  (if (not (wcmatch (cdr (assoc 0 entTxt)) "MTEXT,TEXT"))
    (progn
      (princ "\nError: Selected object is not a text object")
      (quit)
    )
  )
  
  (command "_JUSTIFYTEXT" enameTxt "" "MC")

  (setq str (cdr (assoc 1 entTxt)))
  (setq hc (atoi str))
  
  (setq txtHeight (cdr (assoc 40 entTxt)))
  (setq txtPos (cdr (assoc 10 entTxt)))
  (setq scale (/ txtHeight 0.0100))
  (setq scale (/ scale 2))
  (setq radius (* scale 0.0190))
  (setq rot (angle txtPos insertionpoint))
  (setq endPt (list (+ (car insertionpoint) (* radius (cos rot))) (+ (cadr insertionpoint) (* radius (sin rot)))))
  
  ; Housecount
  (cond
    ((< hc 0)
      (progn
        (princ "\nError: House count can't be less than 0")
        (quit)
      )
    )
    ((= hc 0)
      (progn
        (setq layer "2 PORT NAPS")
        (setq blockname "1X2 3RD STAGE SPLITTER")
        (setq portnum "SM")
      )
    )
    ((<= hc 2)
      (progn
        (setq layer "2 PORT NAPS")
        (setq blockname "1X2 3RD STAGE SPLITTER")
        (setq portnum (strcat (itoa hc) "/2"))
      )
    )
    ((<= hc 4)
      (progn
        (setq layer "4 PORT NAPS")
        (setq blockname "1X4 3RD STAGE SPLITTER")
        (setq portnum (strcat (itoa hc) "/4"))
      )
    )
    (t
      (progn
        (princ "\nError: Invalid house count; this macro only supports up to 4-port NAPs")
        (quit)
      )
    )
  )
  
  (setq rotation 0.0)

  ; Switch to the correct layer
  (command "_LAYER"
    "SET" layer
    ""
  )
  
  ; Turn off Object Snapping, which messes with object placement
  (setq prevOSMode (getvar "osmode"))
  (setvar 'osmode 0)
  
  (setvar "ATTDIA" 0)
  (command "-INSERT" blockname endPt scale scale rotation portnum)
  (setq lastEnt (entlast))
  (setvar "ATTDIA" 1)
  
  ; Restore Object Snapping to its previous settings
  (setvar 'osmode prevOSMode)
  
  (setq layer "FLAT DROP")
  (command "_LAYER"
    "SET" layer
    ""
  )
  (command "_COLOR" "BYLAYER")
  (setq i 1)
  (while (<= i hc)
    (setq dropPt (getpoint "\nSelect leader line ending: "))
    (if (null dropPt)
      (princ "\nNo point selected -- skipping.")
      (progn
        ; Turn off Object Snapping, which messes with object placement
        (setq prevOSMode (getvar "osmode"))
        (setvar 'osmode 0)
        (command "._pline" endPt dropPt "")
        ; Restore Object Snapping to its previous settings
        (setvar 'osmode prevOSMode)))
    (setq i (1+ i))
  )
  
  
  (princ)
)
