; Written by Alex McTeague
(defun c:objinfo (/ ent obj)
  (vl-load-com) ; Loads the extended AutoLISP functions related to ActiveX support
  
  ; Asks the user to select an object
  (setq ent (car (entsel)))
  (if (null ent) (progn (princ "\nNo object selected -- aborting.") (quit)))
  (setq obj (vlax-ename->vla-object ent))
  (princ "\n")
  
  ; Print the name of the object
  (princ (strcat "Object Name: " (vla-get-name obj) "\n"))
  
  ; Print the coordinates of the object
  (setq pos (vlax-get obj 'InsertionPoint))
  ;(setq stringpos (strcat "(" (vla-get-x pos) " " (vla-get-y pos) " " (vla-get-z pos) ")"))
  ;(princ (strcat "Coordinates: " stringpos "\n"))
  
  ; Print the normal attributes/properties of the object
  (princ (strcat "--Object Properties--"))
  (vlax-dump-object obj)
  (princ "\n")
  
  ; Print the object data tables
  (setq lst (ade_odgettables ent))
  (princ "--Object Data Tables--\n")
  (foreach tbl lst
      (princ (strcat ";   " tbl ":\n"))
      ; TODO: Loop through each element of each table.
      ; There doesn't seem to be a built-in function to list all elements of an Object Data table.
  )
  
  ; Print the Extended Data (XData)
  (princ "--Extended Data--\n")
  (if (setq xd (cdr (assoc -3 (entget ent '("*")))))
    (foreach a xd
      (foreach x a (princ (strcat ";   " x)))
    )
    (princ "\n;   Entity has no Xdata.")
  )
  
  (princ) ; Prevents double-printed output
)