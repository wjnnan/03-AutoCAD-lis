from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
DIFFCHECK = ROOT / "DiffCheck" / "DiffCheck.lsp"


def main() -> int:
    text = DIFFCHECK.read_text(encoding="gbk")

    assert re.search(r"\(defun\s+c:DFCC\s+\(/\s+ss\s*\)", text), "c:DFCC 必须将 ss 声明为局部变量"
    assert re.search(r"\(defun\s+c:DFCT\s+\(/\s+v\s*\)", text), "c:DFCT 必须将 v 声明为局部变量"

    print("PASS: DiffCheck 命令局部变量检查通过")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}")
        raise SystemExit(1)
