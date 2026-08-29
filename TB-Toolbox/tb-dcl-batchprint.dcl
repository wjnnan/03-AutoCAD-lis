// tb-dcl-batchprint.dcl — 批量打印对话框（重写版 v2.0）

bp_main : dialog {
  label = "批量打印 v2.0";
  initial_focus = "btn_detect";

  // === 图框识别 ===
  :boxed_column { label = "图框识别";
    :row {
      :column {
        :popup_list { key = "frame_type"; label = "识别方式:"; width = 20; }
      }
      :column {
        :edit_box { key = "frame_value"; label = "图块名/图层名:"; width = 24; }
      }
      :column {
        :button { key = "btn_pick"; label = "拾取<<"; width = 10; fixed_width = true; }
      }
    }
    :row {
      :toggle { key = "include_layouts"; label = "包含布局空间"; }
      :toggle { key = "include_model"; label = "包含模型空间"; value = "1"; }
    }
  }

  // === 打印设置 ===
  :boxed_column { label = "打印设置";
    :row {
      :column {
        :popup_list { key = "printer"; label = "打印机:"; width = 32; }
      }
    }
    :row {
      :column {
        :popup_list { key = "paper"; label = "纸张:"; width = 20; }
      }
      :column {
        :popup_list { key = "scale_mode"; label = "比例:"; width = 16; }
      }
      :column {
        :popup_list { key = "ctb"; label = "打印样式:"; width = 16; }
      }
    }
    :row {
      :column {
        :edit_box { key = "custom_scale"; label = "自定义比例 1:"; width = 10; }
      }
      :column {
        :popup_list { key = "color_mode"; label = "颜色:"; width = 12; }
      }
      :column {
        :toggle { key = "plot_upside_down"; label = "反向打印"; }
      }
    }
  }

  // === 输出设置 ===
  :boxed_column { label = "输出设置";
    :row {
      :column {
        :popup_list { key = "output_mode"; label = "输出格式:"; width = 16; }
      }
      :column {
        :edit_box { key = "output_path"; label = "输出路径:"; width = 24; }
      }
      :column {
        :button { key = "btn_path"; label = "浏览..."; width = 10; fixed_width = true; }
      }
    }
    :row {
      :column {
        :edit_box { key = "name_rule"; label = "命名规则(可选):"; width = 28; }
      }
      :column {
        :toggle { key = "merge_pdf"; label = "合并为单个PDF"; }
      }
    }
  }

  // === 图纸列表 ===
  :boxed_column { label = "图纸列表";
    :row {
      :list_box { key = "drawing_list"; width = 50; height = 12; multiple_select = true; }
      :column {
        :button { key = "btn_detect"; label = "检测图框"; width = 12; fixed_width = true; }
        :button { key = "btn_preview"; label = "预览"; width = 12; fixed_width = true; }
        :popup_list { key = "sort_mode"; width = 12; }
        :button { key = "btn_sort"; label = "排序"; width = 12; fixed_width = true; }
        :button { key = "btn_remove"; label = "移除选中"; width = 12; fixed_width = true; }
        :button { key = "btn_clear"; label = "清空列表"; width = 12; fixed_width = true; }
        spacer;
        :button { key = "btn_save_cfg"; label = "保存配置"; width = 12; fixed_width = true; }
        :button { key = "btn_load_cfg"; label = "加载配置"; width = 12; fixed_width = true; }
      }
    }
    :row {
      :text { key = "status"; label = "点击「检测图框」开始。"; }
    }
  }

  // === 底部 ===
  :row {
    :button { key = "btn_help"; label = "帮助"; width = 10; fixed_width = true; }
    spacer;
    :button { key = "btn_print"; label = "开始打印"; width = 14; fixed_width = true; is_default = true; }
    cancel_button;
  }
}
