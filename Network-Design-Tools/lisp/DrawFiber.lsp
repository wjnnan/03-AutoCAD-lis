; Written by Alex McTeague
(defun c:DrawFiber (/ ent obj base-pt fiber-base-pt fiber-input buffer-num fiber-num layer fiber-pos start-pt end-pt pt1 pt2 pt3 pt4)
  ; Ask the user to select an object
  (setq ent (car (entsel "\nSelect starting object: ")))
  (if (null ent)
    (progn
      (princ "\nNo object selected -- aborting.")
      (quit)
    )
  )
  (setq obj (vlax-ename->vla-object ent))
  (setq base-pt (vlax-get obj 'InsertionPoint))
  
  ; Get the location of the fiber start point based on what kind of object was selected
  (setq obj-type (vl-catch-all-apply 'vla-get-EffectiveName (list obj)))
  (if (or (vl-catch-all-error-p obj-type) (null obj-type))
    (setq obj-type (vla-get-Name obj))
  )
  (cond
    ((= obj-type "NAP")
      (progn
        ; Ask the user to input a fiber number
        (setq fiber-input (getint "\nEnter fiber number (1-96): "))
        
        ; Give the user more attempts if they input an invalid number
        (while (or (< fiber-input 1) (> fiber-input 96))
          (setq fiber-input (getint "\nInvalid fiber number. Please enter a number between 1 and 96: "))
        )
        
        (setq start-pt (list (+ (car base-pt) 9.25) (- (cadr base-pt) 37.5)))
        (setq fiber-base-pt base-pt)
      )
    )
    ((= obj-type "Splitter")
      (progn
        ; Ask the user to input a fiber number
        (setq fiber-input (getint "\nEnter fiber number (0-96): "))
        
        ; Give the user more attempts if they input an invalid number
        (while (or (< fiber-input 0) (> fiber-input 96))
          (setq fiber-input (getint "\nInvalid fiber number. Please enter a number between 0 and 96: "))
        )
        
        (setq start-pt (list (- (car base-pt) 1.75) (cadr base-pt)))
        
        (if (not (= fiber-input 0))
          (progn
            ; We need the location of the sheath to draw on, ask the user for it
            (setq ent2 (car (entsel "\nSplitter selected. Select containing Splice Case: ")))
            (if (null ent2)
              (progn
                (princ "\nNo object selected -- aborting.")
                (quit)
              )
            )
            (setq obj2 (vlax-ename->vla-object ent2))
            (setq base-pt2 (vlax-get obj2 'InsertionPoint))
            (setq obj-type2 (vl-catch-all-apply 'vla-get-EffectiveName (list obj2)))
          (if (or (vl-catch-all-error-p obj-type2) (null obj-type2))
            (setq obj-type2 (vla-get-Name obj2))
          )
            (cond
              ((= obj-type2 "Splice Case")
                (setq fiber-base-pt base-pt2)
              )
              ((= obj-type2 "SHEATH")
                (setq fiber-base-pt base-pt2)
              )
              (t
                (progn
                  (princ "\nError: Splice Case requested, incorrect object type selected.")
                  (quit)
                )
              )
            )
          )
        )
      )
    )
    ((= obj-type "Splice Tray")
      (progn
        ; Splice trays have many upstream points, ask the user to select which one to use
        (setq sel-pt (getpoint "\nSelect which splice tray port to use: "))
        (if (null sel-pt) (progn (princ "\nNo point selected -- aborting.") (quit)))
        
        ; Ask the user to input a fiber number
        (setq fiber-input (getint "\nEnter fiber number (1-96): "))
        
        ; Give the user more attempts if they input an invalid number
        (while (or (< fiber-input 1) (> fiber-input 96))
          (setq fiber-input (getint "\nInvalid fiber number. Please enter a number between 1 and 96: "))
        )
        
        ; Round the selected point to the nearest upstream point on the tray
        (setq start-pt (list (- (car base-pt) 0.75) (cadr sel-pt)))
        (progn
          ; We need the location of the sheath to draw on, ask the user for it
          (setq ent2 (car (entsel "\nSplice Tray selected. Select containing Splice Case: ")))
          (if (null ent2)
            (progn
              (princ "\nNo object selected -- aborting.")
              (quit)
            )
          )
          (setq obj2 (vlax-ename->vla-object ent2))
          (setq base-pt2 (vlax-get obj2 'InsertionPoint))
          (setq obj-type2 (vl-catch-all-apply 'vla-get-EffectiveName (list obj2)))
          (if (or (vl-catch-all-error-p obj-type2) (null obj-type2))
            (setq obj-type2 (vla-get-Name obj2))
          )
          (cond
            ((= obj-type2 "Splice Case")
              (setq fiber-base-pt base-pt2)
            )
            ((= obj-type2 "SHEATH")
              (setq fiber-base-pt base-pt2)
            )
            (t
              (progn
                (princ "\nError: Splice Case requested, incorrect object type selected.")
                (quit)
              )
            )
          )
        )
      )
    )
    (t
      (progn
        (princ "\nError: this function only supports NAPs, Splitters, and Splice Trays. Re-run to try again.")
        (quit)
      )
    )
  )
  
  ; Ask the user to select an end point
  (setq end-pt (getpoint "\nSelect end point: "))
  (if (null end-pt) (progn (princ "\nNo point selected -- aborting.") (quit)))
  
  (cond
    ((= fiber-input 0)
      (progn
        (command "_LAYER"
          "SET" "0"
          ""
        )
        (setq fiber-pos (cadr end-pt))
      )
    )
    (t
      (progn    
        ; Calculate the associated buffer number and within-buffer fiber number
        (setq buffer-num (+ 1 (fix (/ fiber-input 12))))
        (setq fiber-num (rem fiber-input 12))
        (if (= fiber-num 0) (setq fiber-num 12 buffer-num (- buffer-num 1)))
  
        ; Switch to the layer matching the buffer/fiber selection
        (setq layer (GetFiberLayer fiber-input buffer-num fiber-num))
        (command "_LAYER"
          "SET" layer
          ""
        )
  
        ; Get the vertical position of the longest segment of the fiber
        (setq fiber-pos (- (cadr fiber-base-pt) (+ (* 1.5 buffer-num) (* 0.5 fiber-input))))
      )
    )
  )
  
  ; Calculate the positions of the remaining points (in the middle of the line)
  (setq pt1 (list (- (car start-pt) 1.5) (cadr start-pt)))
  (setq pt2 (list (car pt1) fiber-pos))
  (setq pt3 (list (+ (car end-pt) 2) fiber-pos))
  (setq pt4 (list (car pt3) (cadr end-pt)))
  
  ; Turn off Object Snapping, which messes with object placement
  (setq prevOSMode (getvar "osmode"))
  (setvar 'osmode 0)
  
  ; Draw the polyline
  (command "_COLOR" "BYLAYER")
  (command "._pline" start-pt pt1 pt2 pt3 pt4 end-pt "")

  ; Restore Object Snapping to its previous settings
  (setvar 'osmode prevOSMode)
  
  (princ)
)

(defun GetFiberLayer (fiber-input buffer-num fiber-num / buffer-color fiber-color layer-name)
  ; Find the buffer and fiber colors
  (cond
    ((= buffer-num 1) (setq buffer-color "BLUE"))
    ((= buffer-num 2) (setq buffer-color "ORANGE"))
    ((= buffer-num 3) (setq buffer-color "GREEN"))
    ((= buffer-num 4) (setq buffer-color "BROWN"))
    ((= buffer-num 5) (setq buffer-color "SLATE"))
    ((= buffer-num 6) (setq buffer-color "WHITE"))
    ((= buffer-num 7) (setq buffer-color "RED"))
    ((= buffer-num 8) (setq buffer-color "BLACK"))
  )
  (cond
    ((= fiber-num 1) (setq fiber-color "BLUE"))
    ((= fiber-num 2) (setq fiber-color "ORANGE"))
    ((= fiber-num 3) (setq fiber-color "GREEN"))
    ((= fiber-num 4) (setq fiber-color "BROWN"))
    ((= fiber-num 5) (setq fiber-color "SLATE"))
    ((= fiber-num 6) (setq fiber-color "WHITE"))
    ((= fiber-num 7) (setq fiber-color "RED"))
    ((= fiber-num 8) (setq fiber-color "BLACK"))
    ((= fiber-num 9) (setq fiber-color "YELLOW"))
    ((= fiber-num 10) (setq fiber-color "VIOLET"))
    ((= fiber-num 11) (setq fiber-color "ROSE"))
    ((= fiber-num 12) (setq fiber-color "AQUA"))
  )
  
  ; 检查 buffer-num 和 fiber-num 是否在有效范围内
  (if (or (null buffer-color) (null fiber-color))
    (progn
      (alert (strcat "Error: Invalid buffer/fiber number. Buffer: "
                     (itoa buffer-num) ", Fiber: " (itoa fiber-num)))
      (quit)
    )
  )

  ; Format the results to get the layer name
  (setq layer-name (strcat "S" (itoa fiber-input) "-" buffer-color "-" fiber-color))
  
  ; Throw an error if the layer can't be found
  (if (not (tblsearch "LAYER" layer-name))
    (progn
      (alert (strcat "Error: Layer '" layer-name "' does not exist."))
      (quit)
    )
  )
  
  ; Return the layer name
  layer-name
)