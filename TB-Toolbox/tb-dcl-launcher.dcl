// tb-dcl-launcher.dcl — 建筑结构工具箱主界面
// 7 个独立标签页 dialog（tb_page_0 ~ tb_page_6），通过 done_dialog 循环真正切页
// 布局思路参考「贱人工具箱」：boxed_row 分区标题 + 多列紧凑按钮网格

tb_page_0:dialog{
  label="建筑结构工具箱 v1.0 - 绘图编辑";
  initial_focus="tab_edit";

  :boxed_radio_row{
    key="tabs";
    :radio_button{label="绘图编辑";key="tab_edit";}
    :radio_button{label="文字处理";key="tab_text";}
    :radio_button{label="图层管理";key="tab_layer";}
    :radio_button{label="图块管理";key="tab_block";}
    :radio_button{label="标注处理";key="tab_dim";}
    :radio_button{label="结构通用";key="tab_struct";}
    :radio_button{label="辅助功能";key="tab_misc";}
  }

  :boxed_row{label="绘图编辑";key="grp_edit";
    :boxed_row{label="绘图";
      :row{
        :column{
          :button{label="直线 Q";key="btn_q";width=14;fixed_width=true;}
          :button{label="多段线 QW";key="btn_qw";width=14;fixed_width=true;}
          :button{label="圆 WW";key="btn_ww";width=14;fixed_width=true;}
        }
        :column{
          :button{label="椭圆 TY";key="btn_ty";width=14;fixed_width=true;}
          :button{label="矩形 QR";key="btn_qr";width=14;fixed_width=true;}
          :button{label="点 PP";key="btn_pp";width=14;fixed_width=true;}
        }
      }
    }
    :boxed_row{label="修改";
      :row{
        :column{
          :button{label="修剪 TE";key="btn_te";width=14;fixed_width=true;}
          :button{label="延伸 WE";key="btn_we";width=14;fixed_width=true;}
          :button{label="移动 A";key="btn_a";width=14;fixed_width=true;}
          :button{label="拉伸 S";key="btn_s";width=14;fixed_width=true;}
        }
        :column{
          :button{label="缩放 SC";key="btn_sc";width=14;fixed_width=true;}
          :button{label="旋转 R";key="btn_r";width=14;fixed_width=true;}
          :button{label="编辑 DE";key="btn_de";width=14;fixed_width=true;}
          :button{label="选线修剪 CX";key="btn_cx";width=14;fixed_width=true;}
        }
      }
    }
    :boxed_row{label="复制·圆角·偏移";
      :row{
        :column{
          :button{label="连续复制 CC";key="btn_cc";width=14;fixed_width=true;}
          :button{label="等距复制 CF";key="btn_cf";width=14;fixed_width=true;}
          :button{label="旋转复制 CR";key="btn_cr";width=14;fixed_width=true;}
          :button{label="复制到层 CL";key="btn_cl";width=14;fixed_width=true;}
        }
        :column{
          :button{label="零倒角 FF";key="btn_ff";width=14;fixed_width=true;}
          :button{label="倒圆角 FR";key="btn_fr";width=14;fixed_width=true;}
          :button{label="偏移 OO";key="btn_oo";width=14;fixed_width=true;}
        }
      }
    }
    :boxed_row{label="快捷缩放·旋转";
      :row{
        :column{
          :button{label="缩放0.5× S1";key="btn_s1";width=14;fixed_width=true;}
          :button{label="缩放2× S2";key="btn_s2";width=14;fixed_width=true;}
          :button{label="缩放4× S4";key="btn_s4";width=14;fixed_width=true;}
        }
        :column{
          :button{label="缩放5× S5";key="btn_s5";width=14;fixed_width=true;}
          :button{label="缩放100× S0";key="btn_s0";width=14;fixed_width=true;}
          :button{label="缩放1000× S00";key="btn_s00";width=14;fixed_width=true;}
        }
        :column{
          :button{label="顺转45 R4";key="btn_r4";width=14;fixed_width=true;}
          :button{label="顺转90 R9";key="btn_r9";width=14;fixed_width=true;}
          :button{label="逆转45 R5";key="btn_r5";width=14;fixed_width=true;}
          :button{label="逆转90 R0";key="btn_r0";width=14;fixed_width=true;}
        }
      }
    }
    :boxed_row{label="改色";
      :row{
        :column{
          :button{label="红 C1";key="btn_c1";width=14;fixed_width=true;}
          :button{label="黄 C2";key="btn_c2";width=14;fixed_width=true;}
          :button{label="绿 C3";key="btn_c3";width=14;fixed_width=true;}
          :button{label="青 C4";key="btn_c4";width=14;fixed_width=true;}
        }
        :column{
          :button{label="蓝 C5";key="btn_c5";width=14;fixed_width=true;}
          :button{label="洋红 C6";key="btn_c6";width=14;fixed_width=true;}
          :button{label="白 C7";key="btn_c7";width=14;fixed_width=true;}
          :button{label="灰 C8";key="btn_c8";width=14;fixed_width=true;}
        }
      }
    }
    :boxed_row{label="视图·其它";
      :row{
        :column{
          :button{label="Z归零 Z0";key="btn_z0";width=14;fixed_width=true;}
          :button{label="范围缩放 EE";key="btn_ee";width=14;fixed_width=true;}
          :button{label="快速保存 AS";key="btn_as";width=14;fixed_width=true;}
        }
        :column{
          :button{label="单视口 V1";key="btn_v1";width=14;fixed_width=true;}
          :button{label="双视口竖 V2";key="btn_v2";width=14;fixed_width=true;}
          :button{label="双视口横 V3";key="btn_v3";width=14;fixed_width=true;}
        }
      }
    }
  }

  :row{
    :button{label="设置(S)";key="settings";width=12;fixed_width=true;}
    :button{label="帮助(H)";key="help";width=12;fixed_width=true;}
    spacer;
    :button{label="关闭";key="close";is_default=true;width=10;fixed_width=true;}
  }
}

