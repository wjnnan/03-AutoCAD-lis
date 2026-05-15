from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
DIFFCHECK = ROOT / "DiffCheck" / "DiffCheck.lsp"


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
    text = DIFFCHECK.read_text(encoding="utf-8")
    diff_body = extract_function(text, "dc:diff")
    helper_body = extract_function(text, "dc:collect-diff-box")

    assert "(defun dc:collect-diff-box" not in diff_body, "dc:diff 内不应再嵌套定义 dc:collect-diff-box"
    for token in ("ofs", "totalW", "totalH", "ignored-cnt", "valid-boxes"):
        assert token in helper_body, f"dc:collect-diff-box 必须显式接收 {token}"

    print("PASS: DiffCheck 嵌套辅助函数检查通过")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}")
        raise SystemExit(1)
