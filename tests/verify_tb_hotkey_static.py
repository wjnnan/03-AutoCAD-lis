# -*- coding: utf-8 -*-
"""快捷键功能静态校验：
- CMD-CATALOG 数量 == PAGE-BINDS 数量且逐项匹配
- 主界面 DCL 按钮 key 全部在目录
- 快捷键对话框 tile key 完整
用法：python tests/verify_tb_hotkey_static.py
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
TB_MAIN = ROOT / "TB-Toolbox" / "tb-main.lsp"
TB_DCL_LAUNCHER = ROOT / "TB-Toolbox" / "tb-dcl-launcher.dcl"
TB_DCL_HOTKEY = ROOT / "TB-Toolbox" / "tb-dcl-hotkey.dcl"
TB_HOTKEY_LSP = ROOT / "TB-Toolbox" / "tb-mod-hotkey.lsp"

EXPECT_PAGE_COUNTS = [45, 14, 11, 5, 8, 23, 19]


def parse_binds(text: str):
    """从 PAGE-BINDS 提取 (key, cmd) 列表。"""
    idx = text.find("*TB:PAGE-BINDS*")
    assert idx >= 0, "未找到 *TB:PAGE-BINDS*"
    q = text.find("'", idx)
    op = text.find("(", q)
    depth, i = 0, op
    while i < len(text):
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
            if depth == 0:
                break
        i += 1
    expr = text[op : i + 1]
    inner = expr[1:-1]
    items, d, st = [], 0, None
    for j, ch in enumerate(inner):
        if ch == "(":
            if d == 0:
                st = j
            d += 1
        elif ch == ")":
            d -= 1
            if d == 0 and st is not None:
                items.append(inner[st : j + 1])
                st = None
    pairs = []
    for blk in items:
        pairs.extend(re.findall(r'\("(btn_\w+)"\s*\.\s*"([^"]*)"\)', blk))
    return pairs


def parse_catalog(text: str):
    """从 CMD-CATALOG 提取 (key, cmd, fn, page) 列表。"""
    idx = text.find("*TB:CMD-CATALOG*")
    assert idx >= 0, "未找到 *TB:CMD-CATALOG*"
    q = text.find("'", idx)
    op = text.find("(", q)
    depth, i = 0, op
    while i < len(text):
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
            if depth == 0:
                break
        i += 1
    expr = text[op : i + 1]
    return re.findall(r'\("(btn_\w+)"\s+"([^"]+)"\s+"([^"]+)"\s+(\d+)\)', expr)


def main() -> int:
    main_text = TB_MAIN.read_text(encoding="gbk")
    launcher = TB_DCL_LAUNCHER.read_text(encoding="gbk")
    hot_dcl = TB_DCL_HOTKEY.read_text(encoding="gbk")

    binds = parse_binds(main_text)
    catalog = parse_catalog(main_text)

    # 1. 数量一致
    assert len(binds) == 125, f"PAGE-BINDS 数量 {len(binds)} != 125"
    assert len(catalog) == 125, f"CMD-CATALOG 数量 {len(catalog)} != 125"

    # 2. 逐项匹配（key + 命令名大小写不敏感）
    for (bk, bc), (ck, cc, cf, cp) in zip(binds, catalog):
        assert bk == ck, f"按钮 key 不一致: {bk} vs {ck}"
        assert bc.lower() == cc.lower(), f"命令名不一致: {bc} vs {cc}"
        assert cf, f"功能名为空: {bk}"
        assert cp.isdigit(), f"页号非数字: {bk}"

    # 3. 每页数量
    for page_idx in range(7):
        n = len([c for c in catalog if int(c[3]) == page_idx])
        assert n == EXPECT_PAGE_COUNTS[page_idx], f"页{page_idx}数量 {n} != {EXPECT_PAGE_COUNTS[page_idx]}"

    # 4. 主界面 DCL 按钮 key 全部在目录
    dcl_keys = set(re.findall(r'key="(btn_\w+)"', launcher))
    catalog_keys = set(c[0] for c in catalog)
    assert dcl_keys == catalog_keys, f"DCL 按钮与目录不一致: 缺失 {catalog_keys - dcl_keys}"

    # 5. 快捷键对话框 tile key 完整
    hot_keys = set(re.findall(r'key="(\w+)"', hot_dcl))
    need = {"cmd_list", "shortcut", "btn_apply", "btn_reset_one", "btn_reset_all",
            "save", "btn_gen", "hk_status", "cur_fn", "cur_cmd"}
    assert need.issubset(hot_keys), f"快捷键对话框缺 key: {need - hot_keys}"
    assert "cancel_button" in hot_dcl, "快捷键对话框缺 cancel_button"

    # 6. tb-mod-hotkey.lsp 必须存在且含关键函数
    hot_lsp = TB_HOTKEY_LSP.read_text(encoding="gbk")
    for fn in ["tb:apply-shortcuts", "tb:update-page-labels", "c:TBSETTING2",
               "tb:hotkey-validate", "tb:effective-shortcut"]:
        assert fn in hot_lsp, f"tb-mod-hotkey.lsp 缺函数 {fn}"

    print(f"PASS: 快捷键静态校验通过（{len(catalog)} 命令 / {len(dcl_keys)} 按钮 / 目录一致）")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}")
        raise SystemExit(1)
