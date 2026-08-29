from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
SYNCBLOCK = ROOT / "SyncBlock" / "SyncBlock.lsp"


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
    text = SYNCBLOCK.read_text(encoding="gbk")
    body = extract_function(text, "sb:get-effective-name")
    syncnow = extract_function(text, "c:SyncNow")

    assert "uc:block-effective-name" in body, "sb:get-effective-name 必须复用 uc:block-effective-name"
    assert "vla-get-EffectiveName" not in body, "sb:get-effective-name 不应继续自维护 EffectiveName 逻辑"
    assert "vla-get-Name" not in body, "sb:get-effective-name 不应继续自维护 Name 回退逻辑"
    assert "(sb:get-effective-name master-ent)" in syncnow, "c:SyncNow 必须直接向 sb:get-effective-name 传入 master-ent"
    assert "(sb:get-effective-name target-ent)" in syncnow, "c:SyncNow 必须直接向 sb:get-effective-name 传入 target-ent"

    print("PASS: SyncBlock 块名解析已收敛到统一核心")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}")
        raise SystemExit(1)
