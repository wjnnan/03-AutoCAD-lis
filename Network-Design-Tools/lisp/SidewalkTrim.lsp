; Written by Alex McTeague
(defun c:SidewalkTrim (/ selPt1 selPt2 selSet entList ent1 ent2 obj1 obj2 intPoints intPointsList intCount newAssoc intList objName startPt endPt)
  (vl-load-com) ; Loads the extended AutoLISP functions related to ActiveX support
  
  ; Enables debug messages (use T or nil for true/false)
  (setq DEBUG nil)
  
  (defun DebugPrint (message)
    ; If the global variable DEBUG is true, print the message
    (if DEBUG
      (progn
        (princ "\n")
        (princ message)
      )
    )
  )
  
  ; Ask the user to select a box
  (setq selPt1 (getpoint "\nSelect start point: "))
  (if selPt1 (setq selPt2 (getcorner selPt1 "\nSelect Opposite Corner")))
  
  ; Find all the Lines, Arcs, PLines, and Circles inside the selected box
  (if (and selPt1 selPt2)
    (setq selSet (ssget "_C" selPt1 selPt2 '((0 . "LINE,ARC,*P*LINE,CIRCLE"))))
  )
  
  ; Note: This routine works by finding lines/arcs/polylines/circles within the selection box.
  ; It checks all intersections between those objects, whether the intersections are in the selection or not.
  ; Therefore, there may be unexpected results if those objects intersect outside the selection.
                
  (cond 
    ((= selSet nil)
      (princ "\nMissing selection or no entities in selection")
    )
    ((< (sslength selSet) 3)
      (princ "\nNot enough entities in selection: 3 entities minimum")
    )
    ((> (sslength selSet) 4)
      (Princ "\nToo many entities in selection: 4 entities maximum")
    )
    ; If no errors were found with the number of selected entities, continue
    (T (progn
      ; Extract the entity names from the selection set into a list
      (DebugPrint "Entities in selection: ")
      (setq i 0)
      (while (< i (sslength selSet))
        (DebugPrint (ssname selSet i))
        (setq entList (cons (ssname selSet i) entList))
        (setq i (1+ i))
      )
      (DebugPrint "\nEntity List: ")
      (foreach ent entList
        (DebugPrint (strcat "\n" (vl-princ-to-string ent)))
      )
      ; Loop through the list
      (foreach ent1 entList
        ; Loop through all selected entities again (nested loop)
        (foreach ent2 entList
          (DebugPrint (strcat "\nComparing " (vl-princ-to-string ent1) " to " (vl-princ-to-string ent2)))
          ; Avoid checking the same entity against itself
          (if (= ent1 ent2)
            (DebugPrint "\nSkipping comparison against self")
            (progn
              ; Convert the entities into objects
              (setq obj1 (vlax-ename->vla-object ent1))
              (setq obj2 (vlax-ename->vla-object ent2))
              ; Find the intersection points between the two objects
              (setq intPoints (vlax-variant-value (vla-IntersectWith obj1 obj2 acExtendNone)))
              ; Verify that the array isn't empty
              (if (> (vlax-safearray-get-u-bound intPoints 1) 0)
                (progn
                  (setq intPointsList (vlax-safearray->list intPoints)) ; This must be done after verifying the array isn't empty
                  ; Each intersection point is represented by three values in the list (its X, Y, Z coordinates)
                  (setq intCount (/ (length intPointsList) 3.0))
                  (DebugPrint (strcat "\nFound " (rtos intCount 2 0) " intersection points"))
                  (if (= intCount 1)
                    ; For now, this routine expects exactly one intersection point between two entities
                    (if (not (assoc ent1 intList))
                      ; If the entity isn't in the list, add it
                      (setq intList (cons (cons ent1 (list intPointsList)) intList))
                      ; If the entity is in the list, add the new point to the list
                      (progn
                        (setq newAssoc (cons ent1 (cons intPointsList (cdr (assoc ent1 intList)))))
                        (setq intList (subst newAssoc (assoc ent1 intList) intList))
                      )
                    )
                    ; Error handling if there's more than one intersection point
                    (progn
                      (if (= (rem intCount 1) 0)
                        (princ "\nMore than one intersection point found, skipping entity pair")
                        ; If intCount isn't an integer, a more serious error has occurred
                        (princ "\nReceived invalid coordinate data from vla-IntersectWith, skipping entity pair")
                      )
                    )
                  )
                )
                (DebugPrint "\nNo intersection points found")
              )
            )
          )
        )
      )
    
      ; Now we should have a list of all intersection points, sorted by entity.
      ; This data is stored in the association list named intList
      
      (DebugPrint "\nIntersection List: ")
      ; Loop through the association list
      (foreach ent1 intList
        (setq obj1 (vlax-ename->vla-object (car ent1)))
        (setq objName (vla-Get-ObjectName obj1))
        (DebugPrint (strcat "\n" (vl-princ-to-string (car ent1)) " has " (itoa (length (cdr ent1))) " intersection points"))
        
        ; For now, the routine will only trim a segment if there are exactly two intersection points for that entity
        (if (= 2 (length (cdr ent1)))
          (progn
            (setq startPt (trans (cadr ent1) 0 1))
            (setq endPt (trans (caddr ent1) 0 1))
            (command "._Break" (ssadd (car ent1)) startPt endPt)
          )
        )
      )
    ))
  )
  
  (princ)
)
