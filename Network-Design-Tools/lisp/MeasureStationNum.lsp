; Written by Alex McTeague
(defun c:MeasureStationNum ( / textHeight prevLayer pt1 pt2 dist midPoint angleRad angleDeg)
  (setq textHeight 7)

  (setq pt1 (getpoint "\nSelect the first pole (point 1) or press Enter to exit: "))
  (if (null pt1) (progn (princ "\nCancelled.") (quit)))
  (setq pt2 (getpoint "\nSelect the second pole (point 2): "))
  (if (null pt2) (progn (princ "\nCancelled.") (quit)))
  (setq cline (car (entsel "\nSelect street centerline: ")))
  (if (null cline) (progn (princ "\nCancelled.") (quit)))
  
  ; Find the closest points on the centerline relative to the selected points
  (setq cPt1 (vlax-curve-getclosestpointto cline pt1))
  (setq cPt2 (vlax-curve-getclosestpointto cline pt2))
  
  ; Get the distance along the centerline between those two points
  (setq d1 (vlax-curve-getdistatpoint cline cPt1))
  (setq d2 (vlax-curve-getdistatpoint cline cPt2))
  (setq dist (abs (- d1 d2)))
  (setq dist (fix (+ dist 0.5))) ; Add 0.5 and truncate to round the distance to the nearest foot
  
  ; Format the distance to match the station number syntax
  (setq distStr (itoa dist))
  
  (if (> (strlen distStr) 2)
    (progn
      (setq last2digits (rem dist 100)) ; Get the last 2 digits
      (setq last2digits (padZero last2digits 2)) ; pad with preceeding zeroes (and convert to string)
      (setq extraDigits (substr distStr 1 (- (strlen distStr) 2)))
      (setq extraDigits (padZero (atoi extraDigits) 3))
    )
    (progn
      (setq last2digits (padZero dist 2))
      (setq extraDigits "000")
    )
  )
  
  (princ (strcat "\nDistance: " (itoa dist) "'\nFormatted: \"STA " extraDigits "+" last2digits "\""))
  (princ)
)

(princ "\nType 'MeasureStationNum' to run.")


(defun padZero (num len / sNum)
  (setq sNum (itoa num))
  (while (< (strlen sNum) len)
    (setq sNum (strcat "0" sNum))
  )
  sNum
)

(defun c:MeasureSN () (c:MeasureStationNum))