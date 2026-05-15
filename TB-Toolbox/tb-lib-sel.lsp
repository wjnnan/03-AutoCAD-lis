;;; tb-lib-sel.lsp -- 选择集操作库
;;; 封装 ssget 常用操作，统一转为 ename 列表处理。
;;; 依赖：tb-core.lsp，unified-lib/uc-core.lsp

(defun sel:by-layer (layname / ss)
  "选择指定图层上的所有实体。"
  (ssget "X" (list (cons 8 layname))))

(defun sel:by-type (ent-type / ss)
  "选择指定类型的所有实体。"
  (ssget "X" (list (cons 0 ent-type))))

(defun sel:filter (alist)
  "按 DXF 过滤表选择实体。"
  (ssget "X" alist))

(defun sel:pick (prompt filter)
  "交互选择实体。"
  (princ (strcat "\n" prompt))
  (ssget filter))

(defun sel:to-list (ss / i lst)
  "将选择集转换为实体列表。"
  (uc:pickset->list ss))

(defun sel:for-each (ss callback)
  "遍历选择集中的所有实体。"
  (if ss
    (mapcar callback (sel:to-list ss))))

(defun sel:count (ss)
  "返回选择集中元素的数量。"
  (if ss (sslength ss) 0))

(defun sel:add (ss ename)
  "向选择集中添加一个实体。"
  (ssadd ename ss))

(defun sel:delete (ss ename)
  "从选择集中删除一个实体。"
  (ssdel ename ss))

(princ "\n[TB] 选择集操作库加载完成 (sel:*)")
(princ)