tb_page_1:dialog{
  label="建筑结构工具箱 v1.0 - 文字处理";
  initial_focus="tab_text";

  :boxed_radio_row{
    key="tabs";
    :radio_button{label="绘图编辑";key="tab_edit";}
    :radio_button{label="文字处理";key="tab_text";}
    :radio_button{label="图层管理";key="tab_layer";}
    :radio_button{label="图块管理";key="tab_block";}
    :radio_button{label="标注处理";key="tab_dim";}
    :radio_button{label="结构通用";key="tab_struct";}
    :radio_button{label="辅助功能";key="tab_misc";}
  }

  :boxed_row{label="文字处理";key="grp_text";
    :boxed_row{label="文字样式";
      :row{
        :column{
          :button{label="创建TSSD TSSD";key="btn_tssd";width=16;fixed_width=true;}
        }
        :column{
          :button{label="改TSSD GTS";key="btn_gts";width=16;fixed_width=true;}
        }
      }
    }
    :boxed_row{label="文字编辑";
      :row{
        :column{
          :button{label="改字宽 TTK";key="btn_ttk";width=14;fixed_width=true;}
          :button{label="改字高 TTG";key="btn_ttg";width=14;fixed_width=true;}
          :button{label="旋转 TTR";key="btn_ttr";width=14;fixed_width=true;}
        }
        :column{
          :button{label="左对齐 TTY";key="btn_tty";width=14;fixed_width=true;}
          :button{label="查找替换 TH";key="btn_th";width=14;fixed_width=true;}
        }
      }
    }
    :boxed_row{label="排版";
      :row{
        :column{
          :button{label="连接 TTJ";key="btn_ttj";width=14;fixed_width=true;}
          :button{label="对齐 TTQ";key="btn_ttq";width=14;fixed_width=true;}
        }
        :column{
          :button{label="文字加框 TJK";key="btn_tjk";width=14;fixed_width=true;}
        }
      }
    }
    :boxed_row{label="钢筋等级转换";
      :row{
        :column{
          :button{label="一级→三级 13";key="btn_13";width=14;fixed_width=true;}
          :button{label="二级→三级 23";key="btn_23";width=14;fixed_width=true;}
        }
        :column{
          :button{label="三级→一级 31";key="btn_31";width=14;fixed_width=true;}
          :button{label="三级→二级 32";key="btn_32";width=14;fixed_width=true;}
        }
      }
    }
  }

  :row{
    :button{label="设置(S)";key="settings";width=12;fixed_width=true;}
    :button{label="帮助(H)";key="help";width=12;fixed_width=true;}
    spacer;
    :button{label="关闭";key="close";is_default=true;width=10;fixed_width=true;}
  }
}

