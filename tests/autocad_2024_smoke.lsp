(setq *cc:smoke-failures* nil)

(defun cc:fail (msg)
  (setq *cc:smoke-failures* (cons msg *cc:smoke-failures*))
  (princ (strcat "\n[CCSMOKE] FAIL: " msg)))

(defun cc:pass (msg)
  (princ (strcat "\n[CCSMOKE] PASS: " msg)))

(defun cc:skip (msg)
  (princ (strcat "\n[CCSMOKE] SKIP: " msg)))

(defun cc:check (cond msg)
  (if cond
    (cc:pass msg)
    (cc:fail msg)))

(defun cc:load-file (path label / load-res)
  (if (findfile path)
    (progn
      (setq load-res (vl-catch-all-apply 'load (list path)))
      (if (vl-catch-all-error-p load-res)
        (cc:fail (strcat label " load error: " (vl-catch-all-error-message load-res)))
        (cc:pass (strcat label " loaded"))))
    (cc:fail (strcat label " missing: " path))))

(defun cc:defined-p (sym / res)
  (setq res (vl-catch-all-apply 'uc:function-defined-p (list sym)))
  (if (vl-catch-all-error-p res)
    nil
    res))

(defun cc:get-first-insert (/ ss)
  (if (setq ss (ssget "_X" '((0 . "INSERT"))))
    (ssname ss 0)
    nil))

(defun cc:run-smoke (/ root insert-ent insert-obj insert-name)
  (setq root "d:\\My Code\\Claude Code\\03-AutoCAD-lisp")
  (if (null root)
    (progn
      (cc:fail "project root unresolved")
      (princ))
    (progn
      (setq *TB:PATH* (strcat root "\\TB-Toolbox"))

      (princ "\n[CCSMOKE] Start AutoCAD 2024 smoke")
      (cc:load-file (strcat root "\\TB-Toolbox\\load.lsp") "TB-Toolbox")
      (cc:load-file (strcat root "\\DiffCheck\\DiffCheck.lsp") "DiffCheck")
      (cc:load-file (strcat root "\\SyncBlock\\SyncBlock.lsp") "SyncBlock")

      (cc:check (cc:defined-p 'c:TBHELP) "TBHELP registered")
      (cc:check (cc:defined-p 'c:DFC) "DFC registered")
      (cc:check (cc:defined-p 'c:DFCC) "DFCC registered")
      (cc:check (cc:defined-p 'c:SyncNow) "SyncNow registered")
      (cc:check (cc:defined-p 'sb:get-active-context) "sb:get-active-context registered")

      (if (cc:defined-p 'uc:com-available-p)
        (cc:check (uc:com-available-p) "COM available")
        (cc:fail "uc:com-available-p undefined"))

      (if (cc:defined-p 'sb:get-active-context)
        (if (sb:get-active-context)
          (cc:pass "active context available")
          (cc:skip "active context unavailable in current console session"))
        (cc:fail "sb:get-active-context undefined"))

      (if (cc:defined-p 'c:TBHELP)
        (progn
          (c:TBHELP)
          (cc:pass "TBHELP callable"))
        (cc:fail "TBHELP not callable"))

      (if (cc:defined-p 'c:DFCC)
        (progn
          (c:DFCC)
          (cc:pass "DFCC callable"))
        (cc:fail "DFCC not callable"))

      (setq insert-ent (cc:get-first-insert))
      (if insert-ent
        (progn
          (setq insert-obj (vlax-ename->vla-object insert-ent))
          (setq insert-name (sb:get-effective-name insert-ent))
          (cc:check insert-name "block name resolved"))
        (cc:skip "no INSERT found for sb:get-effective-name"))

      (if *cc:smoke-failures*
        (progn
          (princ (strcat "\n[CCSMOKE] Result: FAIL " (itoa (length *cc:smoke-failures*))))
          (foreach item (reverse *cc:smoke-failures*)
            (princ (strcat "\n[CCSMOKE] Item: " item))))
        (princ "\n[CCSMOKE] Result: PASS"))
      (princ))))

(cc:run-smoke)
