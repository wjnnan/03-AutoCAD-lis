
;;;????????V2.0
;;;???????????
;;;??????????
(defun c:ZBZL()
    (setvar "cmdecho" 0)
(if (= hd nil) (setq hd 2800))
(if (= ht nil) (setq ht 3200))
(if (= DL nil) (setq DL 800))
(if (= PDL nil) (setq PDL 600))
(if (= L_cLu nil) (setq L_cLu "*S-OUTLINE*"))
(if (= L_tab nil) (setq L_tab "*TAB*"))
(if (= L_pdx nil) (setq L_pdx "*pdx*"))
        (princ "\n????????<????????????>??")
        (while (= nil ss_tab )
               (setq tab (ssget(list (cons 0 "LWPOLYLINE")(cons 8 L_tab))))        
               (if (= nil tab) (dcl_ZBZL_Form1) (ZBZL))
        )
)
(defun dcl_ZBZL_Form1()
  (setq dcl_id (load_dialog "ZBZL.dcl"));????DCL
     (if (not (new_dialog "ZBZL" dcl_id))(exit)) ;;????????

  (set_tile "Text1" (rtos hd))
  (set_tile "Text2" (rtos ht))
  (set_tile "Text3" (rtos DL))
  (set_tile "Text4" (rtos PDL))
  (set_tile "Text5" L_tab)
  (set_tile "Text6" L_cLu)
  (set_tile "Text7" L_pdx)
  (action_tile "accept" "(get_TabText) (done_dialog 1)")
  (action_tile "Command_H1" "(get_TabText) (done_dialog 2)")
  (action_tile "Command_H2" "(get_TabText) (done_dialog 3)")
  (action_tile "Command_W1" "(get_TabText) (done_dialog 4)")
  (action_tile "Command_L1" "(get_TabText) (done_dialog 5)")
  (action_tile "Command_L_tab" "(get_TabText) (done_dialog 6)")
  (action_tile "Command_L_cLu" "(get_TabText) (done_dialog 7)")
  (action_tile "Command_L_pdx" "(get_TabText) (done_dialog 8)")

  (setq dZBZL (start_dialog))
  (cond
     ((= dZBZL 1) (ZBZL))
     ((= dZBZL 2) (setq hd (QYD:dist)) (dcl_ZBZL_Form1))
     ((= dZBZL 3) (setq ht (QYD:dist)) (dcl_ZBZL_Form1))
     ((= dZBZL 4) (setq DL (QYD:dist)) (dcl_ZBZL_Form1))
     ((= dZBZL 5) (setq PDL (QYD:dist)) (dcl_ZBZL_Form1))
     ((= dZBZL 6) (setq s_sym (ssget)) (setq L_tab (QYD:SQTY 8 s_sym L_tab ",")) (dcl_ZBZL_Form1)) ;78.????????????(???)
     ((= dZBZL 7) (setq s_sym (ssget)) (setq L_cLu (QYD:SQTY 8 s_sym L_cLu ",")) (dcl_ZBZL_Form1)) 
     ((= dZBZL 8) (setq s_sym (ssget)) (setq L_pdx (QYD:SQTY 8 s_sym L_pdx ",")) (dcl_ZBZL_Form1))
  )
 )

;;;???????????
(defun get_TabText()
  (setq hd (atof (get_tile "Text1")))   ;;;????????????
  (setq ht (atof (get_tile "Text2")))    ;;;?????????????
  (setq DL (atof (get_tile "Text3")))   ;;;????????????
  (setq PDL (atof (get_tile "Text4")))    ;;;???????
  (setq L_tab (get_tile "Text5"))  ;;;???????
  (setq L_cLu (get_tile "Text6"))   ;;;?????????
  (setq L_pdx (get_tile "Text7"))   ;;;????????
)
;;;???????
(defun QYD:dist()
  (setq pt1 (getpoint "\n????????:"))
  (setq pt2 (getpoint pt1 "\n????????:"))
  (setq pdist (distance pt1 pt2))
  pdist
)

