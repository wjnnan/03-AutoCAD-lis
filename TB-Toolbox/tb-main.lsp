;;; tb-main.lsp -- TB 主入口

(if *TB:LOADED*
  (princ "\n[TB] 工具箱已加载，跳过重复加载。")
  (progn
    (setq *TB:LOADED* T
          *TB:VERSION* "1.0.0"
          *TB:PAGES* '("tb_page_0" "tb_page_1" "tb_page_2" "tb_page_3" "tb_page_4" "tb_page_5" "tb_page_6")
          *TB:TAB-KEYS* '("tab_edit" "tab_text" "tab_layer" "tab_block" "tab_dim" "tab_struct" "tab_misc")
          *TB:PAGE-BINDS* '(
    ;; 页0
    (("btn_q" . "q") ("btn_qw" . "qw") ("btn_ww" . "ww") ("btn_ty" . "ty") ("btn_qr" . "qr") ("btn_pp" . "pp") ("btn_te" . "te") ("btn_we" . "we") ("btn_a" . "a") ("btn_s" . "s") ("btn_sc" . "sc") ("btn_r" . "r") ("btn_de" . "de") ("btn_cc" . "cc") ("btn_cf" . "cf") ("btn_cr" . "cr") ("btn_cl" . "cl") ("btn_ff" . "ff") ("btn_fr" . "fr") ("btn_oo" . "oo") ("btn_mof" . "MOF") ("btn_cx" . "cx") ("btn_s1" . "s1") ("btn_s2" . "s2") ("btn_s4" . "s4") ("btn_s5" . "s5") ("btn_s0" . "s0") ("btn_s00" . "s00") ("btn_r4" . "r4") ("btn_r9" . "r9") ("btn_r5" . "r5") ("btn_r0" . "r0") ("btn_c1" . "C1") ("btn_c2" . "C2") ("btn_c3" . "C3") ("btn_c4" . "C4") ("btn_c5" . "C5") ("btn_c6" . "C6") ("btn_c7" . "C7") ("btn_c8" . "C8") ("btn_z0" . "z0") ("btn_ee" . "ee") ("btn_as" . "As") ("btn_v1" . "v1") ("btn_v2" . "v2") ("btn_v3" . "v3"))
    ;; 页1
    (("btn_tssd" . "tssd") ("btn_gts" . "gts") ("btn_ttk" . "ttk") ("btn_ttg" . "ttg") ("btn_ttr" . "ttr") ("btn_tty" . "tty") ("btn_th" . "th") ("btn_ttj" . "ttj") ("btn_ttq" . "ttq") ("btn_tjk" . "tjk") ("btn_13" . "13") ("btn_23" . "23") ("btn_31" . "31") ("btn_32" . "32"))
    ;; 页2
    (("btn_tg" . "tg") ("btn_tgf" . "tgf") ("btn_td" . "td") ("btn_tdf" . "tdf") ("btn_ts" . "ts") ("btn_tsf" . "tsf") ("btn_tdj" . "tdj") ("btn_tsj" . "tsj") ("btn_tx" . "tx") ("btn_tq" . "tq") ("btn_gtc" . "gtc"))
    ;; 页3
    (("btn_jk" . "jk") ("btn_ktj" . "ktj") ("btn_gkm" . "gkm") ("btn_gks" . "gks") ("btn_sk" . "sk") ("btn_mbo" . "MBO") ("btn_rav" . "RAV") ("btn_rblk" . "RBLK"))
    ;; 页4
    (("btn_fw" . "fw") ("btn_bbq" . "bbq") ("btn_bbf" . "bbf") ("btn_bgc" . "bgc") ("btn_ggb" . "ggb") ("btn_gbb" . "gbb") ("btn_zb" . "zb") ("btn_qb" . "qb"))
    ;; 页5
    (("btn_rb" . "RB") ("btn_rs" . "RS") ("btn_rh" . "RH") ("btn_rdh" . "RDH") ("btn_rw" . "RW") ("btn_ro" . "RO") ("btn_rl" . "RL") ("btn_rd" . "RD") ("btn_rcc" . "RCC") ("btn_rbr" . "RBR") ("btn_rbf" . "RBF") ("btn_re" . "RE") ("btn_ra" . "RA") ("btn_rn" . "RN") ("btn_rm" . "RM") ("btn_red" . "RED") ("btn_redb" . "REDB") ("btn_dk" . "dk") ("btn_dkk" . "dkk") ("btn_sg" . "sg") ("btn_tml" . "tml") ("btn_pq" . "pq") ("btn_pmh" . "pmh"))
    ;; 页6
    (("btn_rt" . "rt") ("btn_jt" . "jt") ("btn_xd" . "xd") ("btn_dx" . "dx") ("btn_dxx" . "dxx") ("btn_dd" . "dd") ("btn_ddd" . "ddd") ("btn_hgf" . "hgf") ("btn_nn" . "nn") ("btn_qq" . "qq") ("btn_sy" . "sy") ("btn_ce" . "ce") ("btn_lcd" . "lcd") ("btn_lmj" . "lmj") ("btn_qh" . "qh") ("btn_tn" . "Tn") ("btn_ss" . "ss") ("btn_bpt" . "BPT") ("btn_bpset" . "BPSET")))



          *TB:BIND-ID* 10)

(setq *TB:CMD-CATALOG* '(
  ("btn_q" "q" "直线" 0)
  ("btn_qw" "qw" "多段线" 0)
  ("btn_ww" "ww" "圆" 0)
  ("btn_ty" "ty" "椭圆" 0)
  ("btn_qr" "qr" "矩形" 0)
  ("btn_pp" "pp" "点" 0)
  ("btn_te" "te" "修剪" 0)
  ("btn_we" "we" "延伸" 0)
  ("btn_a" "a" "移动" 0)
  ("btn_s" "s" "拉伸" 0)
  ("btn_sc" "sc" "缩放" 0)
  ("btn_r" "r" "旋转" 0)
  ("btn_de" "de" "编辑" 0)
  ("btn_cc" "cc" "连续复制" 0)
  ("btn_cf" "cf" "等距复制" 0)
  ("btn_cr" "cr" "旋转复制" 0)
  ("btn_cl" "cl" "复制到层" 0)
  ("btn_ff" "ff" "零倒角" 0)
  ("btn_fr" "fr" "倒圆角" 0)
  ("btn_oo" "oo" "偏移" 0)
  ("btn_mof" "MOF" "多重偏移" 0)
  ("btn_cx" "cx" "选线修剪" 0)
  ("btn_s1" "s1" "缩放0.5×" 0)
  ("btn_s2" "s2" "缩放2×" 0)
  ("btn_s4" "s4" "缩放4×" 0)
  ("btn_s5" "s5" "缩放5×" 0)
  ("btn_s0" "s0" "缩放100×" 0)
  ("btn_s00" "s00" "缩放1000×" 0)
  ("btn_r4" "r4" "顺转45" 0)
  ("btn_r9" "r9" "顺转90" 0)
  ("btn_r5" "r5" "逆转45" 0)
  ("btn_r0" "r0" "逆转90" 0)
  ("btn_c1" "C1" "红" 0)
  ("btn_c2" "C2" "黄" 0)
  ("btn_c3" "C3" "绿" 0)
  ("btn_c4" "C4" "青" 0)
  ("btn_c5" "C5" "蓝" 0)
  ("btn_c6" "C6" "洋红" 0)
  ("btn_c7" "C7" "白" 0)
  ("btn_c8" "C8" "灰" 0)
  ("btn_z0" "z0" "Z归零" 0)
  ("btn_ee" "ee" "范围缩放" 0)
  ("btn_as" "As" "快速保存" 0)
  ("btn_v1" "v1" "单视口" 0)
  ("btn_v2" "v2" "双视口竖" 0)
  ("btn_v3" "v3" "双视口横" 0)
  ("btn_tssd" "tssd" "创建TSSD" 1)
  ("btn_gts" "gts" "改TSSD" 1)
  ("btn_ttk" "ttk" "改字宽" 1)
  ("btn_ttg" "ttg" "改字高" 1)
  ("btn_ttr" "ttr" "旋转" 1)
  ("btn_tty" "tty" "左对齐" 1)
  ("btn_th" "th" "查找替换" 1)
  ("btn_ttj" "ttj" "连接" 1)
  ("btn_ttq" "ttq" "对齐" 1)
  ("btn_tjk" "tjk" "文字加框" 1)
  ("btn_13" "13" "一级→三级" 1)
  ("btn_23" "23" "二级→三级" 1)
  ("btn_31" "31" "三级→一级" 1)
  ("btn_32" "32" "三级→二级" 1)
  ("btn_tg" "tg" "关层" 2)
  ("btn_tgf" "tgf" "反关" 2)
  ("btn_td" "td" "冻层" 2)
  ("btn_tdf" "tdf" "反冻" 2)
  ("btn_ts" "ts" "锁层" 2)
  ("btn_tsf" "tsf" "反锁" 2)
  ("btn_tdj" "tdj" "全解冻" 2)
  ("btn_tsj" "tsj" "全解锁" 2)
  ("btn_tx" "tx" "全部显示" 2)
  ("btn_tq" "tq" "切当前层" 2)
  ("btn_gtc" "gtc" "改到当前层" 2)
  ("btn_jk" "jk" "快速建块" 3)
  ("btn_ktj" "ktj" "块统计" 3)
  ("btn_gkm" "gkm" "块改名" 3)
  ("btn_gks" "gks" "改块属性" 3)
  ("btn_sk" "sk" "删重叠块" 3)
  ("btn_mbo" "MBO" "块向匹配" 3)
  ("btn_rav" "RAV" "属性取整" 3)
  ("btn_rblk" "RBLK" "批量换块" 3)
  ("btn_fw" "fw" "标注复位" 4)
  ("btn_bbq" "bbq" "标注线对齐" 4)
  ("btn_bbf" "bbf" "标注等分" 4)
  ("btn_bgc" "bgc" "标注移层" 4)
  ("btn_ggb" "ggb" "界线对齐" 4)
  ("btn_gbb" "gbb" "改标注文字" 4)
  ("btn_zb" "zb" "坐标标注" 4)
  ("btn_qb" "qb" "球标" 4)
  ("btn_rb" "RB" "画钢筋" 5)
  ("btn_rs" "RS" "画箍筋" 5)
  ("btn_rh" "RH" "加弯钩" 5)
  ("btn_rdh" "RDH" "删弯钩" 5)
  ("btn_rw" "RW" "改宽度" 5)
  ("btn_ro" "RO" "偏移钢筋" 5)
  ("btn_rl" "RL" "线变筋" 5)
  ("btn_rd" "RD" "钢筋标注" 5)
  ("btn_rcc" "RCC" "钢筋编号" 5)
  ("btn_rbr" "RBR" "板底筋" 5)
  ("btn_rbf" "RBF" "板负筋" 5)
  ("btn_re" "RE" "编辑标注" 5)
  ("btn_ra" "RA" "配筋面积" 5)
  ("btn_rn" "RN" "编号管理" 5)
  ("btn_rm" "RM" "钢筋镜像" 5)
  ("btn_red" "RED" "双击编辑" 5)
  ("btn_redb" "REDB" "双击增强" 5)
  ("btn_dk" "dk" "矩形柱" 5)
  ("btn_dkk" "dkk" "圆形柱" 5)
  ("btn_sg" "sg" "墙身缝" 5)
  ("btn_tml" "tml" "图名线" 5)
  ("btn_pq" "pq" "剖切符" 5)
  ("btn_pmh" "pmh" "平面号" 5)
  ("btn_rt" "rt" "云线" 6)
  ("btn_jt" "jt" "云线引线" 6)
  ("btn_xd" "xd" "出图比例" 6)
  ("btn_dx" "dx" "单折断线" 6)
  ("btn_dxx" "dxx" "双折断线" 6)
  ("btn_dd" "dd" "水平断点" 6)
  ("btn_ddd" "ddd" "竖直断点" 6)
  ("btn_hgf" "hgf" "焊管缝线" 6)
  ("btn_nn" "nn" "捕捉设置" 6)
  ("btn_qq" "qq" "图纸清理" 6)
  ("btn_sy" "sy" "说明标签" 6)
  ("btn_ce" "ce" "中心线" 6)
  ("btn_lcd" "lcd" "累计长度" 6)
  ("btn_lmj" "lmj" "累计面积" 6)
  ("btn_qh" "qh" "数字求和" 6)
  ("btn_tn" "Tn" "DXF查询" 6)
  ("btn_ss" "ss" "选择易" 6)
  ("btn_bpt" "BPT" "批量打印" 6)
  ("btn_bpset" "BPSET" "打印设置" 6)
))



