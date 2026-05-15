[中文版](README_ZH.md) | **English**

---

# SyncBlock.lsp — AutoCAD Block Synchronization Tool

**Maintain one master block. Sync everything else automatically.**

---

## The Problem

You have a floor plan in AutoCAD. One base drawing, but multiple versions needed for different reviews:

```
Base plan changed one wall
→ Fire review needs manual update
→ Accessibility review needs manual update  
→ Area calculation needs manual update
→ You forgot which one you already updated
```

The old workflow: turn off layers, copy, paste. Repeat for every drawing, every time the base changes.

---

## The Solution

SyncBlock lets you maintain **one master Block**. Child Blocks (B, C, D...) each keep only the layers they need. Run `SyncNow` once — everything updates automatically.

```
Master Block A (complete version)
  Walls, doors, windows, window tags, dimensions, room names... all layers

Child Block B (Fire review base)
  Keep:   walls, doors, windows
  Remove: window tags, dimensions
  → Overlay fire equipment directly in Model Space

Child Block C (Accessibility review base)
  Keep:   walls, doors, windows, room names
  Remove: window tags, dimensions
  → Overlay accessibility facilities directly in Model Space

Each child block decides which layers to keep — fully flexible.
Change A → run SyncNow → all child block bases update automatically
```

---

## How It Works

SyncBlock uses a **Consensus Voting algorithm** to calculate the correct position offset between blocks — even if you've added new dimensions or annotations to the master block. It samples geometry from each layer, votes on the most consistent offset, and falls back to bounding box alignment if needed.

---

## Installation

1. Download `SyncBlock.lsp`
2. In AutoCAD, type `APPLOAD`
3. Load the file
4. Type `SyncNow` or `SFM` to run

**Tip:** Add to AutoCAD's Startup Suite for automatic loading every session.

---

## Setup

### Master Block A
Select all base drawing objects → type `BLOCK` → give it a name.

You can also use **Paste as Block** (`Ctrl+Shift+V`) — SyncBlock handles both.

### Child Blocks B, C, D...
Copy Block A → enter Block Editor → delete objects on layers you don't need → close.

> Layer names in child blocks must exactly match layer names in Block A.

---

## Usage

Type `SyncNow` or `SFM`:

```
1. Click Master Block A
2. Window-select all target Blocks
3. Done
```

Command line output:
```
Master: 1F-BASE
Processing: 1F-FIRE
  Objects: 3257 (+18 Hatch)
  Done: 3257 objects synced.
Sync complete!
```

---

## Commands

| Command | Description |
|---------|-------------|
| `SyncNow` | Run sync |
| `SFM` | Shortcut |

---

## Notes

| Item | Details |
|------|---------|
| Hatch | Skipped in current version |
| Block A in selection | Auto-skipped |
| Undo | Press `Ctrl+Z` to revert |
| Multiple floors | Create one Block group per floor |
| Nested blocks | Not recursively updated |

---

## Compatibility

| Version | Status |
|---------|--------|
| AutoCAD 2014+ | ✅ Supported |
| Below 2014 | Not tested |

---

## Troubleshooting

**Blocks disappear after sync?**
Layer names in child blocks must exactly match Block A. Check in Block Editor.

**Wrong position after sync?**
The voting algorithm needs at least some original geometry in the child block to calculate offset. Make sure child blocks weren't emptied completely before syncing.

**Only 1 object synced?**
This can happen with certain proxy or corrupted entities. Try running again — the script skips problematic objects.

---

## Version History

| Version | Notes |
|---------|-------|
| v30 | Cleaner output, single-pass engine — reduced COM API calls from ~20k to ~6k |
| v27 | Stratified layer sampling for voting accuracy |
| v22 | Introduced Consensus Voting algorithm |
| v12 | BBox offset, color inheritance |
| v1–v11 | Development |

---

## Support This Project

If SyncBlock saved you time, consider buying me a coffee ☕

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/beastt1992)

---

## License

MIT License — Free to use, modify, and distribute.

---

**Made with ❤️ for AutoCAD users.**
