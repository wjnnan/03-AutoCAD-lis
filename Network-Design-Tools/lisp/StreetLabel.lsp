; Written by Alex McTeague
(defun c:StreetLabel (/ line pt)
  ; Load the extended AutoLISP functions related to ActiveX support
  (vl-load-com)
  
  ; Helper function: get text from clipboard
  (defun GetClipBoardText( / htmlfile result )
    (setq result
      (vlax-invoke
        (vlax-get
          (vlax-get
            (setq htmlfile (vlax-create-object "htmlfile"))
            'ParentWindow
          )
          'ClipBoardData
        )
        'GetData
        "Text"
      )
    )
    (vlax-release-object htmlfile)
    result
  )
  
  
  ; Config
  (setq textHeight 5.267384)
  (setq layer "ST-NAME")
  (setq color "ByLayer")
  (setq streetName (GetClipBoardText))
  
  ; Ask the user to select the centerline, and the destination for the callout
  (setq line (car (entsel "\nSelect street centerline: ")))
  (if (null line) (progn (princ "\nNo line selected -- aborting.") (quit)))
  (setq pt (getpoint "\nSelect location for street name callout: "))
  (if (null pt) (progn (princ "\nNo point selected -- aborting.") (quit)))
  
  ; Do a little bit of calculus
  (setq linePt (vlax-curve-getclosestpointto line pt))
  (setq theta (angle
    '(0 0 0)
    (vlax-curve-getfirstderiv line
      (vlax-curve-getparamatpoint line linePt)
    )
  ))
  (setq theta (/ (* 180.0 theta) pi))
  
  ; Correct the angle so text is never flipped upside down
  (if (and (> theta 90) (< theta 270))
    (setq theta (+ theta 180))
  )
  
  ; Switch to the Street Name Layer
  (command "_LAYER"
    "SET" "ST-NAME"
    ""
  )

  ; Change the default layer color to ByLayer
  (command "_COLOR" "BYLAYER")
  
  ; Create a text callout with the street name
  (command "_.TEXT"
    "J" "M"
    pt
    textHeight
    theta
    streetName
  )

  (princ)
)