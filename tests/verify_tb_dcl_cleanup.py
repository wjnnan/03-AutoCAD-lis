from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
TB_MAIN = ROOT / "TB-Toolbox" / "tb-main.lsp"


def extract_function(text: str, name: str) -> str:
    pattern = re.compile(rf"\(defun\s+{re.escape(name)}\b", re.IGNORECASE)
    match = pattern.search(text)
    if not match:
        raise AssertionError(f"未找到函数: {name}")

    start = match.start()
    depth = 0
    in_string = False
    escaped = False

    for index in range(start, len(text)):
        char = text[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue

        if char == '"':
            in_string = True
        elif char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return text[start:index + 1]

    raise AssertionError(f"函数括号不平衡: {name}")


def ensure_cleanup(func_body: str, marker: str) -> None:
    if marker not in func_body:
        raise AssertionError(f"未找到失败提示: {marker}")

    start = func_body.index(marker)
    window = func_body[max(0, start - 120): start + 120]
    assert "(unload_dialog dcl-id)" in window, f"{marker} 所在失败分支必须显式释放 dcl-id"


def main() -> int:
    text = TB_MAIN.read_text(encoding="gbk")
    tb_body = extract_function(text, "c:TB")
    tbsetting_body = extract_function(text, "c:TBSETTING")

    ensure_cleanup(tb_body, '[TB] 无法初始化主界面对话框。')
    ensure_cleanup(tbsetting_body, '[TB] 无法初始化设置对话框。')

    print("PASS: TB DCL 失败分支释放检查通过")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}")
        raise SystemExit(1)
