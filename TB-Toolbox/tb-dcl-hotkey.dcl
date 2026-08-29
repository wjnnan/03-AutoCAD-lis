// tb-dcl-hotkey.dcl - 快捷键设置对话框
// 布局：左命令列表 + 右"当前命令"编辑面板 + 底部操作行

tb_hotkey:dialog{
  label="结构工具箱 - 快捷键设置";
  initial_focus="cmd_list";

  :row{
    :list_box{key="cmd_list";width=38;height=24;multiple_select=false;}
    :boxed_column{label="当前命令";
      :row{
        :column{
          :text{label="功能:";}
          :text{label="命令:";}
          spacer;
          :text{label="快捷键:";}
        }
        :column{
          :text{key="cur_fn";label="";width=16;}
          :text{key="cur_cmd";label="";width=12;}
          spacer;
          :edit_box{key="shortcut";edit_width=10;}
        }
      }
      spacer;
      :row{
        :button{key="btn_apply";label="应用";width=10;fixed_width=true;}
        :button{key="btn_reset_one";label="重置当前";width=12;fixed_width=true;}
      }
      spacer;
      :button{key="btn_reset_all";label="恢复全部默认";width=16;fixed_width=true;}
    }
  }

  :text{key="hk_status";label="共125个命令。选择命令，修改快捷键后点应用，最后保存并应用。";}

  :row{
    :button{key="save";label="保存并应用";is_default=true;width=14;fixed_width=true;}
    :button{key="btn_gen";label="常规设置...";width=14;fixed_width=true;}
    cancel_button;
  }
}
