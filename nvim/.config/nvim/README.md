## 💤 My Personal Neovim Config

![image](./images/demo.png)

Configured from scratch (no distro), inspired by Kickstart & LazyVim, then optimized hard for: fast cold start, per‑plugin isolation, consistent floating UX, minimal diff forks.

> [!NOTE] Status
> WIP. Structure & forks may change.

### Core Ideas

- One plugin per file (clarity, easy diffs, quick swap to forks).
- On‑demand loading (keymaps / `VeryLazy`).
- Startup: ~38ms (dashboard) / ~50ms (open file) via `:Lazy profile`.
- Unified floating layout & behavior across Snacks picker, Telescope, floating nvim‑tree.
- Tab = toggle focus (list<->preview or float<->main). `<C-t>` = toggle side‑panel mode (results dock + floating preview) where supported.
- Other floats (gitsigns preview hunk, eagle markdown) reuse the Tab focus pattern.
- Opinionated consistent UI/UX (shared layout primitives + focus & side‑panel mechanics) is largely enabled by minimal fork patches that expose extra hooks or replace narrow internal rendering pieces.

### Forks (author = hareki)

- 15+ minimal‑diff forks; updated automatically via [wei/pull](https://github.com/wei/pull).
- Features are toggleable so disabling custom bits reverts close to upstream behavior.
- Primary vehicle for unified UX: forks expose the tiny APIs (layout hooks, focus toggles, preview coordination) that upstream doesn't yet surface, letting unrelated plugins feel native to one design language.
- Example: `eagle.nvim` UI for markdown float largely reworked for theme + focus parity.

### Performance Tactics

- Defer heavy UI until first use (use lazy loading on keymaps or `VeryLazy` event whenever possible).
- Central palette + sizing modules (zero duplication).
- Shared layout primitives for pickers / tree instead of bespoke window math.

### AI Usage

Used for scaffolding & idea prompts only; final code is hand‑edited (naming, palette, sizing, error paths).

### Design Principles

- Single source of truth for sizing & theme adjustments.
- No global mutation; specs return tables; shared logic lives in `utils/`.
- Almost every keymap has a `desc` following CMOS 18 title case.
- One async formatting pipeline instead of many commands.

### Roadmap

- Upstream / retire forks when APIs land.
- Further unify preview abstractions.
- Optional minimal profile mode.

### Attribution

Ideas borrowed from Kickstart & LazyVim; all tailoring is personal workflow oriented. Respect upstream licenses.
