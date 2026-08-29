;;; tb-mod-select.lsp — 智能选择过滤模块（选择易）
;;; 组合 entity:* sel:* lay:* 库函数。
;;; 原文件来源：F:\结构插件\选择易.lsp（c:ss）— DCL + 过滤逻辑重写
;;;
;;; 核心思路：选一个样板实体 → 自动提取所有属性 → 用户勾选过滤条件 → 自动构建 ssget 过滤器

;; ============================================================================
;; DCL 对话框（内嵌字符串，加载时写入临时文件）
;; ============================================================================

(setq *TB:SELECT-DCL*
  '("select_filter:dialog{"
    "  label=\"选择易 - 智能过滤\";"
    "  :column{"
    "    :boxed_row{label=\"过滤条件\";"
    "      :column{"
    "        :toggle{label=\"实体类型\";key=\"t0\";}"
    "        :toggle{label=\"图层\";key=\"t8\";}"
    "        :toggle{label=\"颜色\";key=\"t62\";}"
    "        :toggle{label=\"线型\";key=\"t6\";}"
    "      }"
    "      :column{"
    "        :toggle{label=\"文字内容\";key=\"t1\";}"
    "        :toggle{label=\"文字样式\";key=\"t7\";}"
    "        :toggle{label=\"文字高度\";key=\"t40\";}"
    "        :toggle{label=\"块名\";key=\"t2\";}"
    "      }"
    "      :column{"
    "        :edit_box{label=\"文字包含\";key=\"text_filter\";width=20;}"
    "        :edit_box{label=\"图层名称\";key=\"layer_filter\";width=20;}"
    "        :edit_box{label=\"颜色号\";key=\"color_filter\";width=10;}"
    "      }"
    "    }"
    "    :row{"
    "      :button{label=\"应用过滤并选择\";key=\"apply\";is_default=true;}"
    "      :button{label=\"全选同类\";key=\"select_all\";}"
    "      cancel_button;"
    "    }"
    "  }"
    "}"))

;; ============================================================================
;; 选择易核心逻辑
;; ============================================================================

