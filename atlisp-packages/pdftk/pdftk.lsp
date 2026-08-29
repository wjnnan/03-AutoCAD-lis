;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This file was created by @lisp DEV-tools
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; define a first config item  'pdftk:first for package pdftk 's configitem first 
(@:define-config 'pdftk:stamp "D:\\Design\\standard\\stamp.pdf" "???????????pdf???")
(@:define-config 'pdftk:background "D:\\Design\\standard\\background.pdf" "???????????pdf?????????????PDF???????????????")
(@:define-config 'pdftk:pre-folder "D:\\" "???pdf???·??????????β????????λ?á?")
(if (null (findfile (@:get-config 'pdftk:stamp)))
    (@:mkdir (@:path (vl-filename-directory(@:get-config 'pdftk:stamp)))))
;; (@:get-config 'pdftk:first) 
;; (@:set-config 'pdftk:first  "New Value")
;; Add menu in @lisp panel
(@::add-menus '("PDF???"
	       ("PDF????" "(pdftk:setup)" )
	       ("???PDF" "(pdftk:menu-merge)" )
	       ("???PDF" "(pdftk:menu-burst)" )
	       ("PDF?????" "(pdftk:menu-stamp)" )
	       ("?????????" "(pdftk:menu-batch-stamp)" )
	       ("PDF????" "(pdftk:menu-background)")
	       ("????????" "(pdftk:menu-batch-background)")
	       ("????PDF" "(pdftk:menu-decrypt)" )
	       ("????PDF" "(pdftk:menu-encrypt)" )
	       ))
(or @:enable-start
    (@:check-pgp)
    (@:patch-pgp) 
    )
(defun pdftk:setup (/ res)
  "pdf tools"
  (setq res 
	(ui:input "???????"
		  (mapcar '(lambda (x) (list (strcase (vl-symbol-name (car x)) T)(cadr x)(cddr x)))
			  (vl-remove-if '(lambda (x) (not (wcmatch (vl-symbol-name (car x)) "PDFTK:*")))
					(if @:*config.db*
					    @:*config.db* (@:load-config))))))
  (foreach res% res
   	   (@:set-config (read (car res%)) (cdr res%)))
  )
(defun pdftk:download (/ app)
  (setq app "bin\\pdftk.exe")
  (if (null (findfile "bin\\iconv.exe"))
      (@:down-and-unzip "archives/iconv.zip" "bin"))
  (if (null (findfile app))
      ;; ?????????
      (@:down-and-unzip "archives/pdftk.zip" "bin"))
  (if (null (findfile "packages\\pdftk\\background.pdf"))
      (@:down-pkg-file (@:uri)"pdftk/background.pdf" "stable"))
  (if (null (findfile "packages\\pdftk\\stamp.pdf"))
      (@:down-pkg-file (@:uri)"pdftk/stamp.pdf" "stable"))
  )

(defun pdftk:menu-merge (/ folder)
  (@::prompt "???????????????????pdf,???????????????????")
  (if (setq folder (system:get-folder "???????????PDF?????"))
      (progn
	(@:set-config 'pdftk:pre-folder (system:dir folder))
	(pdftk:merge folder)
	(system:explorer (strcat folder "\\..\\" )))))
(defun pdftk:merge (folder / app files filetmp filename-bk fp-bookmark file-bk file-bk-utf8 cnt)
  "??????folder ???????? pdf ???????????????????????????? `?????-merge-all.pdf' "
  ""
  "(pdftk:merge \"D:\\Output\\A???\")"
  (setq app "bin\\pdftk.exe")
  (pdftk:download)
  (if (and (findfile app)
	   folder
	   (vl-directory-files folder "*.pdf" 1))
      (progn
	;;(@:patch-pgp-shell)
	(setq files "*.pdf")
	(setq filetmp "merge-tmp.pdf")
	(setq filename-bk "merge-all.pdf")
	(setvar "cmdecho" 0)
	;;????????????
	(setq fp-bookmark (open (strcat folder "\\bk.txt")"w"))
	(if (null fp-bookmark) (progn (princ "\n无法创建书签文件 -- 退出.") (quit)))
	(setq i 0)
	(foreach bk% (vl-directory-files folder "*.pdf" 1)
		 (write-line "BookmarkBegin" fp-bookmark)
		 (write-line (strcat "BookmarkTitle: "
				     (vl-filename-base bk%))
			     fp-bookmark)
		 (write-line "BookmarkLevel: 1" fp-bookmark)
		 (write-line (strcat "BookmarkPageNumber: "
				     (itoa (setq i (1+ i))))
			     fp-bookmark))
	(close fp-bookmark)
	;; ???
	(setq file-bk (strcat folder "\\bk.txt"))
	(setq file-bk-utf8 (strcat folder "\\bk-utf8.txt"))
	(command "shell-bg"
		 (strcat  @:*prefix* "bin\\iconv.exe -f gb2312 -t utf-8 \""
			  file-bk "\" >> \"" file-bk-utf8  "\""
			  ))
	;;(sleep 3)
	(print folder)

	(command "start-bg"
		 (strcat " /D \"" folder "\""
			 " /MIN /B  "
			 @:*prefix* app  " "
			 files " "
			 "output " filetmp
			 ))
	(setq cnt 0)
	(while (and (null (findfile (strcat folder "\\" filetmp)))
		    (< cnt 60))
	  (sleep 1)
	  (setq cnt (1+ cnt)))
	(if (findfile (strcat folder "\\" filetmp))
	    (progn
	      (command "start-bg"
		       (strcat  " /D \"" folder "\""
				" /MIN /B  "
				@:*prefix* app  " "
				filetmp " "
				"update_info_utf8 "
				" bk-utf8.txt "
				" output \"..\\"
				(vl-filename-base folder) "-" filename-bk "\" "
				))
	      (setq i 0)
	      (setq cnt 0)
	      (while (and (null (findfile (strcat folder "\\..\\"
						     (vl-filename-base folder)
						     "-" filename-bk)))
			 (< cnt 60))
		(sleep 1)
		(setq cnt (1+ cnt))))
	    )
	
	(if (findfile file-bk)(vl-file-delete file-bk))
	(if (findfile file-bk-utf8)(vl-file-delete file-bk-utf8))
	(if (findfile (strcat folder "\\" filetmp))
	    (vl-file-delete (strcat folder "\\" filetmp)))
	
	(setvar "cmdecho" 1)
	(if (findfile  (strcat folder "\\..\\"))
	    (system:explorer (strcat folder "\\..\\" )))
	)
    (cond
     ((not (findfile app))
      (princ "???PDF????????У???з??? pdftk.exe")
      )
     (t
      (princ "???PDF????????У?")
     )
    )
  (princ)
  )

(defun pdftk:menu-burst (/ pdf-file)
  (@::prompt "??????? pdf ????????????????????")
  (if (setq pdf-file  (getfiled "??????????PDF???" (@:get-config 'pdftk:pre-folder) "pdf" 8))
      (progn
	(@:set-config 'pdftk:pre-folder (system:dir (vl-filename-directory pdf-file )))
	(pdftk:burst pdf-file)
	(system:explorer (vl-filename-directory pdf-file)))))
(defun pdftk:burst (pdf-filename / app )
  "??? pdf ??????????"
  (setq app "bin\\pdftk.exe")
  (pdftk:download)
  (if (and (findfile app)
	   (= 'str (type-of pdf-filename))
	   (findfile pdf-filename))
      (progn
	(setvar "cmdecho" 0)
	(command
	 "start-bg"
	 (strcat " /D \"" (vl-filename-directory pdf-filename) "\""
		 " /MIN /B  "
		 @:*prefix* app
		 " \"" pdf-filename "\" "
		 "burst " 
		 ))
	(setvar "cmdecho" 1)
	))
  (princ)
  )

(defun pdftk:menu-encrypt (/ filename pw permission permissions)
  (@::prompt "?????? pdf ???,?????????????????????????????????????")
  (setq permission '(("Printing"  nil "?????????")
		     ("DegradedPrinting" nil "?????????")
		     ("ModifyContents" nil "??????,?????? Assembly.")
		     ("Assembly" nil "???")
		     ("CopyContents" nil "??????????????? ScreenReaders")
		     ("ScreenReaders" nil "????????")
		     ("ModifyAnnotations" nil "???????????? FillIn")
		     ("FillIn" nil "?????")
		     ("AllFeatures" nil "????????.")))

  (if (setq filename (getfiled "???????????PDF???" (@:get-config 'pdftk:pre-folder) "pdf" 8))
      (progn
	(@:set-config 'pdftk:pre-folder (system:dir (vl-filename-directory filename )))
	(setq pw (ui:input "?????????????????PDF:"
			   '(("??????????:" "" "????????????????" T)
			     ("??????????2:" "" "????????????" T)
			     ("???????:"  "" "???????????????" T)
			     ("???????2:" "" "????????????" T))))
	(setq permissions
	      (mapcar '(lambda (x) (car (string:to-list x ": ")))
		      (ui:select-multi "???????????:" (mapcar '(lambda (x) (strcat (car x) ": " (last x))) permission))))
	(if (null permissions)
	    (setq permissions '("")))
	
	(while (and pw
		    (or 
		     (not (= (cdr (assoc "??????????:" pw))(cdr (assoc "??????????2:" pw))))
		     (not (= (cdr (assoc "???????:" pw))(cdr (assoc "???????2:" pw))))))
	  (alert "????????????????????????????????????????????????????????")
	  (setq pw (ui:input "?????????????????PDF:"
			     '(("??????????:" "" "????????????????" T)
			       ("??????????2:" "" "????????????" T)
			       ("???????:"  "" "???????????????" T)
			       ("???????2:" "" "????????????" T))))
	  )
	(if pw
	    (progn
	      (pdftk:encrypt filename (cdr (assoc "??????????:" pw)) (cdr (assoc "???????:" pw)) permissions)
	      (system:explorer (vl-filename-directory filename)))
	  ))))

(defun pdftk:encrypt (filename owner-pw user-pw permissions / app)
  "? pdf ??????????????????"
  ;; ????????·??
  (setq app "bin\\pdftk.exe")
  (pdftk:download)
  ;;(setq files (vl-directory-files (system:get-folder) "*.pdf"))
  (if (= 'str (type permissions))
      (setq permissions (list permissions)))
  (if (findfile app)
      (progn
	(setvar "cmdecho" 0)
	(command "start-bg"
		 (strcat " /D \"" (vl-filename-directory filename) "\""
			 " /MIN /B  "
			 @:*prefix* app  " \""
			 filename "\" "
			 "output \""
			 (strcat (vl-filename-directory filename) "\\"
				 (vl-filename-base filename) "-????.pdf\" ")
			 "owner_pw \"" owner-pw  "\" "
			 "user_pw \"" user-pw "\" "
			 "allow " (string:from-lst permissions " ") " "
			 ))
	(setvar "cmdecho" 1)
	))
  (princ)
  )

(defun pdftk:menu-decrypt (/ pdf-file)
  (@::prompt "?????? pdf ???,????????????????????????????")
  (if (setq pdf-file (getfiled "???????????PDF???" (@:get-config 'pdftk:pre-folder) "pdf" 8))
      (progn
	(@:set-config 'pdftk:pre-folder (system:dir (vl-filename-directory pdf-file )))
	(pdftk:decrypt
	 pdf-file
	 (cdr (assoc "??????????:"
		     (ui:input "?????????????????PDF:"
			       '(("??????????:" "" "????????????????" T))))))
	(system:explorer (vl-filename-directory pdf-file))
	)))

(defun pdftk:decrypt (filename owner-pw / app )
  ;; ????????·??
  (setq app "bin\\pdftk.exe")
  (pdftk:download)
  (if (and (findfile app)
	   owner-pw)
      (progn
	(setvar "cmdecho" 0)
	(command "start-bg"
		 (strcat " /D \"" (vl-filename-directory filename) "\""
			 " /MIN /B  "
			 @:*prefix* app  " \""
			 filename "\" "
			 "input_pw \"" owner-pw"\" "
			 "output \""
			 (strcat (vl-filename-directory filename) "\\"
				 (vl-filename-base filename) "-????.pdf\" ")
			 ))
	(setvar "cmdecho" 1)
	))
  (princ)
  )
(defun pdftk:menu-stamp (/ filename)
  (@::prompt "???????????????????????????????????pdf?????н??????á?")
  (if (setq filename (getfiled "????????????PDF???" (@:get-config 'pdftk:pre-folder) "pdf" 8))
      (progn
	(@:set-config  'pdftk:pre-folder(system:dir (vl-filename-directory filename)))
	(pdftk:stamp filename)
	(system:explorer (vl-filename-directory filename)))))
(defun pdftk:menu-batch-stamp (/ filename)
  (@::prompt "??????????У?????????????pdf????????????????????pdf?????н??????á?")
  (if (setq pathname (system:get-folder "????????????PDF?????"))
      (progn
	(@:set-config  'pdftk:pre-folder (system:dir pathname))
	(setq pdfs (vl-directory-files pathname "*.pdf"))
	(foreach
	 pdf% pdfs
	 (if (null (wcmatch (strcase pdf% t) "*-background.pdf"))
	     (pdftk:stamp (strcat (system:dir pathname) pdf%))))
	(system:explorer (system:dir pathname))
	)))
(defun pdftk:stamp (filename / app)
  ;; ????????·??
  (setq app "bin\\pdftk.exe")
  (pdftk:download)
  (if (null (findfile  (@:get-config 'pdftk:stamp)))
      (progn
	(vl-file-copy (strcat (@:package-path "pdftk") "stamp.pdf")
		      (@:get-config 'pdftk:stamp))
	(sleep 2)))
  ;;(setq files (vl-directory-files (system:get-folder) "*.pdf"))
  (if (and (findfile app)
	   filename)
      (progn
	;;(setq folder (system:get-folder "???????????PDF?????"))
	;;(setq files (strcat folder  "\\*.pdf"))
	(if (/= "" (@:get-config 'pdftk:stamp))
	    (progn
	      (setvar "cmdecho" 0)
	      (command "start-bg"
		       (strcat " /D \"" (vl-filename-directory filename) "\""
			       " /MIN /B  "
			       @:*prefix* app  " \""
			       filename "\" "
			       "stamp \"" (@:get-config 'pdftk:stamp)"\" "
			       "output \""
			       (strcat (vl-filename-directory filename) "\\"
				       (vl-filename-base filename) "-stamp.pdf\" ")
			       ))
	      (setvar "cmdecho" 1)
	      ))
	))
  (princ)
  )
(defun pdftk:menu-background (/ filename)
  (@::prompt "?????????????????????????????????pdf?????н??????á?????? pdf ???????????????????Ч????")
  (if (setq filename  (getfiled "????????????PDF???" (@:get-config 'pdftk:pre-folder) "pdf" 8))
      (progn
	(@:set-config  'pdftk:pre-folder (system:dir (vl-filename-directory filename)))
	(pdftk:background filename)
	(system:explorer (vl-filename-directory filename))
	)))
(defun pdftk:menu-batch-background (/ filename)
  (@::prompt "??????????У?????????????pdf??????????????????pdf?????н??????á?????? pdf ???????????????????Ч????")
  (if (setq pathname (system:get-folder "????????????PDF?????"))
      (progn
	(@:set-config  'pdftk:pre-folder (system:dir pathname))
	(setq pdfs (vl-directory-files pathname "*.pdf"))
	(foreach
	 pdf% pdfs
	 (if (null (wcmatch (strcase pdf% t) "*-background.pdf"))
	     (pdftk:background (strcat (system:dir pathname) pdf%))))
	(system:explorer (system:dir pathname))
	)))

(defun pdftk:background (filename / app)
  ;; ????????·??
  (setq app "bin\\pdftk.exe")
  (pdftk:download)
  (if (null (findfile (@:get-config 'pdftk:background)))
      (progn
	(vl-file-copy (strcat (@:package-path "pdftk") "background.pdf")
		      (@:get-config 'pdftk:background))
	(sleep 2)
	))
  ;;(setq files (vl-directory-files (system:get-folder) "*.pdf"))
  (if (and (findfile app)
	   filename)
      (progn
	;;(setq folder (system:get-folder "???????????PDF?????"))
	;;(setq files (strcat folder  "\\*.pdf"))
	(if (/= "" (@:get-config 'pdftk:background))
	    (progn
	      (setvar "cmdecho" 0)
	      (command "start-bg"
		       (strcat " /D \"" (vl-filename-directory filename) "\""
			       " /MIN /B  "
			       @:*prefix* app  " \""
			       filename "\" "
			       "background \""(@:get-config 'pdftk:background)"\" "
			       "output \""
			       (strcat (vl-filename-directory filename) "\\"
				       (vl-filename-base filename) "-background.pdf\" ")
			       ))
	      (setvar "cmdecho" 1)
	      ))
	))
  (princ)
  )
