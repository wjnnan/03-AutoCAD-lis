(defun c:CircleNumber (/ ent obj pt num suffix radius textHeight circleCenter textPt finalTextHeight)
  (setq ent (entsel "\nSelect polyline: "))
  (if ent
    (progn
      (setq pt (getpoint "\nSpecify point on polyline: "))
      (if (null pt) (progn (princ "\nNo point specified -- aborting.") (quit)))
      (setq num (getint "\nEnter number (1-10): "))
      (if (null num) (progn (princ "\nNo number entered -- aborting.") (quit)))
      (if (and (>= num 1) (<= num 10))
        (progn
          (setq suffix (getstring "\nEnter suffix (a, b, c, d, e or leave blank): "))
          (setq radius (/ 8.020710 2)) ; Set the radius of the circle to half the diameter
          (setq textHeight (* radius 0.95)) ; Adjust text height to be 95% of the radius
          (setq finalTextHeight (if (equal suffix "") textHeight (* textHeight 0.95))) ; Further adjust text height if suffix is used
          (setq circleCenter pt)
          (command "._-layer" "M" "NOTES" "")
          (command "._circle" circleCenter radius)
          (command "._chprop" "L" "" "LW" "ByLayer" "")
          (command "._text" "J" "MC" circleCenter finalTextHeight 0.0 (strcat (itoa num) suffix))
        )
        (princ "\nInvalid number. Please enter a number between 1 and 10.")
      )
    )
  )
  (princ)
)
