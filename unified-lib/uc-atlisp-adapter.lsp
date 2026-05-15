;;; uc-atlisp-adapter.lsp -- atlisp 适配层
;;; 负责：按需加载低依赖函数，并向统一核心暴露稳定包装

(defun uc:atlisp-root nil
  "返回 atlisp-lib 根目录。"
  (if (uc:project-root)
    (uc:path-join (uc:project-root) "atlisp-lib")
    nil))

(defun uc:atlisp-file (relative)
  "返回 atlisp-lib 下文件的绝对路径。"
  (if (uc:atlisp-root)
    (uc:path-join (uc:atlisp-root) relative)
    nil))

(defun uc:load-atlisp-file (relative / path)
  "按需加载 atlisp 文件。"
  (setq path (uc:atlisp-file relative))
  (if (uc:file-loadable-p path)
    (load path)
    nil))

(defun uc:ensure-atlisp-minimum nil
  "加载本轮低依赖 atlisp 函数。"
  (if (not (uc:function-defined-p 'point:mid))
    (uc:load-atlisp-file "src\\point\\mid.lsp"))
  T)

(defun uc:midpoint (pt1 pt2)
  "统一中点函数。"
  (uc:ensure-atlisp-minimum)
  (if (uc:function-defined-p 'point:mid)
    (point:mid pt1 pt2)
    (mapcar '(lambda (a b) (* 0.5 (+ a b))) pt1 pt2)))

(princ "\n[UC] atlisp 适配层已加载")
(princ)
