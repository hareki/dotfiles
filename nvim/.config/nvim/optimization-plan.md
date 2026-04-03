# Neovim Performance Optimization Plan

## Problem Statement

Current startup: **209.21ms**. User reports runtime lag during TSX development. Goal: reduce startup time and eliminate runtime jank, especially in insert mode for typescriptreact files.

## Profile Analysis Summary

| Phase                    | Time    | Key Consumers                                                                                                            |
| ------------------------ | ------- | ------------------------------------------------------------------------------------------------------------------------ |
| startup (start)          | 58.42ms | cursortab→blink.cmp→copilot.lua chain (**35.9ms**), lualine (8.68ms)                                                     |
| VeryLazy                 | 63.49ms | nvim-lspconfig/mason (**24.53ms**), nvim-tree (**15.16ms**), yanky (**5.84ms**), gitsigns (4.94ms), hlslens (**4.01ms**) |
| typescriptreact FileType | 112.5ms | Treesitter TSX parse (inherent, can't optimize)                                                                          |
| BufReadPost              | 8.03ms  | nvim-ufo (4.68ms), git-conflict (1.28ms), treesitter (1.28ms)                                                            |

**Bold** = actionable items.

## Approach

Two-phase optimization:

1. **Startup**: Defer non-essential plugin loading from startup/VeryLazy to event-triggered or keymap-triggered
2. **Runtime**: Eliminate per-keystroke overhead in insert mode, reduce redundant work in hot paths

---

## Phase 1: Startup Optimization

### 1.1 Defer cursortab.nvim (save ~36ms from startup)

**File**: `lua/plugins/features/ai/cursortab.nvim.lua`

Currently `lazy = false, priority = FEATURE` which forces it and its entire dependency chain (blink.cmp 34.47ms + copilot.lua 23.35ms) to load during the startup `start` phase, before UIEnter.

**Change**: Remove `lazy = false` and `priority = Priority.FEATURE`. The existing `event = 'BufReadPost'` is sufficient — the plugin loads when the first file buffer is read, which is after UIEnter (user sees the editor faster).

**Tradeoff**: Original comment says "more responsive when loaded early". Cursortab suggestions may have a brief warm-up delay on first file open. Acceptable for ~36ms UIEnter improvement.

### 1.2 Decouple mason.nvim from LSP startup (save ~17ms from VeryLazy)

**Files**: `lua/config/options.lua`, `lua/plugins/core/lsp/nvim-lspconfig/init.lua`, `lua/plugins/core/lsp/mason.nvim.lua`

Mason is listed as a dependency of nvim-lspconfig. When nvim-lspconfig loads on VeryLazy, it forces mason to load too (16.74ms). But LSP servers don't need mason at runtime — they just need the mason bin directory in PATH.

**Changes**:

1. In `options.lua`: Add mason's bin directory to PATH early (`vim.env.PATH = vim.fn.stdpath('data') .. '/mason/bin:' .. vim.env.PATH`)
2. In `nvim-lspconfig/init.lua`: Remove `dependencies = { 'mason-org/mason.nvim' }`
3. Mason remains lazily loadable via `:Mason` command or `<leader>cm` keymap

**Risk**: Very low. Mason's bin path is stable (`stdpath('data')/mason/bin`). LSP servers work via PATH, not mason's runtime.

### 1.3 Remove VeryLazy from nvim-tree (save ~15ms from VeryLazy)

**File**: `lua/plugins/features/navigation/nvim-tree/init.lua`

nvim-tree has both `event = 'VeryLazy'` and `keys` defined. The VeryLazy event forces it to load even when the user doesn't open the explorer. Session restore doesn't need it (sessionoptions = 'buffers,curdir,folds').

**Change**: Remove `event = 'VeryLazy'`. The `keys` handler (`<leader>e`) is sufficient.

### 1.4 Remove VeryLazy from yanky.nvim (save ~6ms from VeryLazy)

**File**: `lua/plugins/features/editing/yanky.nvim.lua`

yanky.nvim has `event = 'VeryLazy'` AND extensive `keys` (y, p, P, dd, etc.). The keys alone are sufficient — lazy.nvim intercepts the first keypress, loads yanky, then replays the key.

**Change**: Remove `event = 'VeryLazy'`.

### 1.5 Defer nvim-hlslens monkey-patch + lazy load (save ~4ms from VeryLazy)

**File**: `lua/plugins/features/search/nvim-hlslens/init.lua`

hlslens has `event = 'VeryLazy'` AND `keys` (n, N). It also monkey-patches `vim.cmd.nohlsearch` in its opts to re-enable Snacks.words after clearing search highlights.

**Changes**:

1. Remove `event = 'VeryLazy'`
2. Move the `vim.cmd.nohlsearch` monkey-patch from `opts` to `init` (init runs during spec resolution, before any plugin loads — ensuring the patch is in place regardless of load timing)

### 1.6 Inline statusline check in options.lua (minor)

**File**: `lua/config/options.lua`

Currently does `require('services.statusline')` at the top level just for a simple env var check. Inline the check to remove one require from boot.

**Change**: Replace `local statusline = require('services.statusline')` and `statusline.have_status_line()` with `vim.env.NVIM_NO_STATUS_LINE == nil`.

### 1.7 Lazy harpoon in lualine component (save ~4ms from first render)

**File**: `lua/plugins/chrome/lualine/components/harpoon.lua`

The `get()` and `cond()` functions call `require('harpoon')` on every lualine render. On the first render, this triggers harpoon to load (4.04ms). Since harpoon is keymap-triggered, it doesn't need to load until the user actually uses harpoon.

**Change**: Guard both functions with `package.loaded['harpoon']` check. Return `nil`/`false` if harpoon isn't loaded yet.

---

## Phase 2: Runtime Optimization (TSX Focus)

### 2.1 Disable update_in_insert for diagnostics (HIGH IMPACT)

**File**: `lua/plugins/core/lsp/nvim-lspconfig/init.lua`

**This is the single biggest runtime optimization for TSX.**

`update_in_insert = true` causes diagnostic recalculation on **every keystroke** in insert mode. For TSX with vtsls + eslint + tailwindcss, this means 3 LSP servers re-evaluating diagnostics per keypress. This creates visible lag on large files.

**Change**: Set `update_in_insert = false`. Diagnostics update when leaving insert mode (standard VS Code behavior).

### 2.2 Optimize diagnostic set monkey-patch

**File**: `lua/plugins/core/lsp/nvim-lspconfig/utils.lua`

The `apply_underline_hack` function uses `vim.deepcopy` to clone diagnostics. `vim.deepcopy` is expensive — it recursively copies the entire diagnostic object including `user_data` (which contains the full LSP response).

**Changes**:

1. Replace `vim.deepcopy(diagnostic)` with a manual shallow copy that only includes the fields needed for the underline display (lnum, end_lnum, col, end_col, severity, namespace, bufnr)
2. This runs on every `vim.diagnostic.set` call, so the savings compound

### 2.3 Reduce buffer_status per-keystroke overhead

**File**: `lua/plugins/chrome/lualine/components/buffer_status.lua`

The cache invalidation autocmd fires on `TextChanged` and `TextChangedI`, which means **every keystroke in insert mode** invalidates the cache. The subsequent lualine render then iterates all buffers in `get_global_modified()`.

**Change**: Remove `TextChanged` and `TextChangedI` from the invalidation events. `BufModifiedSet` already fires when a buffer's modified state actually changes (unmodified→modified on first edit, modified→unmodified on save). This is sufficient.

New event list: `BufReadPost, BufWritePost, BufModifiedSet, BufEnter, BufDelete, BufWipeout`

### 2.4 Debounce dropbar refresh in noice route

**File**: `lua/plugins/chrome/noice.nvim.lua`

A noice route fires `require('dropbar.utils.bar').exec('update')` on every LSP progress 'end' event. With 3+ LSP servers for TSX, multiple rapid progress events cause redundant dropbar redraws.

**Change**: Add a 100ms debounce timer. Multiple rapid 'end' events within 100ms coalesce into a single dropbar update.

---

## Expected Impact

### Startup

| Optimization              | Estimated Savings          |
| ------------------------- | -------------------------- |
| Defer cursortab.nvim      | ~36ms                      |
| Decouple mason from LSP   | ~17ms                      |
| Lazy nvim-tree            | ~15ms                      |
| Lazy yanky.nvim           | ~6ms                       |
| Lazy nvim-hlslens         | ~4ms                       |
| Lazy harpoon in lualine   | ~4ms                       |
| Inline statusline check   | ~1ms                       |
| **Total**                 | **~83ms**                  |
| **New estimated startup** | **~126ms (40% reduction)** |

### Runtime (TSX Insert Mode)

- **update_in_insert = false**: Eliminates diagnostic recalculation on every keystroke (biggest win)
- **buffer_status fix**: Eliminates per-keystroke buffer iteration in lualine
- **diagnostic patch optimization**: Reduces allocation cost per diagnostic update
- **dropbar debounce**: Reduces redundant UI updates during LSP activity

## Notes

- Treesitter TSX parse (112ms in FileType) is inherent to the parser complexity — cannot be optimized in config
- All `lazy = false` core plugins (catppuccin, snacks, noice, dropbar, lualine) remain early-loaded for layout stability
- No memoization added — all optimizations are about deferring work or eliminating redundant work
