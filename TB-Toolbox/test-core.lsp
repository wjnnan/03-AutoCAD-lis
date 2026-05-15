;;; test-core.lsp — minimal test, ASCII only

(defun sys:detect-platform (/ product)
  (setq product (strcase (getvar "product")))
  (setq *SYS:PLATFORM*
    (cond
      ((wcmatch product "*ZWCAD*")    "ZWCAD")
      ((wcmatch product "*GSTARCAD*") "GSTARCAD")
      ((wcmatch product "*BRICSCAD*") "BRICSCAD")
      (t                              "AUTOCAD")))
  (setq *SYS:HAS-ACTIVEX*
    (not (= *SYS:PLATFORM* "ZWCAD")))
  (setq *SYS:HAS-REACTORS*
    (= *SYS:PLATFORM* "AUTOCAD"))
  (setq *SYS:ACADVER* (atof (getvar "acadver")))
  (princ (strcat "\n[TB] Platform: " *SYS:PLATFORM*
                 " | ActiveX: " (if *SYS:HAS-ACTIVEX* "Y" "N")
                 " | Reactors: " (if *SYS:HAS-REACTORS* "Y" "N")))
  (princ))

(sys:detect-platform)

(setq *SYS:CONFIG* nil
      *PRJ:CONFIG* nil
      *TMP:VARS*   nil)

(setq *SYS:CONFIG-FILE*
  (strcat (if (getvar "ROAMABLEROOTPREFIX")
            (getvar "ROAMABLEROOTPREFIX")
            (getvar "DWGPREFIX"))
          "TB-SysConfig.cfg"))

(defun sys:alist-put (alist key value)
  (cond
    ((member "UC:ALIST-PUT" (atoms-family 1))
     (uc:alist-put alist key value))
    ((assoc key alist)
     (subst (cons key value) (assoc key alist) alist))
    (t
     (append alist (list (cons key value))))))

;; ;;; sys:get — read parameter value (3-level lookup: tmp > prj > sys)
(defun sys:get (key / v)
  (if (setq v (cdr (assoc key *TMP:VARS*))) v
    (if (setq v (cdr (assoc key *PRJ:CONFIG*))) v
      (cdr (assoc key *SYS:CONFIG*)))))

;; ;;; sys:set — write parameter value based on key prefix
(defun sys:set (key value)
  (cond
    ((wcmatch (vl-symbol-name key) "*SYS:*")
     (setq *SYS:CONFIG* (sys:alist-put *SYS:CONFIG* key value))
     (sys:save-config)
     value)
    ((wcmatch (vl-symbol-name key) "*PRJ:*")
     (setq *PRJ:CONFIG* (sys:alist-put *PRJ:CONFIG* key value))
     value)
    ((wcmatch (vl-symbol-name key) "*TMP:*")
     (setq *TMP:VARS* (sys:alist-put *TMP:VARS* key value))
     value)
    (t (princ (strcat "\n[TB] Unknown prefix: " (vl-symbol-name key))) nil)))

(defun sys:save-config (/ f)
  (if (setq f (open *SYS:CONFIG-FILE* "w"))
    (progn
      (foreach pair *SYS:CONFIG*
        (write-line (strcat (vl-symbol-name (car pair))
                            "="
                            (vl-princ-to-string (cdr pair))) f))
      (close f))))

(defun sys:load-config (/ f line k v pos)
  (if (setq f (open *SYS:CONFIG-FILE* "r"))
    (progn
      (while (setq line (read-line f))
        (if (setq pos (vl-string-search "=" line))
          (setq k (read (substr line 1 pos))
                v (read (substr line (+ pos 2)))
                *SYS:CONFIG* (sys:alist-put *SYS:CONFIG* k v))))
      (close f))))

(defun sys:init-defaults nil
  (or (sys:get '*SYS:DWG-SCALE*)      (sys:set '*SYS:DWG-SCALE* 100))
  (or (sys:get '*SYS:TEXT-STYLE*)     (sys:set '*SYS:TEXT-STYLE* "TSSD_Rein"))
  (or (sys:get '*SYS:TEXT-FONT*)      (sys:set '*SYS:TEXT-FONT* "tssdeng.shx"))
  (or (sys:get '*SYS:TEXT-BIGFONT*)   (sys:set '*SYS:TEXT-BIGFONT* "hztxt.shx"))
  (or (sys:get '*SYS:TEXT-WIDTH*)     (sys:set '*SYS:TEXT-WIDTH* 0.7))
  (or (sys:get '*SYS:TEXT-HEIGHT*)    (sys:set '*SYS:TEXT-HEIGHT* 350))
  (or (sys:get '*SYS:DIM-PRECISION*)  (sys:set '*SYS:DIM-PRECISION* 2))
  (or (sys:get '*SYS:CLOUD-LAYER*)    (sys:set '*SYS:CLOUD-LAYER* "Cloud"))
  (or (sys:get '*SYS:CLOUD-COLOR*)    (sys:set '*SYS:CLOUD-COLOR* 6))
  (or (sys:get '*SYS:CLOUD-ARC*)      (sys:set '*SYS:CLOUD-ARC* 6))
  (or (sys:get '*SYS:CLOUD-PLOT*)     (sys:set '*SYS:CLOUD-PLOT* 0))
  (or (sys:get '*SYS:LOAD-PATH*)     (sys:set '*SYS:LOAD-PATH* (vl-string-right-trim "\\" (or (getvar "DWGPREFIX") ""))))
  (or (sys:get '*PRJ:BEAM-LAYER*)     (sys:set '*PRJ:BEAM-LAYER* "S_BEAM"))
  (or (sys:get '*PRJ:COLUMN-LAYER*)   (sys:set '*PRJ:COLUMN-LAYER* "S_COL"))
  (or (sys:get '*PRJ:WALL-LAYER*)     (sys:set '*PRJ:WALL-LAYER* "S_WALL"))
  (or (sys:get '*PRJ:TEXT-LAYER*)     (sys:set '*PRJ:TEXT-LAYER* "S_TEXT"))
  (or (sys:get '*PRJ:DIM-LAYER*)      (sys:set '*PRJ:DIM-LAYER* "S_DIM"))
  (or (sys:get '*SYS:REBAR-LAYER*)     (sys:set '*SYS:REBAR-LAYER* "S_REBAR"))
  (or (sys:get '*SYS:STIRRUP-LAYER*)   (sys:set '*SYS:STIRRUP-LAYER* "S_STIRRUP"))
  (or (sys:get '*SYS:REBAR-TEXT-LAYER*) (sys:set '*SYS:REBAR-TEXT-LAYER* "S_REBAR_TEXT"))
  (or (sys:get '*SYS:REBAR-WIDTH*)     (sys:set '*SYS:REBAR-WIDTH* 0.5))
  (or (sys:get '*SYS:REBAR-DIAMETER*)  (sys:set '*SYS:REBAR-DIAMETER* 8))
  (or (sys:get '*SYS:REBAR-GRADE*)     (sys:set '*SYS:REBAR-GRADE* 3))
  (or (sys:get '*SYS:REBAR-HOOK*)      (sys:set '*SYS:REBAR-HOOK* 2))
  (or (sys:get '*SYS:REBAR-COVER*)     (sys:set '*SYS:REBAR-COVER* 25)))

(sys:load-config)
(sys:init-defaults)

(princ "\n[TB] Test core loaded OK.")
(princ)