;;;?????????????
(defun ZBZL()  
  (if tab    
 (progn
   (setq oldmcdecho (getvar "cmdecho"))
   (setvar "cmdecho" 0)
   (setq tab_i -1)
   (repeat (sslength tab)
     (setq obj (ssname tab (setq tab_i (1+ tab_i))))
     (vla-GetBoundingBox
       (vlax-ename->vla-object obj)
       'p1
       'p2
     ) ;_?????????????????§³??
     (setq p1 (vlax-safearray->list p1)) ;_?????
     (setq p2 (vlax-safearray->list p2)) ;_?????
     (command "..zoom" p1 p2)
     (setq ss1 (ssget "_w" (mapcar '+ p1 (list 0 ht)) p2 (list (cons -4 "<not")(cons 8 "?v§µ??")(cons -4 "not>")(cons -4 "<not")(cons 8 L_tab)(cons -4 "not>"))))
     (setq ss2 (ssget "_p" (list                                 
                             (cons 0 "*LINE")(cons 8 L_cLu) 
                             (cons -4 "<not")
                             (cons -4 "<and") 
                             (cons 8 L_pdx) 
                             (cons -4 "<not") (cons 90 2)(cons -4 "not>")
                             (cons -4 "and>")
                             (cons -4 "not>")                             
                             )
                 )
      )
(setq pb1
 	(list
		(* 0.5 (+(car p1) (car p2)))
	        (cadr (mapcar '+ p1 (list 0 ht)))
	)
)      
      (command "_u")
;;;?????????
  (if (/= ss2 nil)
    (progn
      (setq &ss1 (MJ:GetssBox ss2));64.???????????¦Ï? by gxl
      (setq p1 (car &ss1))
      (setq p2 (cadr &ss1))        
     )
   )
(setq pz
 	(list
		( + (* 0.5 (+(car p1) (car p2))) (* 0.5 DL))
	        ( - (cadr p1) hd)
	)
)

     (command "move" ss1 """non" pz "non"pb1 ) 
   )
   (setvar "cmdecho" oldmcdecho)
   (princ "\n???")
 )
  )
  (princ)
)
;64.???????????¦Ï? by gxl
;;??????????????????????
(defun MJ:GetssBox (ss / i l1 l2 ll ur)
  (repeat (setq i (sslength ss))
    (if (vl-catch-all-error-p
          (vl-catch-all-apply 'vla-getboundingbox
            (list (vlax-ename->vla-object (ssname ss (setq i (1- i)))) 'll 'ur)))
      (setq ll nil ur nil))
    (setq l1 (cons (vlax-safearray->list ll) l1)
	      l2 (cons (vlax-safearray->list ur) l2)
    )
  )
  (mapcar '(lambda (a b) (apply 'mapcar (cons a b)))
	      '(min max)
	       (list l1 l2)
  )
)


(defun MJ:GetssBox_2 (ss / i l1 l2 ll ur)
    (if (vl-catch-all-error-p
          (vl-catch-all-apply 'vla-getboundingbox
            (list (vlax-ename->vla-object ss) 'll 'ur)))
      (setq ll nil ur nil))
    (setq l1 (cons (vlax-safearray->list ll) l1)
	      l2 (cons (vlax-safearray->list ur) l2)
    )
  
  (mapcar '(lambda (a b) (apply 'mapcar (cons a b)))
	      '(min max)
	       (list l1 l2)
  )
)
;12.?¡Â?????§Ò?????????????
;?¡Â?????§Ò????????????? by PEACE 2013/09/06
;string=???????strkeylst=??????§Ò?
(defun QYD:Split (string strkeylst / strkey i j po strlst strlst0 xlen)
  (setq strlst (cons string '()))
  (cond
    (
      (= strkeylst '())
      (setq strlst strlst)
    )
    (
      t
      (setq i 0)
      (repeat (length strkeylst)
        (setq strkey (nth i strkeylst)
                xlen (1+ (strlen strkey))
        )
        (cond
          (
            (= strkey "")
            (setq strlst strlst)
          )
          (
            t
            (setq j 0 strlst0 '())
            (repeat (length strlst)
              (setq string (nth j strlst))
              (while (setq po (vl-string-search strkey string))
                (setq strlst0 (cons (substr string 1 po) strlst0))
                (setq string (substr string (+ po xlen)))
              )
              (setq strlst0 (cons string strlst0) j (1+ j))
              (if (= (nth 0 strlst0) "") (setq strlst0 (cdr strlst0)))
            )
            (setq strlst (reverse strlst0) i (1+ i))
          )
        )
      )
    )
  )
  (setq i 0 strlst0 '())
  (repeat (length strlst)
    (if (/= (nth i strlst) "")
      (setq strlst0 (cons (nth i strlst) strlst0))
    )
    (setq i (1+ i))
  )
  (setq strlst (reverse strlst0))
  strlst
);12.?¡Â?????§Ò?????????????
;?¡Â?????§Ò????????????? by PEACE 2013/09/06
;string=???????strkeylst=??????§Ò?
(defun QYD:Split (string strkeylst / strkey i j po strlst strlst0 xlen)
  (setq strlst (cons string '()))
  (cond
    (
      (= strkeylst '())
      (setq strlst strlst)
    )
    (
      t
      (setq i 0)
      (repeat (length strkeylst)
        (setq strkey (nth i strkeylst)
                xlen (1+ (strlen strkey))
        )
        (cond
          (
            (= strkey "")
            (setq strlst strlst)
          )
          (
            t
            (setq j 0 strlst0 '())
            (repeat (length strlst)
              (setq string (nth j strlst))
              (while (setq po (vl-string-search strkey string))
                (setq strlst0 (cons (substr string 1 po) strlst0))
                (setq string (substr string (+ po xlen)))
              )
              (setq strlst0 (cons string strlst0) j (1+ j))
              (if (= (nth 0 strlst0) "") (setq strlst0 (cdr strlst0)))
            )
            (setq strlst (reverse strlst0) i (1+ i))
          )
        )
      )
    )
  )
  (setq i 0 strlst0 '())
  (repeat (length strlst)
    (if (/= (nth i strlst) "")
      (setq strlst0 (cons (nth i strlst) strlst0))
    )
    (setq i (1+ i))
  )
  (setq strlst (reverse strlst0))
  strlst
)
;;48. [????] ????????????
(defun MJ:delsame (l)
  (if L
    (cons (car L) (MJ:delsame (vl-remove (car L) (cdr L))))
  )
)
;59a.????????????
(defun QYD:List_str(lst str)
  (substr (apply 'strcat (mapcar '(lambda (a) (strcat str a)) lst))
   (1+ (strlen str))
  )
)

;77.??????????DXF??????
(defun QYD:dxf (n s1) (cdr (assoc n (entget s1))))

;78.????????????(???)
;???¨²???
(defun QYD:SQTY (n s_sym s_sym_1 chrm)
     (setq s_sym_0 s_sym_1)
     (setq in0 0 num (sslength s_sym))
   (repeat num
     (setq s_sym_i (QYD:dxf n (ssname s_sym in0)));77.??????????DXF??????
     (setq s_sym_0 (strcat s_sym_0","s_sym_i))
     (setq in0 (1+ in0)
   ) 
   (setq s_sym_list (QYD:Split s_sym_0 '(","))) ;12.?¡Â?????§Ò?????????????
   (setq s_sym_list (MJ:delsame s_sym_list))     ;;48. [????] ????????????
    (setq s_sym_1 (QYD:List_str s_sym_list chrm));59a.????????????
     s_sym_1
     )
)
  (princ)  (princ)