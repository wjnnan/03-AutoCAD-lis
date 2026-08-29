(@::define-config 'ole:gap 300  "?????????????")
(@::define-config 'ole:scale 1.0  "????????????????")
(@::define-config 'ole:width 3000.0 "??????")
(@::define-config 'ole:img-types "jpg,png"  "??????????,???????")
(@::define-config 'ole:title-size 50   "??????????")
(@::define-config 'ole:title-style "????" "?????????????????????????")
(@:add-menu "ole???" "ole????" "(ole:setup)" )
(@:add-menu "ole???" "????????" "(ole:multi-insert)")
(@:add-menu "ole???" "???????" "(ole:insert-img)")
(@:add-menu "ole???" "???????" "(ole:install)" )
(@:add-menu "ole???" "???????" "(ole:multi-rasteriamge)")

(defun ole:setup (/ res)
   (setq @::tmp-search-str "ole:")
   (@::edit-config-dialog))
(defun ole:install ()
  (@::cmd "shell"
	  (strcat "powershell "
		  (@::package-path "ole")"install.ps1")))
(defun ole:multi-insert ()
  (@::prompt '("????????е???????jpg/png,???????dwg??"
	       ))
  (setq i 0)
  (if (setq folder (system:get-folder "???????????????????????????"))
      (progn
	(if (null (setq pt-ins (getpoint "?????:")))
	  (progn (princ "
δ???????? -- ???.") (quit)))
	(if (setq imglst
		  (vl-sort
		   (vl-remove ""
			      (apply 'append
				     (mapcar '(lambda(img-type)
					       (vl-directory-files folder
						(strcat "*."
						 (vl-string-trim  "*." img-type))
						1))
					     (string:to-list (@::get-config 'ole:img-types)",")
					     )))
		   '<))
	    (progn
	      (if (findfile (strcat @::*tmp-path*
				    "oleimg.lst"))
		  (vl-file-delete (strcat @::*tmp-path*
					  "oleimg.lst")))
	      (setq fp (open (strcat @::*tmp-path*
				     "oleimg.lst")

			     "w"))
	      (foreach img imglst
		       (write-line
			(strcat folder"\\" img)
			fp))
	      (close fp)
	      (or @::enable-start
		  (@::check-pgp)
		  (@::patch-pgp) 
		  )
	      (@::cmd "shell-bg"
		      (strcat "atlisp-ole "
			      (strcat @::*tmp-path*
				     "oleimg.lst")))
	      )
	    (@::prompt"??з?????????")
	    ))
      ))
(defun ole:insert-img (/ imgfile )
  (@::prompt '("????????jpg/png,??OLE??????????dwg??"
	       ))
  (if (setq imgfile (getfiled "?????????????" "" "png" 8))
      (progn
	(if (null (setq pt-ins (getpoint "?????:")))
	  (progn (princ "
δ???????? -- ???.") (quit)))
	(or @::enable-start
	    (@::check-pgp)
	    (@::patch-pgp) 
	    )
	(@::cmd "shell-bg"
		(strcat "atlisp-ole "imgfile)
		)
	))
      )
(defun ole:calc-ptins()
  (if (null pt-ins)(setq pt-ins '(0 0 0)))
  (setq box (entity:getbox (entlast) 0))
  (setq pt-ins (polar pt-ins
		      0
		      ;;(+ 100 (- (caadr box)(caar box)))
		      (+ (@::get-config 'ole:gap)
			 (@::get-config 'ole:width)
			 )))
  )
(defun ole:scale-img(/ ole)
  (setq ole  (e2o(entlast)))
  (if (null ole) (progn (princ "\nOLE对象未创建 -- 退出.") (quit)))
  (if (not
       (equal (vla-get-width ole)
	      (@::get-config 'ole:width)
	      (* 0.01 (@::get-config 'ole:width))
	      ))
      (progn
	(vla-put-width ole (@::get-config 'ole:width))
	))
  (vla-put-InsertionPoint ole (point:to-ax pt-ins))
  (vla-update  ole)
  )

(defun ole:make-title (str)
  (entity:make-text
   str
   (polar pt-ins (* 1.5 pi)
	  (* 2.0 (@::get-config 'ole:title-size)))
   (@::get-config 'ole:title-size)
   0 0.9 0 "LB")
  (if (member (@::get-config 'ole:title-style) (tbl:list"textstyle"))
      (entity:putdxf (entlast)
		     7
		     (@::get-config 'ole:title-style)))
  )
(defun ole:osmode-off ()
  (if (< (getvar "osmode") 16384)
      (setvar "osmode" (+ (getvar "osmode") 16384))))
(defun ole:osmode-on ()
  (if (>= (getvar "osmode") 16384)
      (setvar "osmode" (- (getvar "osmode") 16384))))

(defun ole:multi-rasteriamge ()
  (@::prompt '("????????е?????????jpg/png,???????dwg??"
	       ))
  (setq i 0)
  (if (setq folder (system:get-folder "???????????????????????????"))
      (progn
	(if (null (setq pt-ins (getpoint "?????:")))
	  (progn (princ "
δ???????? -- ???.") (quit)))
	(if (setq imglst
		  (vl-sort
		   (vl-remove ""
			      (apply 'append
				     (mapcar '(lambda(img-type)
					       (vl-directory-files folder
						(strcat "*."
						 (vl-string-trim  "*." img-type))
						1))
					     (string:to-list (@::get-config 'ole:img-types)",")
					     )))
		   '<))
	    (mapcar '(lambda(img / obj)
		      (print img)
		      (setq obj
		       (vla-addRaster
			*MS*
			(@::path-os(strcat folder "/"  img))
			(point:to-ax pt-ins)
			1
			0))
		      (vla-put-scaleFactor obj (@::get-config 'ole:width))
		      (ole:make-title (vl-filename-base img))
		      (setq pt-ins
		       (polar pt-ins
			0
			(+ (@::get-config 'ole:gap)
			   (@::get-config 'ole:width))
			   )))
		    imglst)
	    (@::prompt"??з?????????")
	    ))
      ))
