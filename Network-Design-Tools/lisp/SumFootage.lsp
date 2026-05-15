; Written by Alex McTeague
(defun c:SumFootage ()
  (vl-load-com)  ;; Ensure Visual LISP functions are available
  (setq total 0)
  
  ;; Prompt user to select a polyline boundary
  (setq pline (car (entsel "\nSelect a polyline boundary: ")))
  (if (and pline (= (cdr (assoc 0 (entget pline))) "LWPOLYLINE"))
    (progn
      ;; Get bounding box of polyline
      (setq plObj (vlax-ename->vla-object pline))
      (vla-GetBoundingBox plObj 'minPt 'maxPt)
      (setq minPt (vlax-safearray->list minPt)
            maxPt (vlax-safearray->list maxPt))
      
      ;; Get all text objects in the drawing
      (setq textObjs (ssget "X" '((0 . "TEXT,MTEXT"))))
      
      (if textObjs
        (progn
          (setq i 0)
          (while (< i (sslength textObjs))
            (setq ent (ssname textObjs i)
                  entData (entget ent)
                  txt (cdr (assoc 1 entData))
                  pos (cdr (assoc 10 entData)))
            
            ;; Check if text position is inside the polyline bounding box
            (if (and (>= (car pos) (car minPt)) (<= (car pos) (car maxPt))
                     (>= (cadr pos) (cadr minPt)) (<= (cadr pos) (cadr maxPt)))
              (if (wcmatch txt "*[0-9]'*")  ;; Check if text contains a number followed by '
                (setq total (+ total (atoi (substr txt 1 (- (vl-string-search "'" txt) 0)))))))
            (setq i (1+ i)))
          
          (princ (strcat "Total Footage: " (itoa total) "'"))
        )
        (princ "No valid footages found within the boundary.")))
    (princ "Invalid selection. Please select a polyline boundary."))
  (princ))