tb_page_2:dialog{
  label="建筑结构工具箱 v1.0 - 图层管理";
  initial_focus="tab_layer";

  :boxed_radio_row{
    key="tabs";
    :radio_button{label="绘图编辑";key="tab_edit";}
    :radio_button{label="文字处理";key="tab_text";}
    :radio_button{label="图层管理";key="tab_layer";}
    :radio_button{label="图块管理";key="tab_block";}
    :radio_button{label="标注处理";key="tab_dim";}
    :radio_button{label="结构通用";key="tab_struct";}
    :radio_button{label="辅助功能";key="tab_misc";}
  }

  :boxed_row{label="图层管理";key="grp_layer";
    :boxed_row{label="图层开关";
      :row{
        :column{
          :button{label="关层 TG";key="btn_tg";width=14;fixed_width=true;}
          :button{label="反关 TGF";key="btn_tgf";width=14;fixed_width=true;}
          :button{label="冻层 TD";key="btn_td";width=14;fixed_width=true;}
        }
        :column{
          :button{label="反冻 TDF";key="btn_tdf";width=14;fixed_width=true;}
          :button{label="锁层 TS";key="btn_ts";width=14;fixed_width=true;}
          :button{label="反锁 TSF";key="btn_tsf";width=14;fixed_width=true;}
        }
      }
    }
    :boxed_row{label="全部操作";
      :row{
        :column{
          :button{label="全解冻 TDJ";key="btn_tdj";width=14;fixed_width=true;}
          :button{label="全解锁 TSJ";key="btn_tsj";width=14;fixed_width=true;}
        }
        :column{
          :button{label="全部显示 TX";key="btn_tx";width=14;fixed_width=true;}
        }
      }
    }
    :boxed_row{label="当前层";
      :row{
        :column{
          :button{label="切当前层 TQ";key="btn_tq";width=14;fixed_width=true;}
        }
        :column{
          :button{label="改到当前层 GTC";key="btn_gtc";width=16;fixed_width=true;}
        }
      }
    }
  }

  :row{
    :button{label="设置(S)";key="settings";width=12;fixed_width=true;}
    :button{label="帮助(H)";key="help";width=12;fixed_width=true;}
    spacer;
    :button{label="关闭";key="close";is_default=true;width=10;fixed_width=true;}
  }
}

tb_page_3:dialog{
  label="建筑结构工具箱 v1.0 - 图块管理";
  initial_focus="tab_block";

  :boxed_radio_row{
    key="tabs";
    :radio_button{label="绘图编辑";key="tab_edit";}
    :radio_button{label="文字处理";key="tab_text";}
    :radio_button{label="图层管理";key="tab_layer";}
    :radio_button{label="图块管理";key="tab_block";}
    :radio_button{label="标注处理";key="tab_dim";}
    :radio_button{label="结构通用";key="tab_struct";}
    :radio_button{label="辅助功能";key="tab_misc";}
  }

  :boxed_row{label="图块管理";key="grp_block";
    :row{
      :column{
        :button{label="快速建块 JK";key="btn_jk";width=14;fixed_width=true;}
        :button{label="块统计 KTJ";key="btn_ktj";width=14;fixed_width=true;}
        :button{label="块改名 GKM";key="btn_gkm";width=14;fixed_width=true;}
      }
      :column{
        :button{label="改块属性 GKS";key="btn_gks";width=14;fixed_width=true;}
        :button{label="删重叠块 SK";key="btn_sk";width=14;fixed_width=true;}
      }
    }
  }

  :row{
    :button{label="设置(S)";key="settings";width=12;fixed_width=true;}
    :button{label="帮助(H)";key="help";width=12;fixed_width=true;}
    spacer;
    :button{label="关闭";key="close";is_default=true;width=10;fixed_width=true;}
  }
}

