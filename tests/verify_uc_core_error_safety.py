from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
UC_CORE = ROOT / "unified-lib" / "uc-core.lsp"


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
    text = UC_CORE.read_text(encoding="utf-8")

    helper = extract_function(text, "uc:command-safe")
    undo_begin = extract_function(text, "uc:undo-begin")
    undo_end = extract_function(text, "uc:undo-end")

    assert "command-s" in helper, "uc:command-safe 必须优先支持 command-s"
    assert "uc:command-safe" in undo_begin, "uc:undo-begin 必须通过 uc:command-safe 执行回退命令"
    assert "uc:command-safe" in undo_end, "uc:undo-end 必须通过 uc:command-safe 执行回退命令"
    assert "'command '" not in undo_begin, "uc:undo-begin 不应直接调用 command 作为回退路径"
    assert "'command '" not in undo_end, "uc:undo-end 不应直接调用 command 作为回退路径"

    print("PASS: uc-core 异常恢复命令回退路径检查通过")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}")
        raise SystemExit(1)
