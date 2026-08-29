from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
SMOKE_LSP = ROOT / "tests" / "autocad_2024_smoke.lsp"


def main() -> int:
    text = SMOKE_LSP.read_text(encoding="gbk")

    assert "sb:get-effective-name insert-ent" in text, (
        "autocad_2024_smoke.lsp 必须按最新签名向 sb:get-effective-name 传入 insert-ent"
    )
    assert "sb:get-effective-name insert-obj" not in text, (
        "autocad_2024_smoke.lsp 不应继续按旧签名向 sb:get-effective-name 传入 insert-obj"
    )
    assert re.search(r"\(setq\s+insert-ent\s+\(cc:get-first-insert\)\)", text), (
        "autocad_2024_smoke.lsp 必须先获取 insert-ent"
    )

    print("PASS: autocad_2024_smoke.lsp 已对齐 SyncBlock 最新签名")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}")
        raise SystemExit(1)
