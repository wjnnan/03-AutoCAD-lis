; Written by Alex McTeague
(defun c:MeasureCallouts ( / textHeight prevLayer pt1 pt2 dist midPoint angleRad angleDeg)
  (setq textHeight 7)

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
    (princ (strcat "\nAerial span footage: " (itoa dist) "'"))

    ; Calculate the angle in radians and degrees
    (if (= pt2X pt1X)
      (if (> pt2Y pt1Y)
        (setq angleRad (* pi 0.5))
        (setq angleRad (* pi 1.5))
      )
      (setq angleRad (atan (/ 
        (- pt2Y pt1Y)
        (- pt2X pt1X)
      )))
    )
    (setq angleDeg (* angleRad (/ 180 pi)))
    
    ; Ask the user for the callout location
    (setq midPoint (getpoint "\nSelect the callout location: "))
    (if (null midPoint) (progn (princ "\nNo location selected -- aborting.") (quit)))

    ; Offset the chosen points by the text height and angle
    (setq offsetVX (* textHeight (cos (+ angleRad (* pi 0.5)))))
    (setq offsetVY (* textHeight (sin (+ angleRad (* pi 0.5)))))
    (setq offsetHX (* textHeight (cos angleRad)))
    (setq offsetHY (* textHeight (sin angleRad)))
    
    (setq bpt1 (list (- (car midpoint) (* offsetHX 1.5)) (- (cadr midpoint) (* offsetHY 1.5))))
    (setq bpt2 (list (+ (car midpoint) (* offsetHX 1.5)) (+ (cadr midpoint) (* offsetHY 1.5))))

    (setq bpt1H (list (+ (car bpt1) (* offsetVX 0.65)) (+ (cadr bpt1) (* offsetVY 0.65))))
    (setq bpt1C (list (- (car bpt1) (* offsetHX 0.65)) (- (cadr bpt1) (* offsetHY 0.65))))
    (setq bpt1L (list (- (car bpt1) (* offsetVX 0.65)) (- (cadr bpt1) (* offsetVY 0.65))))
    
    (setq bpt2H (list (+ (car bpt2) (* offsetVX 0.65)) (+ (cadr bpt2) (* offsetVY 0.65))))
    (setq bpt2C (list (+ (car bpt2) (* offsetHX 0.65)) (+ (cadr bpt2) (* offsetHY 0.65))))
    (setq bpt2L (list (- (car bpt2) (* offsetVX 0.65)) (- (cadr bpt2) (* offsetVY 0.65))))
    
    ; Turn off Object Snapping, which messes with object placement/math
    (setq prevOSMode (getvar "osmode"))
    (setvar 'osmode 0)
    
    ; Change to Street Name layer
    (setq prevLayer (getvar "clayer"))
    (command "_.CLAYER" "0")
    
    ; Change color to ByLayer
    (setq prevColor (getvar "cecolor"))
    (command "_.CECOLOR" "ByLayer")
    
    ; Create the text callout at the midpoint, rotated to match the angle
    (command "_.TEXT" "J" "M" midPoint textHeight angleDeg (strcat (itoa dist) "'"))
    ; Return to previous state
    (setvar 'osmode prevOSMode)
    (command "_.CLAYER" prevLayer)
    (command "_.cecolor" prevColor)
      )
    )
  )

  (princ "\nCallout creation canceled.")
)

(princ "\nType 'MeasureCallouts' to run.")

