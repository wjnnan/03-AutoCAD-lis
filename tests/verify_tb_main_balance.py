from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TB_MAIN = ROOT / "TB-Toolbox" / "tb-main.lsp"


def main() -> int:
    text = TB_MAIN.read_text(encoding="gbk")

    left = text.count("(")
    right = text.count(")")

    assert left == right, (
        f"tb-main.lsp 括号数量不平衡: '('={left}, ')'={right}"
    )

    print("PASS: tb-main.lsp 括号平衡检查通过")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}")
        raise SystemExit(1)
