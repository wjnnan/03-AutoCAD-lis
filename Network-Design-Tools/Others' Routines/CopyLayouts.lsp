(defun c:CopyLayouts (/ layoutName newLayoutName layoutList sortedLayoutList)
  (setq layoutName "3") ; Name of the layout to copy
  (setq startNum 4) ; Starting number for new layouts
  (setq endNum 29) ; Ending number for new layouts
  (setq layoutList nil) ; Initialize an empty list for layout names

  ; Create a list of new layout names
  (repeat (- endNum startNum -1)
    (setq newLayoutName (itoa startNum))
    (setq layoutList (append layoutList (list newLayoutName)))
    (setq startNum (1+ startNum))
  )

  ; Custom sorting function to sort layout names numerically
  (defun sort-numeric (a b)
    (< (atoi a) (atoi b))
  )

  ; Sort the layout list using the custom sorting function
  (setq sortedLayoutList (vl-sort layoutList 'sort-numeric))

  ; Copy layouts in the order of the sorted list
  (foreach newLayoutName sortedLayoutList
    (command "._layout" "Copy" layoutName newLayoutName)
  )
  (princ)
)