(setq *TB:PAGE-NAMES* '("绘图编辑" "文字处理" "图层管理" "图块管理" "标注处理" "结构通用" "辅助功能"))

    (defun tb:bind (key cmd)
      "绑定 DCL 按钮到命令名。"
      (setq *TB:BIND-ID* (1+ *TB:BIND-ID*))
      (action_tile key
        (strcat
          "(progn (done_dialog " (itoa *TB:BIND-ID*) ")"
          "(setq *TB:CMD* \"" cmd "\"))")))

    (defun tb:resolve-dcl (name / dcl-fn)
      "解析 DCL 文件路径。优先用 *TB:ROOT*，避免依赖可能被 read 截断的 LOAD-PATH。"
      (setq dcl-fn (findfile name))
      (if (not dcl-fn)
        (if *TB:ROOT*
          (setq dcl-fn (strcat *TB:ROOT* "\\" name))))
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

    (defun tb:bind-tabs nil
      "绑定 7 个标签页 radio，点击时 done_dialog 200+index 触发切页。"
      (foreach i '(0 1 2 3 4 5 6)
        (action_tile (nth i *TB:TAB-KEYS*)
          (strcat "(done_dialog " (itoa (+ 200 i)) ")"))))

    (defun tb:bind-page (page-index)
      "绑定指定标签页的按钮。"
      (setq *TB:BIND-ID* 10)
      (foreach pair (nth page-index *TB:PAGE-BINDS*)
        (tb:bind (car pair) (cdr pair))))

    (defun c:TB (/ dcl-fn dcl-id result olderror)
      "打开工具箱主界面。7 个标签页通过 done_dialog 循环真正切页。"
      (setq olderror *error*
            *error* (lambda (msg)
                      (if dcl-id (vl-catch-all-apply 'unload_dialog (list dcl-id)))
                      (setq *error* olderror)
                      (princ (strcat "\n[TB] 界面异常: " (if msg msg "")))
                      (princ)))
      (setq dcl-fn (tb:resolve-dcl "tb-dcl-launcher.dcl"))
      (if (and dcl-fn (setq dcl-id (load_dialog dcl-fn)))
        (progn
          (setq *TB:CUR-PAGE* 0
                *TB:DONE* nil)
          (while (not *TB:DONE*)
            (if (new_dialog (nth *TB:CUR-PAGE* *TB:PAGES*) dcl-id)
              (progn
                (set_tile (nth *TB:CUR-PAGE* *TB:TAB-KEYS*) "1")
                (tb:bind-tabs)
                (tb:bind-page *TB:CUR-PAGE*)
                (if (uc:function-defined-p 'tb:update-page-labels)
                  (vl-catch-all-apply 'tb:update-page-labels (list *TB:CUR-PAGE*)))
                (action_tile "settings" "(done_dialog 99)")
                (action_tile "help"     "(done_dialog 100)")
                (action_tile "close"    "(done_dialog 0)")
                (setq result (start_dialog))
                (cond
                  ((>= result 200) (setq *TB:CUR-PAGE* (- result 200)))
                  ((= result 99) (c:TBSETTING2) (setq *TB:DONE* T))
                  ((= result 100) (c:TBHELP) (setq *TB:DONE* T))
                  ((= result 0) (setq *TB:DONE* T))
                  ((< result 0) (setq *TB:DONE* T)) ; ESC 取消兜底（已移除 cancel_button）
                  ((and *TB:CMD* (> result 10)) (tb:run-bound-command) (setq *TB:DONE* T))))
              (progn
                (unload_dialog dcl-id)
                (princ "\n[TB] 无法初始化主界面对话框。")
                (setq *TB:DONE* T))))
          (unload_dialog dcl-id))
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
                "(if (<= 1 (atoi (get_tile \"cloud_col\")) 255)"
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
                "(done_dialog 1))(progn (alert \"云线颜色须为 1-255\") (mode_tile \"cloud_col\" 2)))"))

            (action_tile "reset"  "(progn (sys:reset-defaults)(done_dialog 2))")
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
          "\n    TBSETTING2 快捷键设置"
          "\n    TBHELP    显示帮助"
          "\n=============================================="))
      (princ))

    (princ
      (strcat
        "\n[TB] 建筑结构工具箱 v" *TB:VERSION* " 已加载"
        "\n[TB] 命令: TB / TBSETTING / TBHELP"
        "\n[TB] 平台: " *SYS:PLATFORM*))
    (princ)))
