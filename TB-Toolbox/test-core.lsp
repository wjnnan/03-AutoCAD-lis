;;; test-core.lsp — 核心系统加载测试
;;; 复用 tb-core.lsp，不再复制函数，避免与 tb-core 重复定义。

;; 加载核心系统（tb-core 内部会执行平台检测、配置加载、默认值初始化）
(load "tb-core.lsp")

;; 验证核心已加载
(princ "\n[TB] Test core 验证:")
(princ (strcat "\n  平台: " *SYS:PLATFORM*
               "\n  绘图比例: " (vl-princ-to-string (sys:get '*SYS:DWG-SCALE*))))

(princ "\n[TB] Test core loaded OK.")
(princ)
