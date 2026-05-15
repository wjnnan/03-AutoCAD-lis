;;; SyncBlock.lsp -- 块定义同步工具
;;; 命令：SyncNow / SFM

(vl-load-com)

(if (and (null *UC:ROOT*) *TB:PATH*)
  (setq *UC:ROOT* (vl-filename-directory *TB:PATH*)))

(if (not (member 'uc:guard-begin (atoms-family 1)))
  (cond
    ((and *UC:ROOT* (findfile (strcat *UC:ROOT* "\\unified-lib\\uc-core.lsp")))
     (load (strcat *UC:ROOT* "\\unified-lib\\uc-core.lsp"))
     (if (findfile (strcat *UC:ROOT* "\\unified-lib\\uc-atlisp-adapter.lsp"))
       (load (strcat *UC:ROOT* "\\unified-lib\\uc-atlisp-adapter.lsp"))))
    ((findfile "uc-core.lsp")
     (load (findfile "uc-core.lsp"))
     (if (findfile "uc-atlisp-adapter.lsp")
       (load (findfile "uc-atlisp-adapter.lsp"))))))

(defun sb:end-command (msg)
  (if (uc:function-defined-p 'uc:guard-end)
    (uc:guard-end))
  (if msg
    (princ msg))
  (princ)
  nil)

(defun sb:get-active-context (/ acad-res doc-res blocks-res)
  (if (not (and (uc:function-defined-p 'uc:com-available-p) (uc:com-available-p)))
    nil
    (progn
      (setq acad-res (vl-catch-all-apply 'vlax-get-acad-object '()))
      (if (vl-catch-all-error-p acad-res)
        nil
        (progn
          (setq doc-res (vl-catch-all-apply 'vla-get-ActiveDocument (list acad-res)))
          (if (vl-catch-all-error-p doc-res)
            nil
            (progn
              (setq blocks-res (vl-catch-all-apply 'vla-get-Blocks (list doc-res)))
              (if (vl-catch-all-error-p blocks-res)
                nil
                (list acad-res doc-res blocks-res)))))))))

(defun sb:get-effective-name (ename)
  (if (uc:function-defined-p 'uc:block-effective-name)
    (uc:block-effective-name ename)
    nil))

(defun sb:get-block-def (blocks name / def-res)
  (if (and blocks name (/= name ""))
    (progn
      (setq def-res (vl-catch-all-apply 'vla-Item (list blocks name)))
      (if (vl-catch-all-error-p def-res)
        nil
        def-res))
    nil))

(defun sb:object-list->safearray (objects / arr idx obj)
  (if objects
    (progn
      (setq arr (vlax-make-safearray vlax-vbObject (cons 0 (1- (length objects))))
            idx 0)
      (foreach obj objects
        (vlax-safearray-put-element arr idx obj)
        (setq idx (1+ idx)))
      arr)
    nil))

(defun sb:safearray->object-list (arr / idx result)
  (if arr
    (progn
      (setq idx (vlax-safearray-get-l-bound arr 1)
            result nil)
      (while (<= idx (vlax-safearray-get-u-bound arr 1))
        (setq result (cons (vlax-safearray-get-element arr idx) result)
              idx (1+ idx)))
      (reverse result))
    nil))

(defun sb:get-obj-center (obj / ll ur)
  (if (not (vl-catch-all-error-p
             (vl-catch-all-apply 'vla-GetBoundingBox (list obj 'll 'ur))))
    (progn
      (setq ll (vlax-safearray->list ll)
            ur (vlax-safearray->list ur))
      (list (/ (+ (car ll) (car ur)) 2.0)
            (/ (+ (cadr ll) (cadr ur)) 2.0)))
    nil))

(defun sb:is-geometry-object-p (obj-name)
  (and (/= obj-name "AcDbHatch")
       (/= obj-name "AcDbAttributeDefinition")
       (/= obj-name "AcDbText")
       (/= obj-name "AcDbMText")
       (not (vl-string-search "Dimension" obj-name))))

(defun sb:collect-def-stats (blkdef / layer-list lay-color-map centers counts objs-to-delete minpt
                                    obj lay obj-name ll ur cur-count-item cur-count pt col)
  (setq layer-list nil
        lay-color-map nil
        centers nil
        counts nil
        objs-to-delete nil
        minpt (list 1e99 1e99))
  (vlax-for obj blkdef
    (setq objs-to-delete (cons obj objs-to-delete)
          lay (vla-get-Layer obj)
          obj-name (vla-get-ObjectName obj))
    (if (not (member lay layer-list))
      (setq layer-list (cons lay layer-list)))
    (if (and (not (assoc lay lay-color-map))
             (not (vl-catch-all-error-p
                    (setq col (vl-catch-all-apply 'vla-get-Color (list obj))))))
      (setq lay-color-map (cons (cons lay col) lay-color-map)))
    (if (sb:is-geometry-object-p obj-name)
      (progn
        (if (not (vl-catch-all-error-p
                   (vl-catch-all-apply 'vla-GetBoundingBox (list obj 'll 'ur))))
          (setq minpt
            (list
              (min (car minpt) (car (vlax-safearray->list ll)))
              (min (cadr minpt) (cadr (vlax-safearray->list ll))))))
        (setq cur-count-item (assoc lay counts)
              cur-count (if cur-count-item (cdr cur-count-item) 0))
        (if (< cur-count 12)
          (if (setq pt (sb:get-obj-center obj))
            (progn
              (setq centers (cons pt centers))
              (setq counts
                (if cur-count-item
                  (subst (cons lay (1+ cur-count)) cur-count-item counts)
                  (cons (cons lay 1) counts)))))))))
  (list layer-list lay-color-map centers counts objs-to-delete minpt))

(defun sb:collect-master-geometry (master-def allowed-layers / geometry centers counts hatch-count minpt
                                              obj lay obj-name ll ur cur-count-item cur-count pt)
  (setq geometry nil
        centers nil
        counts nil
        hatch-count 0
        minpt (list 1e99 1e99))
  (vlax-for obj master-def
    (setq lay (vla-get-Layer obj))
    (if (member lay allowed-layers)
      (progn
        (setq obj-name (vla-get-ObjectName obj))
        (if (= obj-name "AcDbHatch")
          (setq hatch-count (1+ hatch-count))
          (progn
            (setq geometry (cons obj geometry))
            (if (sb:is-geometry-object-p obj-name)
              (progn
                (if (not (vl-catch-all-error-p
                           (vl-catch-all-apply 'vla-GetBoundingBox (list obj 'll 'ur))))
                  (setq minpt
                    (list
                      (min (car minpt) (car (vlax-safearray->list ll)))
                      (min (cadr minpt) (cadr (vlax-safearray->list ll))))))
                (setq cur-count-item (assoc lay counts)
                      cur-count (if cur-count-item (cdr cur-count-item) 0))
                (if (< cur-count 12)
                  (if (setq pt (sb:get-obj-center obj))
                    (progn
                      (setq centers (cons pt centers))
                      (setq counts
                        (if cur-count-item
                          (subst (cons lay (1+ cur-count)) cur-count-item counts)
                          (cons (cons lay 1) counts)))))))))))))
  (list geometry centers counts hatch-count minpt))

(defun sb:vote-offset (target-centers master-centers target-min master-min / vote-list max-vote
                                       best-dx best-dy dx dy key existing item)
  (setq max-vote 0
        vote-list nil)
  (if (and target-centers master-centers)
    (progn
      (foreach tpt target-centers
        (foreach mpt master-centers
          (setq dx (- (car tpt) (car mpt))
                dy (- (cadr tpt) (cadr mpt))
                key (strcat (rtos dx 2 1) "," (rtos dy 2 1))
                existing (assoc key vote-list))
          (if existing
            (setq vote-list
              (subst (list key (1+ (cadr existing)) dx dy) existing vote-list))
            (setq vote-list (cons (list key 1 dx dy) vote-list)))))
      (foreach item vote-list
        (if (> (cadr item) max-vote)
          (setq max-vote (cadr item)
                best-dx (caddr item)
                best-dy (cadddr item))))))
  (if (>= max-vote 3)
    (list best-dx best-dy 0.0)
    (if (and (/= (car master-min) 1e99) (/= (car target-min) 1e99))
      (list (- (car target-min) (car master-min))
            (- (cadr target-min) (cadr master-min))
            0.0)
      nil)))

(defun sb:apply-sync (doc target-def geometry-to-copy objs-to-delete lay-color-map offset / pt1 pt2 copy-res
                           copy-arr copied-objs success-count new-obj obj-lay mapped-col obj)
  (if (not geometry-to-copy)
    (progn
      (princ "\n  [Warning] No matching geometry found in master block.")
      nil)
    (progn
      (setq pt1 (vlax-3d-point 0.0 0.0 0.0)
            copy-arr (sb:object-list->safearray geometry-to-copy)
            pt2 (if offset
                  (vlax-3d-point (car offset) (cadr offset) (caddr offset))
                  nil)
            copy-res (if copy-arr
                       (vl-catch-all-apply 'vla-CopyObjects (list doc copy-arr target-def))
                       nil))
      (if (or (null copy-arr)
              (null copy-res)
              (vl-catch-all-error-p copy-res))
        (progn
          (princ "\n  [Error] Copy failed. Old objects were kept unchanged.")
          nil)
        (progn
          (setq copied-objs
            (sb:safearray->object-list
              (vlax-variant-value copy-res)))
          (if (null copied-objs)
            (progn
              (princ "\n  [Error] Copy returned no new objects. Old objects were kept unchanged.")
              nil)
            (progn
          (foreach obj objs-to-delete
            (vl-catch-all-apply 'vla-Delete (list obj)))
          (setq success-count 0)
          (foreach new-obj copied-objs
            (if pt2
              (vl-catch-all-apply 'vla-Move (list new-obj pt1 pt2)))
            (if (not (vl-catch-all-error-p
                       (setq obj-lay (vl-catch-all-apply 'vla-get-Layer (list new-obj)))))
              (if (setq mapped-col (cdr (assoc obj-lay lay-color-map)))
                (vl-catch-all-apply 'vla-put-Color (list new-obj mapped-col))))
            (setq success-count (1+ success-count)))
          (princ (strcat "\n  Done: " (itoa success-count) " objects synced."))
          T)))))))

(defun c:SyncNow (/ context acad-obj doc blocks master-ent master-vla master-name master-def
                    target-ss i target-ent target-vla target-name target-def
                    target-stats master-stats layer-list lay-color-map t-centers
                    objs-to-delete t-min geometry-to-copy m-centers hatch-count m-min
                    final-offset synced-count skipped-count regen-res)
  (if (uc:function-defined-p 'uc:guard-begin)
    (uc:guard-begin '("CMDECHO" "OSMODE" "CLAYER")))

  (setq context (sb:get-active-context))
  (if (null context)
    (sb:end-command "\n[Error] Current host does not support the COM block sync workflow.")
    (progn
      (setq acad-obj (nth 0 context)
            doc      (nth 1 context)
            blocks   (nth 2 context))
      (if (not (setq master-ent (car (entsel "\nSelect Master Block A: "))))
        (sb:end-command "\nCancelled.")
        (progn
          (setq master-vla (vl-catch-all-apply 'vlax-ename->vla-object (list master-ent)))
          (if (or (vl-catch-all-error-p master-vla)
                  (/= (vl-catch-all-apply 'vla-get-ObjectName (list master-vla)) "AcDbBlockReference"))
            (sb:end-command "\nNot a Block.")
            (progn
              (setq master-name (sb:get-effective-name master-ent)
                    master-def  (sb:get-block-def blocks master-name))
              (if (or (null master-name) (null master-def))
                (sb:end-command "\n[Error] Failed to resolve the master block definition.")
                (progn
                  (princ (strcat "\nMaster: " master-name))
                  (princ "\nWindow-select target Blocks: ")
                  (if (not (setq target-ss (ssget '((0 . "INSERT")))))
                    (sb:end-command "\nCancelled.")
                    (progn
                      (setq synced-count 0
                            skipped-count 0
                            i 0)
                      (while (< i (sslength target-ss))
                        (setq target-ent  (ssname target-ss i)
                              target-vla  (vlax-ename->vla-object target-ent)
                              target-name (sb:get-effective-name target-ent))
                        (cond
                          ((null target-name)
                           (setq skipped-count (1+ skipped-count))
                           (princ "\n  [Warning] Skip target: failed to resolve block name."))
                          ((= target-name master-name)
                           (setq skipped-count (1+ skipped-count))
                           (princ (strcat "\nSkip master: " target-name)))
                          ((null (setq target-def (sb:get-block-def blocks target-name)))
                           (setq skipped-count (1+ skipped-count))
                           (princ (strcat "\n  [Warning] Skip target: missing block definition -> " target-name)))
                          (t
                           (princ (strcat "\nProcessing: " target-name))
                           (setq target-stats    (sb:collect-def-stats target-def)
                                 layer-list      (nth 0 target-stats)
                                 lay-color-map   (nth 1 target-stats)
                                 t-centers       (nth 2 target-stats)
                                 objs-to-delete  (nth 4 target-stats)
                                 t-min           (nth 5 target-stats))
                           (setq master-stats     (sb:collect-master-geometry master-def layer-list)
                                 geometry-to-copy (nth 0 master-stats)
                                 m-centers        (nth 1 master-stats)
                                 hatch-count      (nth 3 master-stats)
                                 m-min            (nth 4 master-stats))
                           (princ
                             (strcat
                               "\n  Objects: "
                               (itoa (length geometry-to-copy))
                               (if (> hatch-count 0)
                                 (strcat " (+" (itoa hatch-count) " Hatch)")
                                 "")))
                           (setq final-offset (sb:vote-offset t-centers m-centers t-min m-min))
                           (if final-offset
                             (princ (strcat "\n  Offset: " (rtos (car final-offset) 2 2) "," (rtos (cadr final-offset) 2 2)))
                             (princ "\n  [Warning] No alignment found"))
                           (if (sb:apply-sync doc target-def geometry-to-copy objs-to-delete lay-color-map final-offset)
                             (setq synced-count (1+ synced-count))
                             (setq skipped-count (1+ skipped-count)))))
                        (setq i (1+ i)))
                      (setq regen-res (vl-catch-all-apply 'vla-Regen (list doc 2)))
                      (if (vl-catch-all-error-p regen-res)
                        (princ "\n  [Warning] Regen failed, but synchronization edits were already applied."))
                      (if (uc:function-defined-p 'uc:guard-end) (uc:guard-end))
                      (princ "\n=============================")
                      (princ "\nSync complete!")
                      (princ (strcat "\nSynced: " (itoa synced-count)))
                      (princ (strcat "\nSkipped: " (itoa skipped-count)))
                      (princ "\n=============================\n")
                      (princ))))))))))))

(defun c:SFM () (c:SyncNow))

(princ "\nSyncBlock loaded. Type SyncNow or SFM to run.")
(princ)
