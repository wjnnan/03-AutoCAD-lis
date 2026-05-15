from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REBAR_EDIT = ROOT / "TB-Toolbox" / "tb-mod-rebar-edit.lsp"


def main() -> int:
    text = REBAR_EDIT.read_text(encoding="utf-8")

    depth = 0
    in_string = False
    escaped = False
    in_comment = False

    for index, char in enumerate(text):
        if in_comment:
            if char == "\n":
                in_comment = False
            continue

        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue

        if char == ";":
            in_comment = True
            continue
        if char == '"':
            in_string = True
            continue
        if char == "(":
            depth += 1
            continue
        if char == ")":
            depth -= 1
            assert depth >= 0, f"tb-mod-rebar-edit 在偏移 {index} 出现多余右括号"

    assert not in_string, "tb-mod-rebar-edit 存在未闭合字符串"
    assert depth == 0, f"tb-mod-rebar-edit 括号不平衡，剩余深度 {depth}"

    print("PASS: tb-mod-rebar-edit 结构平衡检查通过")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}")
        raise SystemExit(1)
