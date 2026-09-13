;; 安全加载 COM 支持 — ZWCAD 无 COM，vl-load-com 会失败
;; 用 vl-catch-all-apply 包裹，避免无 COM 宿主（ZWCAD 等）崩溃
(if (vl-catch-all-error-p (vl-catch-all-apply 'vl-load-com '()))
  (princ "\n[UC] COM 支持加载失败（可能为无 COM 宿主）。"))

(setq *UC:VERSION* "0.1.1")

(defun uc:path-join (base child)
  (cond
    ((or (null base) (= base "")) child)
    ((or (null child) (= child "")) base)
    ((= (substr base (strlen base) 1) "\\") (strcat base child))
    (t (strcat base "\\" child))))

(defun uc:project-root nil
  (cond
    (*UC:ROOT*)
    ((findfile "uc-core.lsp")
     (setq *UC:ROOT* (vl-filename-directory (vl-filename-directory (findfile "uc-core.lsp")))))
    (t nil)))

(defun uc:core-file (name / root)
  (if (setq root (uc:project-root))
    (uc:path-join (uc:path-join root "unified-lib") name)
    nil))

(defun uc:file-loadable-p (path)
  (and path (findfile path)))

(defun uc:command-safe (args)
  (cond
    ((uc:function-defined-p 'command-s)
     (apply 'command-s args))
    (t
     (apply 'command args))))

(defun uc:com-available-p (/ obj)
  "判断 ActiveX/COM 是否真的可用。
不只检查是否报错：无头引擎(accoreconsole)下 vlax-get-acad-object 不报错但
返回 nil，旧写法会对 nil 取 not 而误判为可用，随后 vla-* 调用报
VLA-OBJECT nil；且 vla-* 未定义时属 no function definition，
vl-catch-all-apply 不兜底，会直接中断命令。故须同时校验函数存在与返回值有效。"
  (and (car (atoms-family 1 (list "VLAX-GET-ACAD-OBJECT")))
       (setq obj (vl-catch-all-apply 'vlax-get-acad-object '()))
       (not (vl-catch-all-error-p obj))
       obj))

(defun uc:alist-put (alist key value)
  (if (assoc key alist)
    (subst (cons key value) (assoc key alist) alist)
    (append alist (list (cons key value)))))

(defun uc:snapshot-sysvars (vars / result)
  (setq result nil)
  (foreach var vars
    (setq result (cons (cons var
                       (vl-catch-all-apply 'getvar (list var)))
                       result)))
  (reverse result))

(defun uc:restore-sysvars (snapshot / pair)
  (foreach pair snapshot
    (vl-catch-all-apply 'setvar (list (car pair) (cdr pair)))))

(defun uc:undo-begin nil
  (if (uc:com-available-p)
    (vl-catch-all-apply
      '(lambda nil
         (vla-StartUndoMark
           (vla-get-ActiveDocument (vlax-get-acad-object))))
      '())
    (vl-catch-all-apply 'uc:command-safe (list '("_.UNDO" "_BEGIN")))))

(defun uc:undo-end nil
  (if (uc:com-available-p)
    (vl-catch-all-apply
      '(lambda nil
         (vla-EndUndoMark
           (vla-get-ActiveDocument (vlax-get-acad-object))))
      '())
    (vl-catch-all-apply 'uc:command-safe (list '("_.UNDO" "_END")))))

(setq *UC:GUARD-STACK* nil)

(defun uc:guard-begin (sysvars / frame)
  (setq frame
    (list
      (cons 'olderror *error*)
      (cons 'snapshot (uc:snapshot-sysvars sysvars))
      (cons 'undo T)))
  (setq *UC:GUARD-STACK* (cons frame *UC:GUARD-STACK*))
  (uc:undo-begin)
  (setq *error*
    (lambda (msg)
      (uc:guard-fail msg)))
  T)

(defun uc:guard-end nil
  (if *UC:GUARD-STACK*
    (progn
      (uc:undo-end)
      (uc:restore-sysvars (cdr (assoc 'snapshot (car *UC:GUARD-STACK*))))
      (setq *error* (cdr (assoc 'olderror (car *UC:GUARD-STACK*))))
      (setq *UC:GUARD-STACK* (cdr *UC:GUARD-STACK*))))
  (princ))

(defun uc:guard-fail (msg / frame olderror)
  (if *UC:GUARD-STACK*
    (progn
      (setq frame (car *UC:GUARD-STACK*))
      (uc:undo-end)
      (uc:restore-sysvars (cdr (assoc 'snapshot frame)))
      (setq olderror (cdr (assoc 'olderror frame)))
      (setq *UC:GUARD-STACK* (cdr *UC:GUARD-STACK*))
      (setq *error* olderror)))
  (cond
    ((wcmatch (strcase (if msg msg "")) "*BREAK*,*CANCEL*,*QUIT*,*EXIT*")
     (princ "\nCommand canceled."))
    (t
     (princ (strcat "\nError: " (if msg msg "Unknown error")))))
  (princ))

(defun uc:function-defined-p (sym / atom-list sym-name)
  (if (null sym)
    nil
    (progn
      (setq sym-name
        (if (eq (type sym) 'SYM)
          (vl-symbol-name sym)
          nil))
      (setq atom-list (vl-catch-all-apply 'atoms-family (list 1)))
      (if (or (null sym-name) (vl-catch-all-error-p atom-list))
        nil
        (if (member sym-name atom-list) T nil)))))

(defun uc:command-defined-p (sym)
  (uc:function-defined-p sym))

(defun uc:call-command (sym)
  (apply sym '()))

(defun uc:pickset->list (ss / i out)
  (if ss
    (progn
      (setq i 0
            out nil)
      (repeat (sslength ss)
        (setq out (cons (ssname ss i) out)
              i (1+ i)))
      (reverse out))
    nil))

(defun uc:entity-getdxf (ename code)
  (cdr (assoc code (entget ename))))

(defun uc:entity-putdxf (ename code value / data old)
  (setq data (entget ename)
        old (assoc code data))
  (if old
    (entmod (subst (cons code value) old data))
    (entmod (append data (list (cons code value))))))

(defun uc:entity-type (ename)
  (uc:entity-getdxf ename 0))

(defun uc:entity-layer (ename)
  (uc:entity-getdxf ename 8))

(defun uc:entity-color (ename)
  (uc:entity-getdxf ename 62))

(defun uc:entity-bbox (ename / obj minpt maxpt)
  (if (and ename (uc:com-available-p))
    (progn
      (setq obj (vlax-ename->vla-object ename))
      (if (vl-catch-all-error-p
            (vl-catch-all-apply 'vla-GetBoundingBox (list obj 'minpt 'maxpt)))
        nil
        (list (vlax-safearray->list minpt)
              (vlax-safearray->list maxpt))))
    nil))

(defun uc:block-attributes (ename / next attrs)
  (if (= (uc:entity-type ename) "INSERT")
    (progn
      (setq next ename)
      (while (and (setq next (entnext next))
                  (= (uc:entity-type next) "ATTRIB"))
        (setq attrs
          (cons
            (cons (uc:entity-getdxf next 2)
                  (uc:entity-getdxf next 1))
            attrs)))
      (reverse attrs))
    nil))

(defun uc:block-effective-name (ename / obj result name)
  (cond
    ((null ename) nil)
    ((and (uc:com-available-p)
          (not (vl-catch-all-error-p
                 (setq result
                   (vl-catch-all-apply
                     '(lambda nil
                        (setq obj (vlax-ename->vla-object ename))
                        (vla-get-EffectiveName obj))
                     '())))))
     result)
    (t
     (setq name (uc:entity-getdxf ename 2))
     (if (and name (wcmatch name "`**"))
       name
       name))))

(defun uc:layer-exists-p (name)
  (and name (tblsearch "LAYER" name) T))

(defun uc:style-exists-p (name)
  (and name (tblsearch "STYLE" name) T))

(defun uc:block-exists-p (name)
  (and name (tblsearch "BLOCK" name) T))

(defun uc:ensure-layer (name color linetype / entry)
  (if (not (uc:layer-exists-p name))
    (entmakex
      (list '(0 . "LAYER")
            '(100 . "AcDbSymbolTableRecord")
            '(100 . "AcDbLayerTableRecord")
            '(70 . 0)
            (cons 2 name)
            (cons 62 (if color color 7))
            (cons 6 (if linetype linetype "Continuous"))))
    (progn
      (uc:layer-set-dxf name 62 (if color color 7))
      (uc:layer-set-dxf name 6 (if linetype linetype "Continuous"))))
  name)

(defun uc:layer-set-dxf (name code value / entry old)
  (if (uc:layer-exists-p name)
    (progn
      (setq entry (entget (tblobjname "LAYER" name))
            old (assoc code entry))
      (if old
        (entmod (subst (cons code value) old entry))
        (entmod (append entry (list (cons code value))))))))

(defun uc:layer-unfreeze-unlock (name / entry flags)
  (if (uc:layer-exists-p name)
    (progn
      (setq entry (entget (tblobjname "LAYER" name))
            flags (cdr (assoc 70 entry)))
      (if (null flags)
        (setq flags 0))
      (if (= 1 (logand flags 1))
        (setq flags (- flags 1)))
      (if (= 4 (logand flags 4))
        (setq flags (- flags 4)))
      (uc:layer-set-dxf name 70 flags))))

(defun uc:prepare-layer (name color linetype)
  (uc:ensure-layer name color linetype)
  (if (uc:layer-exists-p name)
    (progn
      (uc:layer-set-dxf name 62
        (abs
          (if (cdr (assoc 62 (entget (tblobjname "LAYER" name))))
            (cdr (assoc 62 (entget (tblobjname "LAYER" name))))
            (if color color 7))))
      (uc:layer-unfreeze-unlock name)))
  name)

(princ (strcat "\n[UC] core loaded v" *UC:VERSION*))
(princ)
