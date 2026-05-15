; Written by Alex McTeague
(defun c:MeasureArrow ( / prevLayer pt1 pt2 dist midPt)
  ; Define a helper function to find the midpoint of two points
  (defun find-midpoint (pt1 pt2)
    (mapcar '(lambda (a b) (/ (+ a b) 2.0)) pt1 pt2)
  )  

  (while (setq pt1 (getpoint "\nSelect the first pole (point 1) or press Enter to exit: "))
    (setq pt2 (getpoint "\nSelect the second pole (point 2): "))
    (if pt2
      (progn
    ; Get the X and Y coordinates of each point
    (setq pt1X (car pt1))
    (setq pt1Y (cadr pt1))
    (setq pt2X (car pt2))
    (setq pt2Y (cadr pt2))

    ; Calculate the distance between the two points
    (setq dist (sqrt (+
      (expt (- pt2X pt1X) 2)
      (expt (- pt2Y pt1Y) 2)
    )))
    (setq dist (fix (+ dist 0.5))) ; Add 0.5 and truncate to round the distance to the nearest foot
    (princ (strcat "\nDistance: " (itoa dist) "'"))

    ; Find the callout location
    (setq midPt (find-midpoint pt1 pt2))

    ; Turn off Object Snapping, which messes with object placement/math
    (setq prevOSMode (getvar "osmode"))
    (setvar 'osmode 0)

    ; Change to DIMS layer
    (setq prevLayer (getvar "clayer"))
    (command "_.CLAYER" "DIMS")

    ; Change color to Black
    (setq prevColor (getvar "cecolor"))
    (command "_.CECOLOR" "15,15,15")

    ; Create a Dim Align
    (command "_.DIMALIGNED" pt1 pt2 "T" (strcat (itoa dist) "'") midPt)
    (setq dimAlignObj (vlax-ename->vla-object (entlast)))
    (vlax-put-property dimAlignObj 'ArrowheadSize 5)
    (vlax-put-property dimAlignObj 'TextStyle "DIM-50scale")

    ; Return to previous state
    (setvar 'osmode prevOSMode)
    (command "_.CLAYER" prevLayer)
    (command "_.CECOLOR" prevColor)
      )
    )
  )

  (princ "\nCallout creation canceled.")
)

(princ "\nType 'MeasureArrow' to run.")

