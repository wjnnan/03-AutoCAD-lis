from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
TB_CORE = ROOT / "TB-Toolbox" / "tb-core.lsp"


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


def main() -> int:
    text = TB_CORE.read_text(encoding="utf-8")

    assert "(defun err:handler" not in text, "err:handler 应已删除"
    assert "(defun err:save-sysvars" not in text, "err:save-sysvars 应已删除"
    assert "(defun err:restore-sysvars" not in text, "err:restore-sysvars 应已删除"

    undo_begin = extract_function(text, "sys:undo-begin")
    undo_end = extract_function(text, "sys:undo-end")

    assert "uc:undo-begin" in undo_begin, "sys:undo-begin 必须优先复用 uc:undo-begin"
    assert "uc:undo-end" in undo_end, "sys:undo-end 必须优先复用 uc:undo-end"
    assert 'command "_.UNDO" "_BEGIN"' not in undo_begin, "sys:undo-begin 不应继续直接维护旧的 UNDO 分支"
    assert 'command "_.UNDO" "_END"' not in undo_end, "sys:undo-end 不应继续直接维护旧的 UNDO 分支"

    print("PASS: tb-core 遗留错误链已删除，UNDO 兼容包装保持有效")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}")
        raise SystemExit(1)
