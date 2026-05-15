
(vl-load-com)

;;;(C:GJO_XBreak)
;;;(command "._U")
(defun C:GJO_XBreak ( / UndoFlag OldOSM OldEcho XBreak_Pnt_in_Bndy XBreak_StartEnd
		    CWP1 CWP2 SelSet Index Enty1 Entlist OBJ1 Enty2 intPoints Values
		    IntList NewAssoc OBJName XTrimPnt StartPoint EndPoint Coords)
  
  
  
  
  (if (= 4 (logand 4 (getvar "undoctl")))
    (progn
      (setq UndoFlag T)
      (if (= 8 (logand 8 (getvar "undoctl")))
	      (command "._undo" "_end")
	    );if active undo group
      (command "._undo" "_begin")
    );progn
    (setq UndoFlag nil)
  );if undo auto enabled
  (setq OldOSM (getvar "osmode"))
  (setq OldEcho (getvar "cmdecho"))
  (setvar "cmdecho" 0)
  (setvar "osmode" 0)

  ;embed repeatable functions
  (defun XBreak_StartEnd (OBJ FromProperty AddZ / Coords CoordsLen StartPoint EndPoint)
    (setq Coords (vlax-safearray->list (vlax-variant-value (vlax-get-property OBJ FromProperty))));coords
    (setq CoordsLen (- (length Coords) 1))
    (if AddZ
      (progn
	      (setq StartPoint (trans
          (list (nth 0 Coords) (nth 1 Coords) 0.0)
          (vlax-vla-object->ename OBJ) 1)
	      );startpoint
	      (setq EndPoint (trans
          (list
            (nth (- CoordsLen 1) Coords)
            (nth CoordsLen Coords)
            0.0
          );list coords
          (vlax-vla-object->ename OBJ) 1)
        );endpoint
	    );progn AddZ True
      (progn
	      (setq StartPoint (trans
          (list (nth 0 Coords) (nth 1 Coords) (nth 2 Coords))
          (vlax-vla-object->ename OBJ) 1)
	      );startpoint
	      (setq EndPoint (trans
          (list
            (nth (- CoordsLen 2) Coords)
            (nth (- CoordsLen 1) Coords)
            (nth CoordsLen Coords)
          );list coords
          (vlax-vla-object->ename OBJ) 1)
	      );endpoint
	    );progn AddZ nil
    );if AddZ
    (list StartPoint EndPoint)
  );XBreak_StartEnd
  
  (defun XBreak_Pnt_in_Bndy (TestPoint BndyPnt1 BndyPnt2 / MinX MaxX MinY MaxY)
    (if (< (car BndyPnt1) (car BndyPnt2))
      (progn (setq MinX (car BndyPnt1)) (setq MaxX (car BndyPnt2)))
      (progn (setq MinX (car BndyPnt2)) (setq MaxX (car BndyPnt1)))
    )
    (if (< (cadr BndyPnt1) (cadr BndyPnt2))
      (progn (setq MinY (cadr BndyPnt1)) (setq MaxY (cadr BndyPnt2)))
      (progn (setq MinY (cadr BndyPnt2)) (setq MaxY (cadr BndyPnt1)))
    )
    (if
      (and
        (>= (car TestPoint) MinX)
        (<= (car TestPoint) MaxX)
        (>= (cadr TestPoint) MinY)
        (<= (cadr TestPoint) MaxY)
	    )
      T
      nil
    )
  );XBreak_Pnt_in_Bndy

  (setq CWP1 (getpoint "\nSelect Crossing Window Start Corner"))
  (while CWP1
    (if UndoFlag
      (command "._undo" "_Mark")
    )
    (if
      (and
        (setq CWP2 (getcorner CWP1 "\nSelect Opposite Corner"))
        (setq SelSet (ssget "_C" CWP1 CWP2 '((0 . "LINE,ARC,*P*LINE,CIRCLE"))))
	    );and
      (cond
	      ((> (sslength SelSet) 8)
	        (Princ "\nToo many entities in selection set: 8 entities maximum")
        )
	      ((>= (sslength SelSet) 3)
	        (progn
            ;Extract the entities
            (setq Index 0)
            (while (< Index (sslength SelSet))
              (setq Enty1 (ssname SelSet Index))
              (setq Entlist (cons Enty1 Entlist))
              (setq Index (1+ Index))
            );while
            (setq Enty1 nil)
            ;get the entities intersections
	   
	          (foreach Enty1 Entlist
              (setq OBJ1 (vlax-ename->vla-object Enty1))
              (setq Index 0)
              (repeat (length Entlist)
                (if (/= Enty1 (setq Enty2 (nth index Entlist)))
		              (progn
		                (setq intPoints (vla-IntersectWith OBJ1
				              (vlax-ename->vla-object Enty2) acExtendNone)
                    )
		                (setq Values (vlax-variant-value intPoints))
		                (if (> (vlax-safearray-get-u-bound Values 1) 0)
		                  (progn
		                    (setq XTrimPnt (vlax-safearray->list Values))
		                    (if (not (assoc Enty1 IntList))
                          ;add the group
                          (setq IntList (cons (cons Enty1 (list XTrimPnt)) IntList));setq
                          ;add the point to existing group
                          (progn
			                      (setq NewAssoc 
                              (cons Enty1
                                (cons XTrimPnt
                                  (cdr (assoc Enty1 IntList))
                                )
                              )
                            )
			                      (setq IntList (subst NewAssoc (assoc Enty1 IntList) IntList));setq
                          );progn if in list
			                  );if not in list
		                  );progn
		                );if intpoint
                  );progn
		            );if not same enty
	              (setq Index (1+ Index))
	            );repeat
	          );foreach
	   
            ;get to work
            (foreach Enty1 IntList
              (setq OBJ1 (vlax-ename->vla-object (car Enty1)))
              (setq OBJName (vla-Get-ObjectName OBJ1))
              (setq XTrimPnt (trans (cadr Enty1) 0 1))
              (princ (strcat "\n" (vl-princ-to-string (car Enty1)) " has " (itoa (length (cdr Enty1))) " intersection points"))
              (cond
                ;simple scenario
                ((= 2 (length (cdr Enty1)))
                  (progn
                    (setq EndPoint (trans (caddr Enty1) 0 1))
                    (command "._Break" (ssadd (car Enty1)) XTrimPnt EndPoint)
                    (setq EndPoint nil)
                  );progn
		            );cond points length of 2
                
                ;line overrun scenario
                ((= 1 (length (cdr Enty1)))
		              (progn
                    ;get closest endpoint of segment
                    (cond
		                  ((or (= OBJName "AcDbLine") (= OBJName "AcDbArc"))
		                    (progn
		                      (setq StartPoint
			                      (trans
				                      (vlax-safearray->list
				                        (vlax-variant-value
				                          (vla-get-StartPoint OBJ1)
                                )
                              )
				                      0
                              1
                            )
                          );startpoint
		                      (setq EndPoint
                            (trans
				                      (vlax-safearray->list
				                        (vlax-variant-value
				                          (vla-get-EndPoint OBJ1)
                                )
                              )
				                      0
                              1
                            )
                          );endpoint
		                    )
                      );lines/arcs
                      ((= OBJName "AcDbPolyline")
                        (progn
                          (setq Coords (XBreak_StartEnd OBJ1 "Coordinates" T))
                          (setq StartPoint (car Coords))
                          (setq EndPoint (cadr Coords))
                        )
                      );lw plines
                      ((= OBJName "AcDb3dPolyline")
                        (progn
                          (setq Coords (XBreak_StartEnd OBJ1 "Coordinates" nil))
                          (setq StartPoint (car Coords))
                          (setq EndPoint (cadr Coords))
                        )
                      );3D plines
                      ((= OBJName "AcDbSpline")
                        ;get start and end points from: ControlPoints
                        (progn
                          (setq Coords (XBreak_StartEnd OBJ1 "ControlPoints" nil))
                          (setq StartPoint (car Coords))
                          (setq EndPoint (cadr Coords))
                        )
                      );splines
		                  (T (setq XTrimPnt nil StartPoint nil EndPoint nil))
		                );cond
		                (if
                      (and
                        XTrimPnt StartPoint EndPoint
                        (not (equal XTrimPnt StartPoint 0.01))
                        (not (equal XTrimPnt EndPoint 0.01))
                      );and
		                  (if (< (distance XTrimPnt StartPoint) (distance XTrimPnt EndPoint))
		                    (if (XBreak_Pnt_in_Bndy StartPoint CWP1 CWP2)
			                    (command "._Break" (ssadd (car Enty1)) XTrimPnt StartPoint)
			                  )
		                    (if (XBreak_Pnt_in_Bndy EndPoint CWP1 CWP2)
			                    (command "._Break" (ssadd (car Enty1)) XTrimPnt EndPoint)
			                  )
		                  );if which end to trim
                    );if there is anything to trim
		              );progn points length of 1
		            );cond points length of 1
	            );cond
	          );foreach
	        );progn for workable cond
	      );workable cond
	      (T (Princ "\nInsufficient number of entities in selection set: 3 entities Minimum"))
	    );cond stmt
    );if selset
    (if UndoFlag
      (progn
	      (initget 128)
        (setq CWP1
          (getpoint
            (strcat "\nSelect Crossing Window Start Corner "
				     "or hit any number or letter key to undo last or "
				     "\<Enter\> to end command")
          )
        )
	      (if (= 'STR (type CWP1))
	        (progn
            (command "._undo" "_Back")
            (setq CWP1 (getpoint "\nSelect Crossing Window Start Corner or \<Enter\> to end command"))
          )
	      );if keyboard entry
	    )
      (setq CWP1 (getpoint "\nSelect Crossing Window Start Corner or \<Enter\> to end command"))
    )
    (setq Entlist nil)
    (setq IntList nil)
  );while

  (setvar "osmode" OldOSM)
  (setvar "cmdecho" OldEcho)
  (if UndoFlag
    (command "._undo" "_End")
  )
  (princ)
);C:GJO_XBreak
;;;(C:GJO_XBreak)
;;;(command "._U")

(princ "\nType \"C:GJO_XBreak\" to run")
(princ)


