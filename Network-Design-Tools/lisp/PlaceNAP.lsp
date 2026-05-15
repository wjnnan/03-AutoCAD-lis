; Written by Alex McTeague
(defun c:polestamp (/ ent obj)
  (vl-load-com) ; Loads the extended AutoLISP functions related to ActiveX support
  
  ; Asks the user to select an object
  (setq ent (car (entsel)))
  (if (null ent) (progn (princ "\nNo object selected -- aborting.") (quit)))
  (setq obj (vlax-ename->vla-object ent))
  (setq objpos (vlax-get obj 'InsertionPoint))
  (princ "\n")
  (princ objpos)
  
  ; Asks the user to select a position for the new stamp
  (setq stamppos (getpoint "\nSelect stamp position: "))
  (if (null stamppos) (progn (princ "\nNo position selected -- aborting.") (quit)))

  ; Get the Object Data tables (there should only be one)
  (setq lst (ade_odgettables ent))
  
  ; Store the Object Data fields that we need
  (setq owner (ade_odgetfield ent lst "owner" 0))
  (setq tag (ade_odgetfield ent lst "tag" 0))
  (setq attach_ht (ade_odgetfield ent lst "prop_1ht" 0))
  (setq mr_cat (ade_odgetfield ent lst "mr_categ" 0))
  
  ; Print the Object Data fields
  (princ (strcat "Owner: " owner "\n"))
  (princ (strcat "Pole Tag: " tag "\n"))
  (princ (strcat "Attachment Height: " attach_ht "\n"))
  (princ (strcat "MR Category: " mr_cat "\n"))
  
  ; Switch to the Street Name Layer
  (command "_LAYER"
    "SET" "ST-NAME"
    ""
  )
  
  ; Change the default layer color to ByLayer
  (command "_COLOR" "BYLAYER")
  
  ; Add an MText object with the fields
  (command "_MTEXT"
    stamppos ; Chosen position
    "Style" "Arial" ; Arial style
    "Height" "3" ; Text height
    "Justify" "MC" ; Middle-Center justified
    stamppos ; Second corner of new MText, same as the first (it will autosize to text anyway)
    owner ; Each string is entered on a separate line
    tag
    attach_ht
    mr_cat
    "" ; Empty string input to finalize MText
  )
  
  (princ) ; Prevents double-printed output
)