;;; tb-mod-block.lsp — 图块管理模块
;;; 组合 blk:* entity:* sel:* lay:* 库函数。
;;; 原文件来源：F:\结构插件\块.lsp（8命令）— 去重改写

;; ============================================================================
;; 快速建块
;; ============================================================================

(defun c:jk (/ ss pt name)
  (uc:guard-begin '())
  "快速建块：选择实体 → 指定基点 → 自动生成块名 → 原位插入。"
  (if (setq ss (ssget))
    (if (setq pt (getpoint "\n插入基点: "))
      (progn
        (setq name (blk:quick-make ss pt))
        (princ (strcat "\n块已创建: " name)))
      (princ "\n已取消（未指定插入基点）。")))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 块统计
;; ============================================================================

(defun c:ktj (/ e name count)
  (uc:guard-begin '())
  "选择一个块，统计全图同名块的数量。"
  (if (setq e (car (entsel "\n选择图块: ")))
    (if (= (entity:get-type e) "INSERT")
      (progn
        (setq name (entity:get-dxf e 2)
              count (blk:count name))
        (princ (strcat "\n块名: " name "  数量: " (itoa count))))
      (princ "\n所选不是图块。")))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 块重命名
;; ============================================================================

(defun c:gkm (/ e old-name new-name)
  (uc:guard-begin '())
  "选择图块，输入新名称重命名。"
  (if (setq e (car (entsel "\n选择要改名的图块: ")))
    (if (= (entity:get-type e) "INSERT")
      (progn
        (setq old-name (entity:get-dxf e 2))
        (setq new-name (getstring T (strcat "\n新块名（原名 " old-name "）: ")))
        (if (and new-name (/= new-name ""))
          (if (blk:rename old-name new-name)
            (princ (strcat "\n已改名: " old-name " → " new-name))
            (princ "\n改名失败（可能权限不足或新名已存在）。"))))
      (princ "\n所选不是图块。")))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 块属性编辑
;; ============================================================================

(defun c:gks (/ e atts tag new-val)
  (uc:guard-begin '())
  "修改块属性值。选择一个带属性的块，修改指定 tag 的值。"
  (if (setq e (car (nentsel "\n选择块属性: ")))
    (if (= (entity:get-type e) "ATTRIB")
      (progn
        (setq tag (entity:get-dxf e 2))
        (setq new-val (getstring T (strcat "\n" tag " 的新值 <" (entity:get-dxf e 1) ">: ")))
        (if (and new-val (/= new-val ""))
          (entity:set-dxf e 1 new-val)))
      (princ "\n所选不是属性。")))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 删除重叠块
;; ============================================================================

(defun c:sk (/ ss names positions to-del)
  (uc:guard-begin '())
  "删除位置完全重叠的同名块（保留一个）。"
  (if (setq ss (ssget '((0 . "INSERT"))))
    (progn
      (setq names (mapcar '(lambda (e) (entity:get-dxf e 2)) (sel:to-list ss))
            positions nil
            to-del (ssadd))
      ;; 遍历找出重叠块
      (sel:for-each ss
        '(lambda (e / name pt rot sx sy sz key)
           (setq name (entity:get-dxf e 2)
                 pt   (entity:get-dxf e 10)
                 rot  (entity:get-dxf e 50)
                 sx   (entity:get-dxf e 41)
                 sy   (entity:get-dxf e 42)
                 sz   (entity:get-dxf e 43)
                 key  (strcat name "|"
                              (rtos (car pt) 2 3) "|" (rtos (cadr pt) 2 3) "|" (rtos (caddr pt) 2 3) "|"
                              (rtos (if rot rot 0.0) 2 3) "|"
                              (rtos (if sx sx 1.0) 2 3) "|" (rtos (if sy sy 1.0) 2 3) "|" (rtos (if sz sz 1.0) 2 3)))
           (if (member key positions)
             (ssadd e to-del)
             (setq positions (cons key positions)))))
      ;; 删除重叠块
      (if (> (sel:count to-del) 0)
        (progn
          (command "_.ERASE" to-del "")
          (princ (strcat "\n已删除 " (itoa (sel:count to-del)) " 个重叠块。")))
        (princ "\n未发现重叠块。")))
    (princ "\n未选择任何图块。"))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 块方向匹配（吸收自 AutoCAD-LISP 项目）
;; ============================================================================

(defun c:MBO (/ ref rot ss i cnt)
  "块方向匹配：选参照块，其余所选块统一旋转到相同角度。"
  (uc:guard-begin '())
  (if (setq ref (car (entsel "\n选择参照块: ")))
    (if (= (entity:get-type ref) "INSERT")
      (progn
        (setq rot (vlax-get (vlax-ename->vla-object ref) 'Rotation))
        (if (setq ss (ssget '((0 . "INSERT"))))
          (progn
            (setq i 0 cnt 0)
            (repeat (sslength ss)
              (vl-catch-all-apply 'vla-put-rotation
                (list (vlax-ename->vla-object (ssname ss i)) rot))
              (setq i (1+ i) cnt (1+ cnt)))
            (princ (strcat "\n已将 " (itoa cnt) " 个块旋转到 "
                           (rtos (* 180.0 (/ rot pi)) 2 2) " 度。")))))
      (princ "\n所选不是图块。")))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 属性文字取整（吸收自 AutoCAD-LISP 项目）
;; ============================================================================

(defun c:RAV (/ ss i cnt en atts)
  "块属性文字取整：数字型属性统一保留 2 位小数。"
  (uc:guard-begin '())
  (if (setq ss (ssget '((0 . "INSERT"))))
    (progn
      (setq i 0 cnt 0)
      (repeat (sslength ss)
        (setq en (ssname ss i))
        (foreach pair (uc:block-attributes en)
          (if (numberp (read (cdr pair)))
            (progn
              (entity:set-attrib en (car pair) (rtos (atof (cdr pair)) 2 2))
              (setq cnt (1+ cnt)))))
        (setq i (1+ i)))
      (princ (strcat "\n已处理 " (itoa cnt) " 个属性文字。"))))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 批量换块（吸收自 AutoCAD-LISP 项目，通用化改造）
;; ============================================================================

(defun c:RBLK (/ ref new old newname ss i recs cnt ins e)
  "批量换块：把全图指定块替换为目标块，保留插入点/旋转/图层，迁移同名属性。"
  (uc:guard-begin '())
  (if (and (setq ref (car (entsel "\n选择要被替换的块: ")))
           (= (entity:get-type ref) "INSERT"))
    (progn
      (setq old (entity:get-dxf ref 2))
      (if (and (setq new (car (entsel (strcat "\n选择替换目标块 [" old "]: "))))
               (= (entity:get-type new) "INSERT"))
        (progn
          (setq newname (entity:get-dxf new 2))
          ;; 收集旧块的插入点/旋转/图层/属性
          (setq ss (ssget "X" (list '(0 . "INSERT") (cons 2 old)))
                i 0 recs nil)
          (repeat (sslength ss)
            (setq e (ssname ss i))
            (setq recs (cons (list (entity:get-dxf e 10)
                                   (or (entity:get-dxf e 50) 0.0)
                                   (entity:get-layer e)
                                   (uc:block-attributes e))
                             recs))
            (setq i (1+ i)))
          ;; 删除旧块
          (command "_.ERASE" ss "")
          ;; 插入新块并回填属性
          (setq cnt 0)
          (foreach rec recs
            (setq ins (blk:insert newname (car rec) 1.0 (cadr rec)))
            (if ins
              (progn
                (entity:set-dxf ins 8 (caddr rec))
                (foreach pair (cadddr rec)
                  (entity:set-attrib ins (car pair) (cdr pair)))
                (setq cnt (1+ cnt)))))
          (princ (strcat "\n已将 " (itoa cnt) " 个 " old " 替换为 " newname)))
        (princ "\n未选择有效的替换块。"))))
  (princ)
  (uc:guard-end))

(princ "\n[TB] 图块管理模块加载完成 (block: 8命令)")
(princ)
