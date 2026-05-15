from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
DIFFCHECK = ROOT / "DiffCheck" / "DiffCheck.lsp"


def locals_of(text: str, name: str) -> set[str]:
    pattern = re.compile(rf"\(defun\s+{re.escape(name)}\s*\([^/]*\/([^)]*)\)", re.IGNORECASE)
    match = pattern.search(text)
    if not match:
        raise AssertionError(f"未找到或未声明局部变量的函数: {name}")
    return {item for item in re.split(r"\s+", match.group(1).strip()) if item}


def main() -> int:
    text = DIFFCHECK.read_text(encoding="utf-8")

    offset_locals = locals_of(text, "dc:offset")
    diff_locals = locals_of(text, "dc:diff")

    for symbol in ("c", "en", "a", "b", "v"):
        assert symbol in offset_locals, f"dc:offset 必须将 {symbol} 声明为局部变量"

    for symbol in ("en", "s", "box"):
        assert symbol in diff_locals, f"dc:diff 必须将 {symbol} 声明为局部变量"

    print("PASS: DiffCheck 辅助函数局部变量检查通过")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}")
        raise SystemExit(1)