(defun c:ss (/ sample slent entl dcl-fn dcl-f dcl-id filter ss result
              type-toggle layer-toggle color-toggle ltype-toggle
              text-toggle style-toggle height-toggle blk-toggle
              text-filter layer-filter color-filter)
  (uc:guard-begin '())
  "智能选择过滤。选择样板实体 → 勾选过滤条件 → 自动选择匹配实体。"
  ;; 提取模板实体的所有 DXF 组码
  (initget "N")
  (setq slent (entsel "\n选择样板实体 (N-取消): "))
  (if (and slent (listp slent))
    (progn
      (setq sample (car slent)
            entl (entget sample))

      ;; 写入临时 DCL 文件
      (setq dcl-fn (strcat (getvar "TEMPPREFIX") "TB-SELECT.DCL"))
      (if (setq dcl-f (open dcl-fn "w"))
        (progn
          (foreach line *TB:SELECT-DCL* (write-line line dcl-f))
          (close dcl-f)))

      ;; 加载 DCL 并显示对话框
      (if (and (setq dcl-id (load_dialog dcl-fn))
               (new_dialog "select_filter" dcl-id))
        (progn
          ;; 显示样板实体信息
          ;; 展示样板信息到命令行（不污染 text_filter 编辑框）
          (princ (strcat "\n样板: " (entity:get-type sample)
                         "  图层: " (entity:get-layer sample)
                         "  颜色: " (itoa (abs (if (entity:get-dxf sample 62) (entity:get-dxf sample 62) 7)))))
          (set_tile "text_filter" "")
          (action_tile "apply"
            "(progn
               (setq type-toggle  (atoi (get_tile \"t0\")))
               (setq layer-toggle (atoi (get_tile \"t8\")))
               (setq color-toggle (atoi (get_tile \"t62\")))
               (setq ltype-toggle (atoi (get_tile \"t6\")))
               (setq text-toggle  (atoi (get_tile \"t1\")))
               (setq style-toggle (atoi (get_tile \"t7\")))
               (setq height-toggle (atoi (get_tile \"t40\")))
               (setq blk-toggle   (atoi (get_tile \"t2\")))
               (setq text-filter  (get_tile \"text_filter\"))
               (setq layer-filter (get_tile \"layer_filter\"))
               (setq color-filter (get_tile \"color_filter\"))
               (done_dialog 1))")
          (action_tile "select_all"
            "(progn
               (setq type-toggle 1)
               (done_dialog 2))")
          (action_tile "cancel" "(done_dialog 0)")

          ;; 显示对话框
          (setq result (start_dialog))
          (unload_dialog dcl-id)

          ;; 删除临时文件
          (vl-file-delete dcl-fn)

          ;; 构建过滤器
          (if (> result 0)
            (progn
              (setq filter (list))
              ;; 实体类型
              (if (= type-toggle 1)
                (setq filter (append filter (list (cons 0 (entity:get-type sample))))))
              ;; 图层（编辑框优先，否则用样板图层）
              (if (= layer-toggle 1)
                (setq filter (append filter (list (cons 8
                  (if (and layer-filter (/= layer-filter "")) layer-filter (entity:get-layer sample)))))))
              ;; 颜色（编辑框优先，否则用样板颜色）
              (if (= color-toggle 1)
                (setq filter (append filter (list (cons 62
                  (if (and color-filter (/= color-filter "") (numberp (atoi color-filter)))
                    (atoi color-filter)
                    (if (entity:get-dxf sample 62) (entity:get-dxf sample 62) 7)))))))
              ;; 线型
              (if (and (= ltype-toggle 1) (entity:get-dxf sample 6))
                (setq filter (append filter (list (cons 6 (entity:get-dxf sample 6))))))
              ;; 文字内容通配
              (if (and (= text-toggle 1) text-filter (/= text-filter ""))
                (setq filter (append filter (list (cons 1 (strcat "*" text-filter "*"))))))
              ;; 文字样式
              (if (and (= style-toggle 1) (entity:get-dxf sample 7))
                (setq filter (append filter (list (cons 7 (entity:get-dxf sample 7))))))
              ;; 文字高度（按样板字高过滤）
              (if (and (= height-toggle 1) (entity:get-dxf sample 40))
                (setq filter (append filter (list (cons 40 (entity:get-dxf sample 40))))))
              ;; 块名
              (if (and (= blk-toggle 1) (entity:get-dxf sample 2))
                (setq filter (append filter (list (cons 2 (entity:get-dxf sample 2))))))

              ;; 执行选择
              (if filter
                (progn
                  (setq ss (if (= result 2) (ssget "X" filter) (ssget filter)))
                  (if ss
                    (progn
                      (sssetfirst nil ss)
                      (princ (strcat "\n已选择 " (itoa (sel:count ss)) " 个匹配实体。")))
                    (princ "\n未找到匹配实体。")))
                (princ "\n未设置过滤条件。")))))))
    (princ "\n已取消。"))
  (princ)
  (uc:guard-end))


(defun c:sss (/ e filter ss)
  (uc:guard-begin '())
  "选择相似：点选样板对象，全图选择所有相似实体（同类型+同图层+同块名/样式）。"
  (if (setq e (car (entsel "\n选择样板对象: ")))
    (progn
      (setq filter (list (cons 0 (entity:get-type e))
                         (cons 8 (entity:get-layer e))))
      ;; 块名（INSERT）
      (if (and (= (entity:get-type e) "INSERT") (entity:get-dxf e 2))
        (setq filter (append filter (list (cons 2 (entity:get-dxf e 2))))))
      ;; 文字样式（TEXT/MTEXT）
      (if (and (wcmatch (entity:get-type e) "TEXT,MTEXT") (entity:get-dxf e 7))
        (setq filter (append filter (list (cons 7 (entity:get-dxf e 7))))))
      ;; 全图选择
      (setq ss (ssget "X" filter))
      (if ss
        (progn
          (sssetfirst nil ss)
          (princ (strcat "\n已选择 " (itoa (sel:count ss)) " 个相似实体。")))
        (princ "\n未找到相似实体。"))))
  (princ)
  (uc:guard-end))

(princ "\n[TB] 智能选择过滤模块加载完成 (select: 2命令)")
(princ)
