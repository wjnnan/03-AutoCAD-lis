(defun c:MeasureCallouts ( / pt1 pt2 distance midPoint angle) 
  (while (setq pt1 (getpoint "\nSelect the first pole (point 1) or press Enter to exit: "))
    (setq pt2 (getpoint "\nSelect the second pole (point 2): "))
    (if pt2
      (progn
    ;; Calculate the distance between the two points manually
    (setq distance (sqrt (+ 
                          (expt (- (car pt2) (car pt1)) 2) 
                          (expt (- (cadr pt2) (cadr pt1)) 2))))

    ;; Round the distance to the nearest foot (integer)
    (setq distance (fix (+ distance 0.5))) ;; Adds 0.5 and truncates to simulate rounding

    ;; Create a callout with the distance at the midpoint of the two points
    (setq midPoint (list (/ (+ (car pt1) (car pt2)) 2.0)
                         (/ (+ (cadr pt1) (cadr pt2)) 2.0)))

    ;; Calculate the angle in degrees
    (setq angle (atan (/ (- (cadr pt2) (cadr pt1))
                          (- (car pt2) (car pt1)))))

    ;; Convert radians to degrees
    (setq angle (* angle (/ 180 pi)))

    ;; Create the text callout at the midpoint, rotated to match the angle, with a text height of 3.961325
    (command "_.TEXT" midPoint 3.961325 angle (strcat (itoa distance) "'"))

    (princ (strcat "\nAerial span footage distance: " (itoa distance) "'"))
      )
    )
  )

  (princ "\nCallout creation canceled.")
)

(princ "\nType 'MeasureCallouts' to run.")

