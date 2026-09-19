# -*- coding: utf-8 -*-
"""TB-Toolbox DCL 语法静态校验（纯静态，无需 CAD）。

DCL 对话框只能在真实 GUI 中加载，无法自动驱动；而语法错误会让
`new_dialog` 失败、主界面直接打不开。这里用静态解析兜住低级错误：
  1. 花括号平衡
  2. tile 名是 DCL 预定义项
  3. 单个 dialog 内 key 唯一（不同 dialog 之间重名属正常）
  4. tb-dcl-launcher.dcl 的 dialog 名与 *TB:PAGES* 一致
  5. 主界面引用的 tile key（tabs/settings/help/close）每页都存在
  6. DCL 标题里的版本号与 *TB:VERSION* 一致（防止两处各写各的）

用法：python tests/verify_tb_dcl_syntax.py
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
TB = ROOT / "TB-Toolbox"
LAUNCHER = TB / "tb-dcl-launcher.dcl"
MAIN = TB / "tb-main.lsp"

KNOWN_TILES = {
    "dialog", "row", "column", "boxed_row", "boxed_column",
    "boxed_radio_row", "boxed_radio_column", "radio_button", "radio_row",
    "radio_column", "button", "edit_box", "list_box", "text", "spacer",
    "image", "image_button", "toggle", "slider", "popup_list",
    "concatenation", "paragraph", "errtile", "cancel_button", "ok_button",
    "help_button", "retirement_button", "icon",
}

# 界面必备控件。主界面改为单界面后不再有 tabs（标签栏已移除）
REQUIRED_KEYS = {"settings", "help", "close"}


def collect(text: str):
    """返回 (dialog 列表, {dialog: {key: 行号}}, 错误列表)。"""
    errors = []
    dialogs = []
    key_map = {}
    cur = None

    for no, raw in enumerate(text.splitlines(), 1):
        s = raw.strip()
        if not s or s.startswith("//"):
            continue

        m = re.match(r"^(\w+):(\w+)\{", s)
        if m:
            cur = m.group(1)
            dialogs.append(cur)
            key_map.setdefault(cur, {})
            if m.group(2) != "dialog":
                errors.append(f"行{no} 顶层 tile 应为 dialog，实际 {m.group(2)}")
        else:
            m2 = re.match(r"^:(\w+)\{", s)
            if m2 and m2.group(1) not in KNOWN_TILES:
                errors.append(f"行{no} 未知 tile: {m2.group(1)}")
            m3 = re.match(r"^(\w+);$", s)
            if m3 and m3.group(1) not in KNOWN_TILES:
                errors.append(f"行{no} 未知预定义 tile: {m3.group(1)}")

        if cur:
            for km in re.finditer(r'key="(\w+)"', s):
                k = km.group(1)
                if k in key_map[cur]:
                    errors.append(
                        f"行{no} dialog {cur} 内 key 重复: {k}（首次行{key_map[cur][k]}）")
                else:
                    key_map[cur][k] = no

    return dialogs, key_map, errors


def main() -> int:
    launcher = LAUNCHER.read_text(encoding="gbk")
    main_text = MAIN.read_text(encoding="gbk")

    errors = []

    # 1. 花括号平衡
    for name, text in (("tb-dcl-launcher.dcl", launcher),):
        if text.count("{") != text.count("}"):
            errors.append(f"{name} 花括号不平衡: {{={text.count('{')} }}={text.count('}')}")

    # 2-3. tile 名与 key 唯一性
    dialogs, key_map, errs = collect(launcher)
    errors += errs

    # 4. dialog 名与 *TB:PAGES* 一致
    m = re.search(r"\*TB:PAGES\*\s*'\(([^)]*)\)", main_text)
    assert m, "未找到 *TB:PAGES*"
    pages = re.findall(r'"([^"]+)"', m.group(1))
    assert dialogs == pages, f"dialog 名与 *TB:PAGES* 不一致:\n  DCL={dialogs}\n  LISP={pages}"

    # 5. 每页都必须有导航/底栏 key
    for d in dialogs:
        missing = REQUIRED_KEYS - set(key_map.get(d, {}))
        if missing:
            errors.append(f"{d} 缺必备 key: {sorted(missing)}")

    # 6. 版本号一致性：DCL 标题的主次版本须与 *TB:VERSION* 相同
    vm = re.search(r'\*TB:VERSION\*\s*"([^"]+)"', main_text)
    assert vm, "未找到 *TB:VERSION*"
    version = vm.group(1)                       # 例如 1.1.0
    major_minor = ".".join(version.split(".")[:2])
    tags = set(re.findall(r"建筑结构工具箱\s+(v[\d.]+)", launcher))
    if not tags:
        errors.append("launcher DCL 标题里找不到版本号（形如 建筑结构工具箱 v1.1）")
    else:
        if len(tags) > 1:
            errors.append(f"launcher DCL 标题版本号不统一: {sorted(tags)}")
        tag = tags.pop()
        if tag != "v" + major_minor:
            errors.append(
                f"版本号不一致: DCL 标题 {tag} vs *TB:VERSION* {version}"
                f"（应为 v{major_minor}）")

    if errors:
        for e in errors:
            print(f"  [FAIL] {e}")
        print(f"FAIL: DCL 语法校验未通过（{len(errors)} 个问题）")
        return 1

    print(f"PASS: DCL 语法校验通过（{len(dialogs)} 个 dialog，"
          f"{sum(len(v) for v in key_map.values())} 个 key）")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}")
        raise SystemExit(1)
