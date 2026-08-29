;;; build.lsp — 建筑结构工具箱 编译脚本
;;; 用法：在 AutoCAD 命令行执行 (load "build.lsp")
;;; 功能：
;;;   1. 按依赖顺序合并所有 .lsp 源文件 → build/intermediate.lsp
;;;   2. 调用 vlisp-compile 编译 intermediate.lsp → build/toolbox.fas
;;;   3. 输出 VLISP "Make Application" 向导说明
;;;
;;; 最终产物：结构工具箱.vlx（需手动用 VLISP 向导打包 .fas + .dcl）


;; ============================================================================
;; 第一节：路径设置
;; ============================================================================

;; 通过 findfile 定位自身所在目录（确保无论从哪里加载都能找到源文件）
(setq *TB:BUILD-DIR*
  (vl-filename-directory (findfile "build.lsp")))

;; 输出目录
(setq *TB:OUTPUT-DIR* (strcat *TB:BUILD-DIR* "\\build"))

;; 创建输出目录（如果不存在）
(if (not (findfile *TB:OUTPUT-DIR*))
  (vl-mkdir *TB:OUTPUT-DIR*))

(princ (strcat "\n[Build] 源文件目录: " *TB:BUILD-DIR*))
(princ (strcat "\n[Build] 输出目录:     " *TB:OUTPUT-DIR*))


;; ============================================================================
;; 第二节：加载顺序定义
;; ============================================================================

;; 依赖规则：
;;   tb-core.lsp         — 无依赖（参数、错误、平台）
;;   tb-lib-point.lsp    — 无依赖
;;   tb-lib-curve.lsp    — 依赖 point
;;   tb-lib-sel.lsp      — 无依赖
;;   tb-lib-lay.lsp      — 无依赖
;;   tb-lib-entity.lsp   — 依赖 point, curve, lay
;;   tb-lib-txt.lsp      — 依赖 entity
;;   tb-lib-blk.lsp      — 依赖 entity
;;   tb-lib-dim.lsp      — 依赖 entity
;;   tb-lib-rebar.lsp    — 依赖 point, entity, lay
;;   各 tb-mod-*.lsp      — 依赖所有 lib（模块间无依赖）
;;   tb-main.lsp          — 依赖所有以上

(setq *TB:LOAD-ORDER*
  '(
    ;; === 统一核心（先于 tb-core，提供 uc:* 函数）===
    "..\unified-lib\uc-core.lsp"
    "..\unified-lib\uc-atlisp-adapter.lsp"
    ;; === 核心 ===
    "tb-core.lsp"
    ;; === 库（底层） ===
    "tb-lib-point.lsp"
    "tb-lib-curve.lsp"
    "tb-lib-sel.lsp"
    "tb-lib-lay.lsp"
    ;; === 库（依赖底层） ===
    "tb-lib-entity.lsp"
    "tb-lib-txt.lsp"
    "tb-lib-blk.lsp"
    "tb-lib-dim.lsp"
    "tb-lib-rebar.lsp"
    "tb-lib-rebar-edit.lsp"
    "tb-lib-struct.lsp"
    ;; === 应用模块 ===
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
    ;; === 入口 ===
    "tb-main.lsp"
    "tb-mod-hotkey.lsp"
  ))


;; ============================================================================
;; 第三节：合并源文件
;; ============================================================================

(defun build:merge (/ out-file in-file in-path line-count)
  "将 *TB:LOAD-ORDER* 中的所有源文件合并为一个 intermediate.lsp。"
  (setq out-file (strcat *TB:OUTPUT-DIR* "\\intermediate.lsp"))

  (if (setq out-fp (open out-file "w"))
    (progn
      ;; 写入文件头注释
      (write-line ";;; intermediate.lsp — 建筑结构工具箱 合并中间文件" out-fp)
      (write-line ";;; 此文件由 build.lsp 自动生成，请勿手动编辑。" out-fp)
      (write-line (strcat ";;; 生成时间: " (menucmd "M=$(edtime,$(getvar,date),YYYY-MO-DD HH:MM:SS)")) out-fp)
      (write-line "" out-fp)

      (setq line-count 0)

      (foreach src *TB:LOAD-ORDER*
        (setq in-path (strcat *TB:BUILD-DIR* "\\" src))

        (if (findfile in-path)
          (progn
            (princ (strcat "\n[Build] 合并: " src))
            (write-line (strcat "\n;;" (build:repeat-str "=" 70)) out-fp)
            (write-line (strcat ";; 源文件: " src) out-fp)
            (write-line (strcat ";;" (build:repeat-str "=" 70)) out-fp)
            (write-line "" out-fp)

            ;; 逐行复制，跳过原文件头注释
            (if (setq in-fp (open in-path "r"))
              (progn
                (while (setq line (read-line in-fp))
                  (write-line line out-fp)
                  (setq line-count (1+ line-count)))
                (close in-fp))))
          (princ (strcat "\n[Build] 警告: 找不到文件 " in-path))))

      (close out-fp)
      (princ (strcat "\n[Build] 合并完成，共 " (itoa line-count) " 行 → " out-file)))
    (princ "\n[Build] 错误: 无法创建输出文件。"))
  (princ))


