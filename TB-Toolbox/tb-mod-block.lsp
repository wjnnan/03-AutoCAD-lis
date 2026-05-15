;;; tb-mod-block.lsp — 图块管理模块
;;; 组合 blk:* entity:* sel:* lay:* 库函数。
;;; 原文件来源：F:\结构插件\块.lsp（8命令）— 去重改写

;; ============================================================================
;; 快速建块
;; ============================================================================

(defun c:jk (/ ss pt name)
  "快速建块：选择实体 → 指定基点 → 自动生成块名 → 原位插入。"
  (if (setq ss (ssget))
    (if (setq pt (getpoint "\n插入基点: "))
      (progn
        (setq name (blk:quick-make ss pt))
        (princ (strcat "\n块已创建: " name)))
      (princ "\n已取消（未指定插入基点）。")))
  (princ))


;; ============================================================================
;; 块统计
;; ============================================================================

(defun c:ktj (/ e name count)
  "选择一个块，统计全图同名块的数量。"
  (if (setq e (car (entsel "\n选择图块: ")))
    (if (= (entity:get-type e) "INSERT")
      (progn
        (setq name (entity:get-dxf e 2)
              count (blk:count name))
        (princ (strcat "\n块名: " name "  数量: " (itoa count))))
      (princ "\n所选不是图块。")))
  (princ))


;; ============================================================================
;; 块重命名
;; ============================================================================

(defun c:gkm (/ e old-name new-name)
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
  (princ))


;; ============================================================================
;; 块属性编辑
;; ============================================================================

(defun c:gks (/ e atts tag new-val)
  "修改块属性值。选择一个带属性的块，修改指定 tag 的值。"
  (if (setq e (car (nentsel "\n选择块属性: ")))
    (if (= (entity:get-type e) "ATTRIB")
      (progn
        (setq tag (entity:get-dxf e 2))
        (setq new-val (getstring T (strcat "\n" tag " 的新值 <" (entity:get-dxf e 1) ">: ")))
        (if (and new-val (/= new-val ""))
          (entity:set-dxf e 1 new-val)))
      (princ "\n所选不是属性。")))
  (princ))


;; ============================================================================
;; 删除重叠块
;; ============================================================================

(defun c:sk (/ ss names positions to-del)
  "删除位置完全重叠的同名块（保留一个）。"
  (if (setq ss (ssget '((0 . "INSERT"))))
    (progn
      (setq names (mapcar '(lambda (e) (entity:get-dxf e 2)) (sel:to-list ss))
            positions nil
            to-del (ssadd))
      ;; 遍历找出重叠块
      (sel:for-each ss
        '(lambda (e / name pt key)
           (setq name (entity:get-dxf e 2)
                 pt   (entity:get-dxf e 10)
                 key  (strcat name "|" (rtos (car pt) 2 3) "|" (rtos (cadr pt) 2 3)))
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
  (princ))


(princ "\n[TB] 图块管理模块加载完成 (block: 5命令)")
(princ)
