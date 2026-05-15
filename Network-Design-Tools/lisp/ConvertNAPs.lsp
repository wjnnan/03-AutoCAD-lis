; Written by Alex McTeague
(defun c:ConvertNAPs (/)
  (setq debug nil) ; Set to t or nil to enable/disable debug messages
  
  ; (defun GetVisibilityState ( blk / vla_obj props prop prop_name )
  ;   ; Converts entity name to VLA object
  ;   (setq vla_obj (vlax-ename->vla-object blk))

  ;   ; Gets all dynamic block properties as a safe array
  ;   (setq props (vla-getdynamicblockproperties vla_obj))

  ;   ; Converts safe array to a LISP list
  ;   (setq props (vlax-safearray->list (vlax-variant-value props)))

  ;   ; Iterate through properties to find the visibility one
  ;   (foreach prop props
  ;     (setq prop_name (vlax-get-property prop "PropertyName"))
  ;     (if (wcmatch prop_name "NAP State")
  ;       (progn
  ;         ; Return the current value (the state name)
  ;         (setq prop_name (vlax-get-property prop "Value"))
  ;         (exit) ; Exit the loop once found
  ;       )
  ;     )
  ;   )
  ;   ; Return the visibility state name
  ;   prop_name
  ; )
  
  ; Select all NAP blocks in this tab
  (if (setq nap-set (ssget "_X" '((0 . "INSERT") (2 . "NAP"))))
    (progn
      ; Loop through all selected objects
      (setq i 0)
      (setq edit-lists '())
      (repeat (sslength nap-set)
        (setq obj (vlax-ename->vla-object (ssname nap-set i)))
        (setq obj-type (vl-catch-all-apply 'vla-get-EffectiveName (list obj)))
        (if (or (vl-catch-all-error-p obj-type) (null obj-type))
          (setq obj-type (vla-get-Name obj)))
        (if debug (princ (strcat "\n=== " obj-type " ===\n")))
        
        ; Skip any objects that aren't "NAP" blocks
        (if (= obj-type "NAP")
          (progn
            ; Loop through all attributes of this NAP
            (setq simple-atts (vlax-invoke obj 'GetAttributes))
            (setq atts (mapcar '(lambda (att) (cons (vla-get-tagstring att) (vla-get-textstring att))) simple-atts))
            (foreach att simple-atts
              (progn
                (setq att-id (vla-get-tagstring att))
                (setq att-val (vla-get-textstring att))
                (if debug (princ (strcat att-id ": " att-val "\n")))
                
                ; Check for attributes with old names
                (cond
                  ((= att-id "96CT_NAP_NAME_2")
                    (if (/= att-val "NAP NAME")
                      ; Save a reference to the object, which attribute needs updating, and the value
                      (setq edit-lists (cons (list obj "NAP_NAME_2" att-val) edit-lists))
                    )
                  )
                  ((= att-id "96CT_NAP_ADDR_2")
                    (if (/= att-val "NAP ADDRESS")
                      (setq edit-lists (cons (list obj "NAP_ADDR_2" att-val) edit-lists))
                    )
                  )
                  ((or (= att-id "ADDR_1_OF_2") (= att-id "ADDR_1_OF_4") (= att-id "96CT_ADDR_1_OF_2") (= att-id "96CT_ADDR_1_OF_4"))
                    (if (/= att-val "OPEN")
                      (setq edit-lists (cons (list obj "ADDR_1" att-val) edit-lists))
                    )
                  )
                  ((or (= att-id "ADDR_2_OF_2") (= att-id "ADDR_2_OF_4") (= att-id "96CT_ADDR_2_OF_2") (= att-id "96CT_ADDR_2_OF_4"))
                    (if (/= att-val "OPEN")
                      (setq edit-lists (cons (list obj "ADDR_2" att-val) edit-lists))
                    )
                  )
                  ((or (= att-id "ADDR_3_OF_4") (= att-id "96CT_ADDR_3_OF_4"))
                    (if (/= att-val "OPEN")
                      (setq edit-lists (cons (list obj "ADDR_3" att-val) edit-lists))
                    )
                  )
                  ((or (= att-id "ADDR_4_OF_4") (= att-id "96CT_ADDR_4_OF_4"))
                    (if (/= att-val "OPEN")
                      (setq edit-lists (cons (list obj "ADDR_4" att-val) edit-lists))
                    )
                  )
                )
              )
            )
          )
        )
        (setq i (1+ i)) ; Go to the next object in the selection
      )
      
      ; After building the list of edits we need to make, we sync all the NAP blocks, so they have the correct attributes to fill
      (command "ATTSYNC" "Name" "NAP")
      
      ; Loop through the list of edits
      (foreach edit-list edit-lists
        (progn
          (setq obj (car edit-list))
          (setq att-name (cadr edit-list))
          (setq att-val (caddr edit-list))
          
          ; Visibility State can't be fixed (easily, anyway), because the state isn't copied when pasted from another document
          ; But if the tech somehow becomes practical, this may be useful: 
          ; (setq obj-state (cadddr edit-list))
          ; Set the visibility state to what it was before
          ; (and
          ;   (setq e (vlax-vla-object->ename obj))
	        ;   ;(wcmatch (getpropertyvalue e "BlockTableRecord/Name") "NAP")
	        ;   (vl-catch-all-apply 'setpropertyvalue (list e "AcDbDynBlockPropertyNAP State" obj-state))
          ; )
          
          ; Loop through each attribute in the given object to find the one we're looking for
          (foreach att (vlax-invoke obj 'GetAttributes)
            ; Once we have a match, replace its value with the one we saved
            (if (= (vla-get-tagstring att) att-name)
              (vla-put-textstring att att-val)
            )
          )
        )
      )
      (princ (strcat "Updated " (itoa (length edit-lists)) " attributes"))
    )
    (princ "\nEmpty selection; could not find any blocks named 'NAP'") ; Throw an error if the initial selection is empty
  )
  (princ)
)