(defun build:repeat-str (char count / result)
  "重复字符 char count 次。"
  (setq result "")
  (repeat count (setq result (strcat result char)))
  result)


;; ============================================================================
;; 第四节：编译为 .fas
;; ============================================================================

(defun build:compile-to-fas (/ src-file fas-file)
  "使用 vlisp-compile 将 intermediate.lsp 编译为 toolbox.fas。"
  (setq src-file (strcat *TB:OUTPUT-DIR* "\\intermediate.lsp")
        fas-file (strcat *TB:OUTPUT-DIR* "\\toolbox.fas"))

  (if (findfile src-file)
    (progn
      (princ (strcat "\n[Build] 正在编译: " src-file))
      (princ "\n[Build] 请稍候...")

      ;; vlisp-compile: 'st = standard compile
      (vlisp-compile 'st src-file fas-file)

      (if (findfile fas-file)
        (princ (strcat "\n[Build] 编译成功 → " fas-file))
        (princ "\n[Build] 编译可能失败，请检查 VLISP 窗口的错误信息。")))
    (princ "\n[Build] 错误: 找不到 intermediate.lsp，请先执行 build:merge。"))
  (princ))


;; ============================================================================
;; 第五节：打印 VLISP 打包说明
;; ============================================================================

(defun build:print-vlx-guide nil
  "打印 VLISP 向导打包 .vlx 的详细步骤。"
  (princ (strcat
    "\n"
    "\n╔══════════════════════════════════════════════════════╗"
    "\n║  .fas 编译完成！接下来打包 .vlx：                    ║"
    "\n╠══════════════════════════════════════════════════════╣"
    "\n║                                                      ║"
    "\n║  1. 在 AutoCAD 命令行输入: VLISP                      ║"
    "\n║     (打开 Visual LISP 编辑器)                         ║"
    "\n║                                                      ║"
    "\n║  2. 菜单: 文件 → 生成应用程序 → 新建应用程序向导       ║"
    "\n║     选择「专家模式」                                  ║"
    "\n║                                                      ║"
    "\n║  3. 应用程序目录: 选择 build 文件夹                    ║"
    "\n║     ( " *TB:OUTPUT-DIR* " )                            ║"
    "\n║                                                      ║"
    "\n║  4. 应用程序文件名: 结构工具箱                         ║"
    "\n║     扩展名 .vlx 自动添加                              ║"
    "\n║                                                      ║"
    "\n║  5. 添加编译后的 .fas 文件:                            ║"
    "\n║     选中 toolbox.fas → 添加                           ║"
    "\n║                                                      ║"
    "\n║  6. 添加资源 .dcl 文件（所有 DCL 都要加入）:           ║"
    "\n║     tb-dcl-launcher.dcl                              ║"
    "\n║     tb-dcl-setting.dcl                               ║"
    "\n║     tb-dcl-batchprint.dcl                            ║"
    "\n║     tb-dcl-hotkey.dcl                               ║"
    "\n║     (如果还有其他 .dcl 也一并加入)                     ║"
    "\n║                                                      ║"
    "\n║  7. 点击「编译应用程序」                              ║"
    "\n║                                                      ║"
    "\n║  8. 输出文件: 结构工具箱.vlx                           ║"
    "\n║     将此文件分发给用户即可                             ║"
    "\n║                                                      ║"
    "\n║  用户加载: (load \"结构工具箱.vlx\")                    ║"
    "\n║  启动命令: TB                                         ║"
    "\n╚══════════════════════════════════════════════════════╝"))
  (princ))


;; ============================================================================
;; 第六节：一键构建入口
;; ============================================================================

(defun c:BUILD-TB nil
  "一键执行：合并 → 编译 → 打印说明。"
  (princ "\n═════════════════════════════════════════")
  (princ "\n  建筑结构工具箱 — 编译构建")
  (princ "\n═════════════════════════════════════════")

  ;; 步骤 1：合并源文件
  (princ "\n\n[1/2] 合并源文件...")
  (build:merge)

  ;; 步骤 2：编译为 .fas
  (princ "\n\n[2/2] 编译 .fas ...")
  (build:compile-to-fas)

  ;; 步骤 3：打印打包说明
  (build:print-vlx-guide)
  (princ))


;; ============================================================================
;; 启动提示
;; ============================================================================

(princ (strcat
  "\n╔══════════════════════════════════════╗"
  "\n║   建筑结构工具箱 — 编译系统          ║"
  "\n║   命令: BUILD-TB (开始编译)          ║"
  "\n║   输出: build/toolbox.fas            ║"
  "\n╚══════════════════════════════════════╝"))
(princ)
