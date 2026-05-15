// tb-dcl-setting.dcl — 工具箱设置对话框

tb_settings:dialog{
  label="建筑结构工具箱 — 系统设置";

  :boxed_column{label="绘图参数";
    :row{
      :edit_box{label="出图比例 1:";key="scale";edit_width=10;}
      :edit_box{label="文字高度";key="text_h";edit_width=10;}
    }
  }

  :boxed_column{label="文字样式（TSSD标准）";
    :row{
      :edit_box{label="样式名";key="style";edit_width=16;}
      :edit_box{label="字体";key="font";edit_width=16;}
    }
    :row{
      :edit_box{label="大字体";key="bigfont";edit_width=16;}
      :edit_box{label="宽高比";key="width";edit_width=10;}
    }
  }

  :boxed_column{label="图层设置";
    :row{
      :edit_box{label="梁图层";key="beam_lay";edit_width=16;}
      :edit_box{label="柱图层";key="col_lay";edit_width=16;}
    }
    :row{
      :edit_box{label="墙图层";key="wall_lay";edit_width=16;}
      :edit_box{label="文字图层";key="text_lay";edit_width=16;}
    }
    :row{
      :edit_box{label="标注图层";key="dim_lay";edit_width=16;}
      :edit_box{label="云线图层";key="cloud_lay";edit_width=16;}
    }
  }

  :boxed_column{label="修订云线";
    :row{
      :edit_box{label="云线颜色(1-255)";key="cloud_col";edit_width=10;}
      :edit_box{label="弧长系数";key="cloud_arc";edit_width=10;}
    }
  }

  :row{
    :button{label="保存设置";key="save";is_default=true;width=14;fixed_width=true;}
    :button{label="恢复默认";key="reset";width=14;fixed_width=true;}
    cancel_button;
  }
}
