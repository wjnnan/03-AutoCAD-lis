**中文版** | [English](README.md)

---

# SyncBlock.lsp — AutoCAD 圖塊同步工具

**只維護一個主底圖，其他圖自動更新。**

---

## 問題

你在 AutoCAD 裡有一張平面圖。同一個底圖，但需要出多個版本：

```
底圖改了一條牆
→ 消防檢討圖要手動更新
→ 無障礙檢討圖要手動更新
→ 面積計算圖要手動更新
→ 忘記哪張已經更新了
```

以前的做法：關閉圖層、複製、貼上。每張圖都要做，每次底圖改動都要重來。

---

## 解法

SyncBlock 讓你只維護**一個主底圖 Block**。子 Block（B、C、D...）各自保留需要的圖層，執行一次 `SyncNow`，全部自動更新。

```
主底圖 Block A（完整版）
  牆線、門窗、窗戶編號、尺寸標註、空間名稱...所有圖層

子 Block B（消防底圖）
  保留：牆線、門窗
  去掉：窗戶編號、尺寸標註
  → 疊加消防設備（直接畫在 Model Space）

子 Block C（無障礙底圖）
  保留：牆線、門窗、空間名稱
  去掉：窗戶編號、尺寸標註
  → 疊加無障礙設施（直接畫在 Model Space）

每個子 Block 要保留哪些圖層由你自己決定，沒有固定規則。
改 A → 執行 SyncNow → 所有子 Block 底圖自動更新
```

---

## 技術原理

SyncBlock 使用 **Consensus Voting 演算法**計算圖塊之間的正確位移——就算你在主底圖加了新標註或尺寸也不會跑掉。腳本從每個圖層抽樣幾何物件，用投票決定最一致的位移，投票不足時自動切換到 BBox 對位。

---

## 安裝

1. 下載 `SyncBlock.lsp`
2. 在 AutoCAD 輸入 `APPLOAD`
3. 載入檔案
4. 輸入 `SyncNow` 或 `SFM` 執行

**小技巧：** 加入 AutoCAD Startup Suite，每次開啟自動載入。

---

## 準備工作

### 主底圖 Block A
選取所有底圖物件 → 輸入 `BLOCK` → 命名。

也可以用**複製貼上為圖塊**（`Ctrl+Shift+V`）——SyncBlock 兩種都支援。

### 子 Block B、C、D...
複製 Block A → 進入 Block Editor → 刪掉不需要圖層的物件 → 關閉。

> 子 Block 的圖層名稱必須與 Block A 完全相同。

---

## 使用方式

輸入 `SyncNow` 或 `SFM`：

```
1. 點選主底圖 Block A
2. 框選所有目標 Block
3. 完成
```

指令列輸出：
```
Master: 1F-BASE
Processing: 1F-FIRE
  Objects: 3257 (+18 Hatch)
  Done: 3257 objects synced.
Sync complete!
```

---

## 指令

| 指令 | 說明 |
|------|------|
| `SyncNow` | 執行同步 |
| `SFM` | 縮寫 |

---

## 注意事項

| 項目 | 說明 |
|------|------|
| Hatch（填充） | 目前版本略過 |
| 框選包含 Block A | 自動跳過 |
| 還原 | 按 `Ctrl+Z` |
| 多個樓層 | 每層各建一組 Block |
| 巢狀 Block | 目前不遞迴更新 |

---

## 相容性

| 版本 | 狀態 |
|------|------|
| AutoCAD 2014+ | ✅ 支援 |
| 2014 以下 | 未測試 |

---

## 常見問題

**同步後子 Block 不見了？**
確認子 Block 的圖層名稱與 Block A 完全相同，進入 Block Editor 確認。

**位置跑掉？**
Voting 演算法需要子 Block 裡有一些原始幾何物件才能計算位移。確認子 Block 沒有被完全清空。

**只同步了 1 個物件？**
某些代理物件或損壞物件會導致這個問題，再執行一次，腳本會跳過有問題的物件。

---

## 版本紀錄

| 版本 | 說明 |
|------|------|
| v30 | 精簡輸出，Single-Pass Engine，COM API 呼叫從 ~20k 降到 ~6k |
| v27 | 分層抽樣提升投票準確度 |
| v22 | 引入 Consensus Voting 演算法 |
| v12 | BBox 位移、顏色繼承 |
| v1–v11 | 開發測試版本 |

---

## 支持這個專案

如果 SyncBlock 幫你節省了時間，歡迎請我喝杯咖啡 ☕

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/beastt1992)

---

## 授權

MIT License — 免費使用、修改、散佈。

---

**為所有 AutoCAD 使用者而做。**
