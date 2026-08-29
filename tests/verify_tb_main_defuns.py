from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
TB_MAIN = ROOT / "TB-Toolbox" / "tb-main.lsp"


def main() -> int:
    text = TB_MAIN.read_text(encoding="gbk")

    assert not re.search(r"\(defun\s+tb:run-bound-command\s+nil\b", text), \
        "tb:run-bound-command 不应使用 nil 作为 defun 形参表"
    assert not re.search(r"\(defun\s+c:TBHELP\s+nil\b", text), \
        "c:TBHELP 不应使用 nil 作为 defun 形参表"
    assert re.search(r"\(defun\s+tb:run-bound-command\s*\(", text), \
        "tb:run-bound-command 应显式使用括号形参表"
    assert re.search(r"\(defun\s+c:TBHELP\s*\(", text), \
        "c:TBHELP 应显式使用括号形参表"

    print("PASS: tb-main defun 形参表检查通过")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}")
        raise SystemExit(1)
