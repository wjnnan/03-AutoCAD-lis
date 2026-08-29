;;; acaddoc.lsp - TB-Toolbox 自动加载（动态定位，不写绝对路径）
;;; 放置：加入 AutoCAD 支持文件搜索路径（OPTIONS > 文件 > 支持文件搜索路径），
;;;       或放在与 TB-Toolbox 同仓库根目录下。
;;;
;;; 定位顺序（全基于 findfile / getenv，无绝对路径）：
;;;   1. 环境变量 TB_TOOLBOX      -> 推荐：路径集中维护，TB-Toolbox 任意位置
;;;   2. findfile "tb-core.lsp"   -> TB-Toolbox 目录已在支持路径
;;;   3. findfile "load.lsp"      -> load.lsp 已在支持路径
;;;   4. findfile "acaddoc.lsp"   -> 本文件与 TB-Toolbox 同仓库根

;; 1. 环境变量锚点（推荐）
(if (and (not *TB:PATH*) (getenv "TB_TOOLBOX"))
  (setq *TB:PATH* (getenv "TB_TOOLBOX")))

;; 2. 支持路径锚点：tb-core.lsp
(if (and (not *TB:PATH*) (setq *TB:ANCHOR* (findfile "tb-core.lsp")))
  (setq *TB:PATH* (vl-filename-directory *TB:ANCHOR*)))

;; 3. 支持路径锚点：load.lsp
(if (and (not *TB:PATH*) (setq *TB:ANCHOR* (findfile "load.lsp")))
  (setq *TB:PATH* (vl-filename-directory *TB:ANCHOR*)))

;; 4. 与 acaddoc.lsp 同仓库根（acaddoc.lsp 需在支持路径）
(if (and (not *TB:PATH*) (setq *TB:ADOC* (findfile "acaddoc.lsp")))
  (progn
    (setq *TB:ROOT2* (vl-filename-directory *TB:ADOC*))
    (if (findfile (strcat *TB:ROOT2* "/TB-Toolbox/tb-core.lsp"))
      (setq *TB:PATH* (strcat *TB:ROOT2* "/TB-Toolbox")))))

(setq *TB:ANCHOR* nil *TB:ADOC* nil *TB:ROOT2* nil)

(if *TB:PATH*
  (progn
    ;; 统一用正斜杠拼接，兼容环境变量带/不带尾部反斜杠
    (load (strcat (vl-string-right-trim "/\\" *TB:PATH*) "/load.lsp"))
    (princ "\n[acaddoc] TB-Toolbox 已加载"))
  (princ "\n[acaddoc] 未定位 TB-Toolbox：请设置环境变量 TB_TOOLBOX，或将 TB-Toolbox 加入支持路径"))
(princ)
