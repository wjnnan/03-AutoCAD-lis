;;; load.lsp -- TB-Toolbox 统一加载入口

(defun tb:resolve-root (/ found)
  "定位工具箱目录。"
  (cond
    (*TB:PATH* *TB:PATH*)
    ((and *UC:ROOT* (findfile (strcat *UC:ROOT* "\\TB-Toolbox\\tb-core.lsp")))
     (strcat *UC:ROOT* "\\TB-Toolbox"))
    ((setq found (findfile "tb-core.lsp"))
     (vl-filename-directory found))
    (t nil)))

(setq *TB:ROOT* (tb:resolve-root))

(if (not *TB:ROOT*)
  (progn
    (princ "\n[TB] 无法自动定位工具箱目录。")
    (princ "\n[TB] 请先设置 *TB:PATH*，或将 TB-Toolbox 加入支持文件搜索路径。")
    (princ))
  (progn
    ;; 统一核心按仓库根目录加载
    (setq *UC:ROOT* (vl-filename-directory *TB:ROOT*))

    (setq *TB:FILES*
      '(
        "..\\unified-lib\\uc-core.lsp"
        "..\\unified-lib\\uc-atlisp-adapter.lsp"
        "tb-core.lsp"
        "tb-lib-point.lsp"
        "tb-lib-curve.lsp"
        "tb-lib-sel.lsp"
        "tb-lib-lay.lsp"
        "tb-lib-entity.lsp"
        "tb-lib-txt.lsp"
        "tb-lib-blk.lsp"
        "tb-lib-dim.lsp"
        "tb-lib-rebar.lsp"
        "tb-lib-rebar-edit.lsp"
        "tb-mod-edit.lsp"
        "tb-mod-text.lsp"
        "tb-mod-dim.lsp"
        "tb-mod-layer.lsp"
        "tb-mod-block.lsp"
        "tb-mod-cloud.lsp"
        "tb-mod-select.lsp"
        "tb-mod-centerline.lsp"
        "tb-mod-beam.lsp"
        "tb-mod-column.lsp"
        "tb-mod-bubble.lsp"
        "tb-mod-misc.lsp"
        "tb-mod-calc.lsp"
        "tb-mod-rebar.lsp"
        "tb-mod-rebar-edit.lsp"
        "tb-mod-batchprint.lsp"
        "tb-main.lsp"
      ))

    (princ (strcat "\n[TB] 工具箱目录: " *TB:ROOT*))
    (setq *TB:OK* 0
          *TB:FAIL* 0)

    (foreach fname *TB:FILES*
      (setq fpath
        (if (= (substr fname 1 3) "..\\")
          (strcat *UC:ROOT* "\\" (substr fname 4))
          (strcat *TB:ROOT* "\\" fname)))
      (if (findfile fpath)
        (progn
          (princ (strcat "\n[TB] 加载: " fname))
          (if (vl-catch-all-error-p
                (setq *TB:LOAD-ERR*
                  (vl-catch-all-apply 'load (list fpath))))
            (progn
              (princ (strcat " -> 失败: " (vl-catch-all-error-message *TB:LOAD-ERR*)))
              (setq *TB:FAIL* (1+ *TB:FAIL*)))
            (setq *TB:OK* (1+ *TB:OK*))))
        (progn
          (princ (strcat "\n[TB] 缺失文件: " fpath))
          (setq *TB:FAIL* (1+ *TB:FAIL*)))))

    (princ
      (strcat
        "\n[TB] 加载完成: "
        (itoa *TB:OK*)
        " 成功"
        (if (> *TB:FAIL* 0)
          (strcat " / " (itoa *TB:FAIL*) " 失败")
          "")))

    (setq *TB:FILES* nil
          *TB:OK* nil
          *TB:FAIL* nil
          *TB:LOAD-ERR* nil
          fname nil
          fpath nil)

    (princ)))
