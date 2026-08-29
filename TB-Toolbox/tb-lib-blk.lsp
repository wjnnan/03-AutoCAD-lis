;;; tb-lib-blk.lsp -- 图块操作库
;;; 图块定义查询、块引用创建、属性管理、统计
;;; 依赖：tb-core.lsp, tb-lib-entity.lsp, tb-lib-sel.lsp

;; ============================================================================
;; 图块检测与查询
;; ============================================================================

(defun blk:exists? (name)
  "检测图块定义是否存在。"
  (cond
    ((and (uc:function-defined-p 'uc:block-exists-p) name)
     (uc:block-exists-p name))
    (t
     (and name (tblsearch "BLOCK" name) T))))

(defun blk:list nil / lst blk name
  "列出所有图块名，排除匿名块与标注块。"
  (setq lst nil
        blk nil)
  (while (setq blk (tblnext "BLOCK" (not blk)))
    (setq name (cdr (assoc 2 blk)))
    (if (and name
             (not (or (= (substr name 1 1) "*")
                      (= (substr name 1 2) "*D"))))
      (setq lst (cons name lst))))
  (reverse lst))

(defun blk:count (name)
  "统计指定图块在模型空间中的插入次数。"
  (sel:count (ssget "X" (list '(0 . "INSERT") (cons 2 name)))))

(defun blk:get-attribs (ename)
  "获取块引用的全部属性。"
  (entity:get-attribs ename))

(defun blk:set-attrib (ename tag value)
  "设置块引用的指定属性值。"
  (entity:set-attrib ename tag value))


;; ============================================================================
;; 图块创建与插入
;; ============================================================================

(defun blk:make (name ents basept)
  "创建图块定义。"
  (entity:make-block name ents basept)
  name)

(defun blk:insert (name inspt scale rot)
  "插入图块引用。"
  (entity:make-insert name inspt scale scale scale rot))

(defun blk:quick-make (ss pt / name ents)
  "快速建块并在原位插入（用 entmake，避免 command-s 不接受选择集 / _BLOCK 弹对话框）。"
  (setq name (strcat "B" (rtos (* (getvar "CDATE") 1000000.0) 2 0))
        ents (sel:to-list ss))
  (if (entity:make-block name ents pt)
    (progn
      (foreach e ents (entdel e))
      (entity:make-insert name pt 1.0 1.0 1.0 0.0)))
  name)


;; ============================================================================
;; 块参考坐标变换
;; ============================================================================

(defun blk:ref-geom (ename / elst x y z)
  "获取块引用的坐标变换参数。仅对 INSERT 实体有效。"
  (if (/= (entity:get-type ename) "INSERT")
    nil
    (progn
      (setq elst (entget ename))
  (setq z (cond ((cdr (assoc 210 elst))) (t '(0.0 0.0 1.0))))
  (setq x (trans (list (cos (cdr (assoc 50 elst)))
                       (sin (cdr (assoc 50 elst)))
                       0.0)
                 z
                 0))
  (setq y (list (- (* (cadr z) (caddr x)) (* (caddr z) (cadr x)))
                (- (* (caddr z) (car x))  (* (car z)   (caddr x)))
                (- (* (car z)   (cadr x)) (* (cadr z)  (car x)))))
  (list x
        y
        z
        (trans (cdr (assoc 10 elst)) z 0)
        (list (cdr (assoc 41 elst))
              (cdr (assoc 42 elst))
              (cdr (assoc 43 elst)))))))

(defun blk:block->insert (pt ref)
  "块定义坐标转块引用坐标。"
  (mapcar '+
    (nth 3 ref)
    (list (+ (* (caar ref)  (car pt)) (* (caadr ref)  (cadr pt)))
          (+ (* (cadar ref) (car pt)) (* (cadadr ref) (cadr pt)))
          (+ (* (caddar ref) (car pt)) (* (caddr (cadr ref)) (cadr pt))))))

(defun blk:insert->block (pt ref / vec det)
  "块引用坐标转块定义坐标。"
  (setq vec (mapcar '- pt (nth 3 ref)))
  (setq det (- (* (caar ref) (cadadr ref))
               (* (caadr ref) (cadar ref))))
  (if (equal det 0.0 1e-12)
    nil
    (list (/ (- (* (car vec) (cadadr ref))
                (* (cadr vec) (caadr ref)))
             det)
          (/ (- (* (cadr vec) (caar ref))
                (* (car vec) (cadar ref)))
             det)
          0.0)))

(defun blk:rename (old-name new-name)
  "重命名块定义。使用标准 RENAME 命令自动处理所有 INSERT 引用。"
  (if (and (blk:exists? old-name)
           new-name
           (/= new-name "")
           (not (blk:exists? new-name)))
    (progn
      (uc:command-safe (list "_.-RENAME" "BLOCK" old-name new-name))
      (if (blk:exists? new-name) new-name nil))
    nil))


(princ "\n[TB] 图块操作库加载完成 (blk:*)")
(princ)
