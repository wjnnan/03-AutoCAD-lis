// tb-dcl-help.dcl — 帮助对话框
// 列表内容由 tb:show-help 从 *TB:CMD-CATALOG* 动态填充，与命令清单始终同步。

tb_help:dialog{
  label="建筑结构工具箱 — 帮助";
  initial_focus="help_list";

  :text{key="help_ver";label="";}

  :text{label="按分类列出全部命令；[ ] 内为当前快捷键，可在「快捷键设置」中修改。";}

  :list_box{key="help_list";width=42;height=22;}

  :row{
    :button{label="关闭";key="close";is_default=true;is_cancel=true;
            width=14;fixed_width=true;}
  }
}