tb_page_4:dialog{
  label="建筑结构工具箱 v1.0 - 标注处理";
  initial_focus="tab_dim";

  :boxed_radio_row{
    key="tabs";
    :radio_button{label="绘图编辑";key="tab_edit";}
    :radio_button{label="文字处理";key="tab_text";}
    :radio_button{label="图层管理";key="tab_layer";}
    :radio_button{label="图块管理";key="tab_block";}
    :radio_button{label="标注处理";key="tab_dim";}
    :radio_button{label="结构通用";key="tab_struct";}
    :radio_button{label="辅助功能";key="tab_misc";}
  }

  :boxed_row{label="标注处理";key="grp_dim";
    :row{
      :column{
        :button{label="标注复位 FW";key="btn_fw";width=16;fixed_width=true;}
        :button{label="标注线对齐 BBQ";key="btn_bbq";width=16;fixed_width=true;}
        :button{label="标注等分 BBF";key="btn_bbf";width=16;fixed_width=true;}
        :button{label="标注移层 BGC";key="btn_bgc";width=16;fixed_width=true;}
      }
      :column{
        :button{label="界线对齐 GGB";key="btn_ggb";width=16;fixed_width=true;}
        :button{label="改标注文字 GBB";key="btn_gbb";width=16;fixed_width=true;}
        :button{label="坐标标注 ZB";key="btn_zb";width=16;fixed_width=true;}
        :button{label="球标 QB";key="btn_qb";width=16;fixed_width=true;}
      }
    }
  }

  :row{
    :button{label="设置(S)";key="settings";width=12;fixed_width=true;}
    :button{label="帮助(H)";key="help";width=12;fixed_width=true;}
    spacer;
    :button{label="关闭";key="close";is_default=true;width=10;fixed_width=true;}
  }
}

tb_page_5:dialog{
  label="建筑结构工具箱 v1.0 - 结构通用";
  initial_focus="tab_struct";

  :boxed_radio_row{
    key="tabs";
    :radio_button{label="绘图编辑";key="tab_edit";}
    :radio_button{label="文字处理";key="tab_text";}
    :radio_button{label="图层管理";key="tab_layer";}
    :radio_button{label="图块管理";key="tab_block";}
    :radio_button{label="标注处理";key="tab_dim";}
    :radio_button{label="结构通用";key="tab_struct";}
    :radio_button{label="辅助功能";key="tab_misc";}
  }

  :boxed_row{label="结构通用";key="grp_struct";
    :boxed_row{label="钢筋绘制";
      :row{
        :column{
          :button{label="画钢筋 RB";key="btn_rb";width=14;fixed_width=true;}
          :button{label="画箍筋 RS";key="btn_rs";width=14;fixed_width=true;}
          :button{label="加弯钩 RH";key="btn_rh";width=14;fixed_width=true;}
          :button{label="删弯钩 RDH";key="btn_rdh";width=14;fixed_width=true;}
        }
        :column{
          :button{label="改宽度 RW";key="btn_rw";width=14;fixed_width=true;}
          :button{label="偏移钢筋 RO";key="btn_ro";width=14;fixed_width=true;}
          :button{label="线变筋 RL";key="btn_rl";width=14;fixed_width=true;}
        }
        :column{
          :button{label="钢筋标注 RD";key="btn_rd";width=14;fixed_width=true;}
          :button{label="钢筋编号 RCC";key="btn_rcc";width=14;fixed_width=true;}
          :button{label="板底筋 RBR";key="btn_rbr";width=14;fixed_width=true;}
          :button{label="板负筋 RBF";key="btn_rbf";width=14;fixed_width=true;}
        }
      }
    }
    :boxed_row{label="钢筋编辑";
      :row{
        :column{
          :button{label="编辑标注 RE";key="btn_re";width=14;fixed_width=true;}
          :button{label="配筋面积 RA";key="btn_ra";width=14;fixed_width=true;}
          :button{label="编号管理 RN";key="btn_rn";width=14;fixed_width=true;}
        }
        :column{
          :button{label="钢筋镜像 RM";key="btn_rm";width=16;fixed_width=true;}
          :button{label="双击编辑 RED";key="btn_red";width=16;fixed_width=true;}
          :button{label="双击增强 REDB";key="btn_redb";width=16;fixed_width=true;}
        }
      }
    }
    :boxed_row{label="结构构件";
      :row{
        :column{
          :button{label="矩形柱 DK";key="btn_dk";width=14;fixed_width=true;}
          :button{label="圆形柱 DKK";key="btn_dkk";width=14;fixed_width=true;}
          :button{label="墙身缝 SG";key="btn_sg";width=14;fixed_width=true;}
        }
        :column{
          :button{label="图名线 TML";key="btn_tml";width=14;fixed_width=true;}
          :button{label="剖切符 PQ";key="btn_pq";width=14;fixed_width=true;}
          :button{label="平面号 PMH";key="btn_pmh";width=14;fixed_width=true;}
        }
      }
    }
  }

  :row{
    :button{label="设置(S)";key="settings";width=12;fixed_width=true;}
    :button{label="帮助(H)";key="help";width=12;fixed_width=true;}
    spacer;
    :button{label="关闭";key="close";is_default=true;width=10;fixed_width=true;}
  }
}

