;;; tb-main.lsp -- TB 主入口

(if *TB:LOADED*
  (princ "\n[TB] 工具箱已加载，跳过重复加载。")
  (progn
    (setq *TB:LOADED* T
          *TB:VERSION* "1.0.0"
          *TB:TAB-GROUPS* '("grp_edit1" "grp_text" "grp_layer" "grp_rebar" "grp_struct" "grp_misc")
          *TB:BIND-ID* 10)

    (defun tb:switch-tab (active-group)
      "切换工具箱标签页。"
      (foreach g *TB:TAB-GROUPS*
        (mode_tile g (if (= g active-group) 0 1))))

    (defun tb:bind (key cmd)
      "绑定 DCL 按钮到命令名。"
      (setq *TB:BIND-ID* (1+ *TB:BIND-ID*))
      (action_tile key
        (strcat
          "(progn (done_dialog " (itoa *TB:BIND-ID*) ")"
          "(setq *TB:CMD* \"" cmd "\"))")))

    (defun tb:resolve-dcl (name / dcl-fn)
      "解析 DCL 文件路径。"
      (setq dcl-fn (findfile name))
      (if (not dcl-fn)
        (if (sys:get '*SYS:LOAD-PATH*)
          (setq dcl-fn (uc:path-join (sys:get '*SYS:LOAD-PATH*) name))))
      dcl-fn)

    (defun tb:run-bound-command (/ cmd-sym)
      "执行按钮绑定的命令。"
      (if *TB:CMD*
        (progn
          (setq cmd-sym (read (strcat "c:" (strcase *TB:CMD*))))
          (if (uc:command-defined-p cmd-sym)
            (uc:call-command cmd-sym)
            (princ (strcat "\n[TB] 未定义命令: " *TB:CMD*)))
          (setq *TB:CMD* nil))))

    (defun c:TB (/ dcl-fn dcl-id result olderror)
      "打开工具箱主界面。带错误保护确保 DCL 资源释放。"
      (setq olderror *error*
            *error* (lambda (msg)
                      (if dcl-id (vl-catch-all-apply 'unload_dialog (list dcl-id)))
                      (setq *error* olderror)
                      (princ (strcat "\n[TB] 界面异常: " (if msg msg "")))
                      (princ)))
      (setq dcl-fn (tb:resolve-dcl "tb-dcl-launcher.dcl"))
      (if (and dcl-fn (setq dcl-id (load_dialog dcl-fn)))
        (if (new_dialog "tb_launcher" dcl-id)
          (progn
            (set_tile "tab_edit" "1")
            (tb:switch-tab "grp_edit1")

            (action_tile "tab_edit"   "(tb:switch-tab \"grp_edit1\")")
            (action_tile "tab_text"   "(tb:switch-tab \"grp_text\")")
            (action_tile "tab_layer"  "(tb:switch-tab \"grp_layer\")")
            (action_tile "tab_rebar"  "(tb:switch-tab \"grp_rebar\")")
            (action_tile "tab_struct" "(tb:switch-tab \"grp_struct\")")
            (action_tile "tab_misc"   "(tb:switch-tab \"grp_misc\")")

            (setq *TB:BIND-ID* 10)

            (tb:bind "btn_q"  "q")
            (tb:bind "btn_qw" "qw")
            (tb:bind "btn_ww" "ww")
            (tb:bind "btn_qr" "qr")
            (tb:bind "btn_te" "te")
            (tb:bind "btn_we" "we")
            (tb:bind "btn_a"  "a")
            (tb:bind "btn_s"  "s")
            (tb:bind "btn_sc" "sc")
            (tb:bind "btn_r"  "r")
            (tb:bind "btn_ff" "ff")
            (tb:bind "btn_fr" "fr")
            (tb:bind "btn_cc" "cc")
            (tb:bind "btn_cf" "cf")
            (tb:bind "btn_oo" "oo")
            (tb:bind "btn_z0" "z0")

            (tb:bind "btn_tssd" "tssd")
            (tb:bind "btn_gts"  "gts")
            (tb:bind "btn_ttk"  "ttk")
            (tb:bind "btn_ttg"  "ttg")
            (tb:bind "btn_th"   "th")
            (tb:bind "btn_tjk"  "tjk")
            (tb:bind "btn_fw"   "fw")
            (tb:bind "btn_bbf"  "bbf")
            (tb:bind "btn_zb"   "zb")

            (tb:bind "btn_tg"  "tg")
            (tb:bind "btn_tgf" "tgf")
            (tb:bind "btn_td"  "td")
            (tb:bind "btn_tdf" "tdf")
            (tb:bind "btn_ts"  "ts")
            (tb:bind "btn_tdj" "tdj")
            (tb:bind "btn_jk"  "jk")
            (tb:bind "btn_ktj" "ktj")
            (tb:bind "btn_gkm" "gkm")

            (tb:bind "btn_rb"  "rb")
            (tb:bind "btn_rs"  "rs")
            (tb:bind "btn_rh"  "rh")
            (tb:bind "btn_rdh" "rdh")
            (tb:bind "btn_rw"  "rw")
            (tb:bind "btn_ro"  "ro")
            (tb:bind "btn_rl"  "rl")
            (tb:bind "btn_rd"  "rd")
            (tb:bind "btn_rcc" "rcc")
            (tb:bind "btn_rbr" "rbr")
            (tb:bind "btn_rbf" "rbf")
            (tb:bind "btn_re"  "re")
            (tb:bind "btn_ra"  "ra")
            (tb:bind "btn_rn"  "rn")
            (tb:bind "btn_rm"  "rm")
            (tb:bind "btn_red" "red")

            (tb:bind "btn_dk"  "dk")
            (tb:bind "btn_dkk" "dkk")
            (tb:bind "btn_sg"  "sg")
            (tb:bind "btn_tml" "tml")
            (tb:bind "btn_pq"  "pq")
            (tb:bind "btn_pmh" "pmh")
            (tb:bind "btn_dx"  "dx")
            (tb:bind "btn_rt"  "rt")
            (tb:bind "btn_ce"  "ce")

            (tb:bind "btn_ss"  "ss")
            (tb:bind "btn_qb"  "qb")
            (tb:bind "btn_nn"  "nn")
            (tb:bind "btn_lcd" "lcd")
            (tb:bind "btn_lmj" "lmj")
            (tb:bind "btn_qh"  "qh")
            (tb:bind "btn_13"  "13")
            (tb:bind "btn_23"  "23")
            (tb:bind "btn_tn"  "Tn")
            (tb:bind "btn_bpt" "bpt")

            (action_tile "settings" "(done_dialog 99)")
            (action_tile "help"     "(done_dialog 100)")
            (action_tile "close"    "(done_dialog 0)")
            (action_tile "cancel"   "(done_dialog 0)")

            (setq result (start_dialog))
            (unload_dialog dcl-id)

            (cond
              ((= result 99) (c:TBSETTING))
              ((= result 100) (c:TBHELP))
              ((= result 0)   (setq *TB:CMD* nil))
              ((and *TB:CMD* (> result 10))
               (tb:run-bound-command))))
          (progn
            (unload_dialog dcl-id)
            (princ "\n[TB] 无法初始化主界面对话框。")))
        (princ "\n[TB] 找不到主界面 DCL 文件。"))
      (setq *error* olderror)
      (princ))

    (defun c:TBSETTING (/ dcl-fn dcl-id result olderror)
      "打开系统设置对话框。带错误保护确保 DCL 资源释放。"
      (setq olderror *error*
            *error* (lambda (msg)
                      (if dcl-id (vl-catch-all-apply 'unload_dialog (list dcl-id)))
                      (setq *error* olderror)
                      (princ (strcat "\n[TB] 设置界面异常: " (if msg msg "")))
                      (princ)))
      (setq dcl-fn (tb:resolve-dcl "tb-dcl-setting.dcl"))
      (if (and dcl-fn (setq dcl-id (load_dialog dcl-fn)))
        (if (new_dialog "tb_settings" dcl-id)
          (progn
            (set_tile "scale"     (itoa (sys:get '*SYS:DWG-SCALE*)))
            (set_tile "text_h"    (itoa (sys:get '*SYS:TEXT-HEIGHT*)))
            (set_tile "style"     (sys:get '*SYS:TEXT-STYLE*))
            (set_tile "font"      (sys:get '*SYS:TEXT-FONT*))
            (set_tile "bigfont"   (sys:get '*SYS:TEXT-BIGFONT*))
            (set_tile "width"     (rtos (sys:get '*SYS:TEXT-WIDTH*) 2 2))
            (set_tile "beam_lay"  (sys:get '*PRJ:BEAM-LAYER*))
            (set_tile "col_lay"   (sys:get '*PRJ:COLUMN-LAYER*))
            (set_tile "wall_lay"  (sys:get '*PRJ:WALL-LAYER*))
            (set_tile "text_lay"  (sys:get '*PRJ:TEXT-LAYER*))
            (set_tile "dim_lay"   (sys:get '*PRJ:DIM-LAYER*))
            (set_tile "cloud_lay" (sys:get '*SYS:CLOUD-LAYER*))
            (set_tile "cloud_col" (itoa (sys:get '*SYS:CLOUD-COLOR*)))
            (set_tile "cloud_arc" (itoa (sys:get '*SYS:CLOUD-ARC*)))

            (action_tile "save"
              (strcat
                "(progn"
                "(sys:set '*SYS:DWG-SCALE*    (atoi (get_tile \"scale\")))"
                "(sys:set '*SYS:TEXT-HEIGHT*  (atoi (get_tile \"text_h\")))"
                "(sys:set '*SYS:TEXT-STYLE*   (get_tile \"style\"))"
                "(sys:set '*SYS:TEXT-FONT*    (get_tile \"font\"))"
                "(sys:set '*SYS:TEXT-BIGFONT* (get_tile \"bigfont\"))"
                "(sys:set '*SYS:TEXT-WIDTH*   (atof (get_tile \"width\")))"
                "(sys:set '*PRJ:BEAM-LAYER*   (get_tile \"beam_lay\"))"
                "(sys:set '*PRJ:COLUMN-LAYER* (get_tile \"col_lay\"))"
                "(sys:set '*PRJ:WALL-LAYER*   (get_tile \"wall_lay\"))"
                "(sys:set '*PRJ:TEXT-LAYER*   (get_tile \"text_lay\"))"
                "(sys:set '*PRJ:DIM-LAYER*    (get_tile \"dim_lay\"))"
                "(sys:set '*SYS:CLOUD-LAYER*  (get_tile \"cloud_lay\"))"
                "(sys:set '*SYS:CLOUD-COLOR*  (atoi (get_tile \"cloud_col\")))"
                "(sys:set '*SYS:CLOUD-ARC*    (atoi (get_tile \"cloud_arc\")))"
                "(done_dialog 1))"))

            (action_tile "reset"  "(progn (sys:init-defaults)(done_dialog 2))")
            (action_tile "cancel" "(done_dialog 0)")

            (setq result (start_dialog))
            (unload_dialog dcl-id)

            (cond
              ((= result 1) (princ "\n设置已保存。"))
              ((= result 2) (princ "\n已恢复默认设置。"))))
          (progn
            (unload_dialog dcl-id)
            (princ "\n[TB] 无法初始化设置对话框。"))))
      (setq *error* olderror)
      (princ))

    (defun c:TBHELP ()
      "显示帮助信息。"
      (princ
        (strcat
          "\n=============================================="
          "\n  建筑结构工具箱 v" *TB:VERSION*
          "\n  平台: " *SYS:PLATFORM*
          "\n=============================================="
          "\n  命令:"
          "\n    TB        打开主界面"
          "\n    TBSETTING 打开设置"
          "\n    TBHELP    显示帮助"
          "\n=============================================="))
      (princ))

    (princ
      (strcat
        "\n[TB] 建筑结构工具箱 v" *TB:VERSION* " 已加载"
        "\n[TB] 命令: TB / TBSETTING / TBHELP"
        "\n[TB] 平台: " *SYS:PLATFORM*))
    (princ)))
