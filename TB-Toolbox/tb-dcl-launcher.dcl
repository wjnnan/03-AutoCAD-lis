// tb-dcl-launcher.dcl — 建筑结构工具箱主界面
// 选项卡 + 按钮网格布局

tb_launcher:dialog{
  label="建筑结构工具箱 v1.0";
  initial_focus="tab_edit";

  // === 选项卡切换 ===
  :boxed_radio_row{
    key="tabs";
    :radio_button{label="绘图编辑";key="tab_edit";}
    :radio_button{label="文字标注";key="tab_text";}
    :radio_button{label="图层图块";key="tab_layer";}
    :radio_button{label="钢筋工具";key="tab_rebar";}
    :radio_button{label="结构工具";key="tab_struct";}
    :radio_button{label="其他工具";key="tab_misc";}
  }

  // === 绘图编辑 标签页 ===
  :boxed_row{label="绘图命令";key="grp_edit1";
    :row{
      :column{
        :button{label="直线 Q";key="btn_q";width=12;fixed_width=true;}
        :button{label="修剪 TE";key="btn_te";width=12;fixed_width=true;}
        :button{label="零倒角 FF";key="btn_ff";width=12;fixed_width=true;}
        :button{label="连续复制 CC";key="btn_cc";width=12;fixed_width=true;}
      }
      :column{
        :button{label="多段线 QW";key="btn_qw";width=12;fixed_width=true;}
        :button{label="延伸 WE";key="btn_we";width=12;fixed_width=true;}
        :button{label="倒圆角 FR";key="btn_fr";width=12;fixed_width=true;}
        :button{label="等距复制 CF";key="btn_cf";width=12;fixed_width=true;}
      }
      :column{
        :button{label="圆 WW";key="btn_ww";width=12;fixed_width=true;}
        :button{label="移动 A";key="btn_a";width=12;fixed_width=true;}
        :button{label="缩放 SC";key="btn_sc";width=12;fixed_width=true;}
        :button{label="偏移 OO";key="btn_oo";width=12;fixed_width=true;}
      }
      :column{
        :button{label="矩形 QR";key="btn_qr";width=12;fixed_width=true;}
        :button{label="拉伸 S";key="btn_s";width=12;fixed_width=true;}
        :button{label="旋转 R";key="btn_r";width=12;fixed_width=true;}
        :button{label="Z归零 Z0";key="btn_z0";width=12;fixed_width=true;}
      }
    }
  }

  // === 文字标注 标签页 ===
  :boxed_row{label="文字标注";key="grp_text";
    :row{
      :column{
        :button{label="TSSD样式 TSSD";key="btn_tssd";width=12;fixed_width=true;}
        :button{label="改宽度 TTK";key="btn_ttk";width=12;fixed_width=true;}
        :button{label="查找替换 TH";key="btn_th";width=12;fixed_width=true;}
      }
      :column{
        :button{label="改TSSD GTS";key="btn_gts";width=12;fixed_width=true;}
        :button{label="改高度 TTG";key="btn_ttg";width=12;fixed_width=true;}
        :button{label="文字加框 TJK";key="btn_tjk";width=12;fixed_width=true;}
      }
      :column{
        :button{label="标注复位 FW";key="btn_fw";width=12;fixed_width=true;}
        :button{label="标注等分 BBF";key="btn_bbf";width=12;fixed_width=true;}
        :button{label="坐标标注 ZB";key="btn_zb";width=12;fixed_width=true;}
      }
    }
  }

  // === 图层图块 标签页 ===
  :boxed_row{label="图层图块";key="grp_layer";
    :row{
      :column{
        :button{label="关层 TG";key="btn_tg";width=12;fixed_width=true;}
        :button{label="冻层 TD";key="btn_td";width=12;fixed_width=true;}
        :button{label="锁层 TS";key="btn_ts";width=12;fixed_width=true;}
      }
      :column{
        :button{label="反关 TGF";key="btn_tgf";width=12;fixed_width=true;}
        :button{label="反冻 TDF";key="btn_tdf";width=12;fixed_width=true;}
        :button{label="全解冻 TDJ";key="btn_tdj";width=12;fixed_width=true;}
      }
      :column{
        :button{label="快速建块 JK";key="btn_jk";width=12;fixed_width=true;}
        :button{label="块统计 KTJ";key="btn_ktj";width=12;fixed_width=true;}
        :button{label="块改名 GKM";key="btn_gkm";width=12;fixed_width=true;}
      }
    }
  }

  // === 钢筋工具 标签页 ===
  :boxed_row{label="钢筋工具";key="grp_rebar";
    :row{
      :column{
        :button{label="画钢筋 RB";key="btn_rb";width=12;fixed_width=true;}
        :button{label="加弯钩 RH";key="btn_rh";width=12;fixed_width=true;}
        :button{label="删弯钩 RDH";key="btn_rdh";width=12;fixed_width=true;}
      }
      :column{
        :button{label="画箍筋 RS";key="btn_rs";width=12;fixed_width=true;}
        :button{label="改宽度 RW";key="btn_rw";width=12;fixed_width=true;}
        :button{label="线变筋 RL";key="btn_rl";width=12;fixed_width=true;}
      }
      :column{
        :button{label="板底筋 RBR";key="btn_rbr";width=12;fixed_width=true;}
        :button{label="板负筋 RBF";key="btn_rbf";width=12;fixed_width=true;}
        :button{label="钢筋偏移 RO";key="btn_ro";width=12;fixed_width=true;}
      }
      :column{
        :button{label="钢筋标注 RD";key="btn_rd";width=12;fixed_width=true;}
        :button{label="钢筋编号 RCC";key="btn_rcc";width=12;fixed_width=true;}
      }
    }
    :row{
      :column{
        :button{label="编辑标注 RE";key="btn_re";width=12;fixed_width=true;}
        :button{label="实时面积 RA";key="btn_ra";width=12;fixed_width=true;}
      }
      :column{
        :button{label="钢筋镜像 RM";key="btn_rm";width=12;fixed_width=true;}
        :button{label="编号管理 RN";key="btn_rn";width=12;fixed_width=true;}
      }
      :column{
        :button{label="双击编辑 RED";key="btn_red";width=12;fixed_width=true;}
      }
    }
  }

  // === 结构工具 标签页 ===
  :boxed_row{label="结构工具";key="grp_struct";
    :row{
      :column{
        :button{label="柱截面 DK";key="btn_dk";width=12;fixed_width=true;}
        :button{label="图名线 TML";key="btn_tml";width=12;fixed_width=true;}
        :button{label="折断线 DX";key="btn_dx";width=12;fixed_width=true;}
      }
      :column{
        :button{label="圆截面 DKK";key="btn_dkk";width=12;fixed_width=true;}
        :button{label="剖切符 PQ";key="btn_pq";width=12;fixed_width=true;}
        :button{label="云线 RT";key="btn_rt";width=12;fixed_width=true;}
      }
      :column{
        :button{label="墙身 SG";key="btn_sg";width=12;fixed_width=true;}
        :button{label="平面号 PMH";key="btn_pmh";width=12;fixed_width=true;}
        :button{label="中心线 CE";key="btn_ce";width=12;fixed_width=true;}
      }
    }
  }

  // === 其他工具 标签页 ===
  :boxed_row{label="其他工具";key="grp_misc";
    :row{
      :column{
        :button{label="选择易 SS";key="btn_ss";width=12;fixed_width=true;}
        :button{label="累计长 LCD";key="btn_lcd";width=12;fixed_width=true;}
        :button{label="钢筋1→3";key="btn_13";width=12;fixed_width=true;}
      }
      :column{
        :button{label="球标 QB";key="btn_qb";width=12;fixed_width=true;}
        :button{label="累计面 LMJ";key="btn_lmj";width=12;fixed_width=true;}
        :button{label="钢筋2→3";key="btn_23";width=12;fixed_width=true;}
      }
      :column{
        :button{label="捕捉 NN";key="btn_nn";width=12;fixed_width=true;}
        :button{label="求和 QH";key="btn_qh";width=12;fixed_width=true;}
        :button{label="DXF查询 TN";key="btn_tn";width=12;fixed_width=true;}
      }
      :column{
        :button{label="批量打印 BPT";key="btn_bpt";width=12;fixed_width=true;}
      }
    }
  }

  // === 底部按钮 ===
  :row{
    :button{label="设置(S)";key="settings";width=12;fixed_width=true;}
    :button{label="帮助(H)";key="help";width=12;fixed_width=true;}
    spacer;
    cancel_button;
    :button{label="关闭";key="close";is_default=true;width=10;fixed_width=true;}
  }
}
