;; compile.lsp — 调用 vlisp-compile 把 intermediate.lsp 编译为 toolbox.fas
;; 由「一键编译.bat」加载；也可在 AutoCAD 里手动 (load "compile.lsp")
;;
;; *b:dir* 由 compile.scr 预先设置；此处仅在未设置时兜底。
(if (not *b:dir*)
  (setq *b:dir* "D:/My Code/Claude Code/03-AutoCAD-lisp/TB-Toolbox/build"))
(setq *b:src* (strcat *b:dir* "/intermediate.lsp")
      *b:fas* (strcat *b:dir* "/toolbox.fas"))
(princ (strcat "\n[Compile] 源文件: " *b:src*))
(princ (strcat "\n[Compile] 目标:   " *b:fas*))
(if (not (findfile *b:src*))
  (princ "\n[Compile] 错误: 找不到 intermediate.lsp，请先执行合并步骤。")
  (progn
    (princ "\n[Compile] 正在编译，请稍候...")
    (princ (strcat "\n[Compile] 返回: "
      (vl-princ-to-string
        (vl-catch-all-apply 'vlisp-compile (list 'st *b:src* *b:fas*)))))
    (if (findfile *b:fas*)
      (princ (strcat "\n[Compile] 编译成功 -> " *b:fas*))
      (princ "\n[Compile] 编译失败，请在 VLISP 窗口查看错误。"))))
(princ)
