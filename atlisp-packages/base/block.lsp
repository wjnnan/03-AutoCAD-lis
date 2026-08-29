

(defun block:get-effectivename (blk / tem blkname)
  "??????????????? MAC"
  (if (= 'ename (type blk))
      (progn
	(setq blkname (cdr (assoc 2 (entget blk))));;????????????
	(if (wcmatch blkname "`**");;???????????
	    (if (and
		 (setq tem
		       (cdadr
			(assoc -3
			       (entget
				(cdr
				 (assoc 330
					(entget
					 (tblobjname "block" blkname);;???????????????????
					 );;??????????????
					)
				 )
				'("AcDbBlockRepBTag")
				)
			       )
			)
		       )
		 (setq tem (handent (cdr (assoc 1005 tem))))
		 )
		(setq blkname (cdr (assoc 2 (entget tem))))
		)
	    )
	blkname
	)
      nil))

(defun block:get-attributes (blk / lst)
  "?????????,??????????????????งา???"
  (if (= 'ename (type blk))
      (if (safearray-value (setq lst (vlax-variant-value (vla-getattributes (vlax-ename->vla-object blk)))))
	  (mapcar '(lambda (x) (cons (vla-get-tagstring x) (vla-get-textstring x)))
		  (vlax-safearray->list lst)
		  )
	  )
      nil)
)

(defun block:set-attributes (blk lst / n atts)
  "??????????"
  (if (= 'ename (type blk))
      (if (safearray-value (setq atts (vlax-variant-value (vla-getattributes (vlax-ename->vla-object blk)))))
	  (progn (foreach n lst
			  (mapcar '(lambda (x)
				    (if (= (strcase (car n)) (strcase (vla-get-tagstring x)))
					(vla-put-textstring x (cdr n))
					)
				    )
				  (vlax-safearray->list atts)
				  )
			  )
		 (vla-update (vlax-ename->vla-object blk))
		 )
	  )
      nil)
  )

(defun block:get-dynamic-properties (blk / oblk props)
  "????????????????งา????????????????????????????????????"
  (if (= 'ename (type blk))
      (progn
	(setq oblk  (vlax-ename->vla-object blk))
	;;?????????????
	(setq props (vl-catch-all-apply 'vlax-invoke (list oblk 'getdynamicblockproperties)))
	(if (or (vl-catch-all-error-p props) (not props))
	    nil
	;;?????????
	(list 
	 (mapcar '(lambda (x) (vlax-get x 'propertyName)) props)
	 ;;???????????????
	 (mapcar '(lambda (x) (vlax-get x 'Value)) props)
	 ;;??????????????
	 (mapcar 'vla-get-readOnly props)
	 ;;?????????????
	 (mapcar 'vla-get-show props)
	 ;;?????????????????
	 (mapcar '(lambda (x) (vlax-get x 'allowedValues)) props)
	 ))
      nil)
  )
(defun block:get-dynamic-prop-cons-name-value (blk / props n lst)
  (setq props (block:get-dynamic-properties blk))
  (setq n 0)(setq lst nil)
  (repeat (length (car props))
	  (setq lst (append lst (list (cons (nth n (car props))
					    (nth n (cadr props))))))
	  (setq n (1+ n)))
  lst)
  
(defun block:set-dynprop (blk prp val)
  "?????????????"
  (setq prp (strcase prp))
  (setq _dynprops (vl-catch-all-apply 'vlax-invoke (list (vlax-ename->vla-object blk) 'getdynamicblockproperties)))
  (if (or (vl-catch-all-error-p _dynprops) (not _dynprops))
      nil
      (vl-some
   '(lambda (x)
     (if (= prp (strcase (vla-get-propertyname x)))
         (progn
           (vla-put-value
            x
            (vlax-make-variant
             val
             (vlax-variant-type (vla-get-value x))
             )
            )
           (cond (val)
                 (t)
		 )
           )
	 )
     )
       _dynprops)))

(defun block:insert()
  "demo create a block containing a circle"
  ;; This example creates a block containing a circle.
  ;; It then inserts the block.
  (setq acadObj (vlax-get-acad-object))
  (setq doc (vla-get-ActiveDocument acadObj))
  
  ;; Create the block
  (setq insertionPnt (vlax-3d-point 0 0 0))
  (setq blockObj (vla-Add (vla-get-Blocks doc) insertionPnt "CircleBlock"))
  
  ;; Add a circle to the block
  (setq center (vlax-3d-point 0 0 0)
        radius 1)
  (setq circleObj (vla-AddCircle blockObj center radius))
  
  ;; Insert the block
  (setq insertionPnt (vlax-3d-point 2 2 0))
  (setq modelSpace (vla-get-ModelSpace doc))
  (setq blockRefObj (vla-InsertBlock modelSpace insertionPnt "CircleBlock" 1 1 1 0))
  
  (vla-ZoomAll acadObj)
  )
)