tb_page_6:dialog{
  label="建筑结构工具箱 v1.0 - 辅助功能";
  initial_focus="tab_misc";

  :boxed_radio_row{
    key="tabs";
    :radio_button{label="绘图编辑";key="tab_edit";}
    :radio_button{label="文字处理";key="tab_text";}
    :radio_button{label="图层管理";key="tab_layer";}
    :radio_button{label="图块管理";key="tab_block";}
    :radio_button{label="标注处理";key="tab_dim";}
    :radio_button{label="结构通用";key="tab_struct";}
    :radio_button{label="辅助功能";key="tab_misc";}
  }

  :boxed_row{label="辅助功能";key="grp_misc";
    :boxed_row{label="云线箭头";
      :row{
        :column{
          :button{label="云线 RT";key="btn_rt";width=14;fixed_width=true;}
          :button{label="云线引线 JT";key="btn_jt";width=14;fixed_width=true;}
        }
        :column{
          :button{label="出图比例 XD";key="btn_xd";width=14;fixed_width=true;}
        }
      }
    }
    :boxed_row{label="辅助绘图";
      :row{
        :column{
          :button{label="单折断线 DX";key="btn_dx";width=14;fixed_width=true;}
          :button{label="双折断线 DXX";key="btn_dxx";width=14;fixed_width=true;}
          :button{label="水平断点 DD";key="btn_dd";width=14;fixed_width=true;}
          :button{label="竖直断点 DDD";key="btn_ddd";width=14;fixed_width=true;}
        }
        :column{
          :button{label="焊管缝线 HGF";key="btn_hgf";width=14;fixed_width=true;}
          :button{label="捕捉设置 NN";key="btn_nn";width=14;fixed_width=true;}
          :button{label="图纸清理 QQ";key="btn_qq";width=14;fixed_width=true;}
          :button{label="说明标签 SY";key="btn_sy";width=14;fixed_width=true;}
        }
        :column{
          :button{label="中心线 CE";key="btn_ce";width=14;fixed_width=true;}
        }
      }
    }
    :boxed_row{label="计算统计";
      :row{
        :column{
          :button{label="累计长度 LCD";key="btn_lcd";width=14;fixed_width=true;}
          :button{label="累计面积 LMJ";key="btn_lmj";width=14;fixed_width=true;}
        }
        :column{
          :button{label="数字求和 QH";key="btn_qh";width=14;fixed_width=true;}
          :button{label="DXF查询 TN";key="btn_tn";width=14;fixed_width=true;}
        }
      }
    }
    :boxed_row{label="选择·批量打印";
      :row{
        :column{
          :button{label="选择易 SS";key="btn_ss";width=14;fixed_width=true;}
        }
        :column{
          :button{label="批量打印 BPT";key="btn_bpt";width=16;fixed_width=true;}
          :button{label="打印设置 BPSET";key="btn_bpset";width=16;fixed_width=true;}
        }
      }
    }
  }

  :row{
    :button{label="设置(S)";key="settings";width=12;fixed_width=true;}
    :button{label="帮助(H)";key="help";width=12;fixed_width=true;}
    spacer;
    :button{label="关闭";key="close";is_default=true;width=10;fixed_width=true;}
  }
}
