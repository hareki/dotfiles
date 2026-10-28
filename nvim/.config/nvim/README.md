# My Personal Neovim Config

![image](./assets/docs/demo.png)

**lazy.nvim** config built from scratch. Optimized for fast cold start, per-plugin isolation, consistent floating UX, and minimal-diff forks.

## Requirements

### System

- **[Neovim](https://neovim.io/) 0.12+**: native `vim.lsp.enable()` API
- **[Git](https://git-scm.com/)**: required by gitsigns.nvim, lazygit, blink-ripgrep (gitgrep backend)
- **[Nerd Font](https://www.nerdfonts.com/)**: all icons are Nerd Font glyphs (mini.icons, lualine, which-key, nvim-tree, etc.)
- **[ripgrep](https://github.com/BurntSushi/ripgrep)**: grep for Snacks picker, and its file finder when fd is missing
- **[fd](https://github.com/sharkdp/fd)**: file finder for Snacks picker
- **[delta](https://github.com/dandavison/delta)**: diff previews in tiny-code-action.nvim
- **[lazygit](https://github.com/jesseduffield/lazygit)**: terminal UI for Git, opened through Snacks (`<A-g>`)
- **[ImageMagick](https://imagemagick.org/)**: `magick` CLI for image rendering in Snacks (`image`)
- **[Ghostty](https://ghostty.org/)**: terminal with kitty graphics protocol support, for Snacks (`image`)
- **C compiler**: builds nvim-treesitter parsers
- **[Go](https://go.dev/)**: build step for cursortab.nvim (`cd server && go build`)
- **[Node.js](https://nodejs.org/) + npm**: mise installs the Node-based LSP servers (vtsls, eslint-lsp, etc.), which the vtsls and angularls configs resolve from mise's install dirs

### Subscriptions & API Keys

- **`ANTHROPIC_API_KEY` env var**: Claude-generated commit messages in ai-commit-msg.nvim
- **`MERCURY_API_KEY` env var**: Inception Labs Mercury token for next-edit predictions in cursortab.nvim and AI completion items in minuet-ai.nvim
- **[Claude Code](https://claude.ai/download) CLI + subscription**: Claude terminal in claudecode.nvim, toggled with `<A-a>`

## Core Ideas

- One spec file or directory per plugin under `lua/{core,chrome,features}/`; snacks.nvim is split into per-feature fragments
- On-demand loading via keymaps or `VeryLazy` event
- Startup: ~38ms (no session or blank file) / ~80ms (opening file or directory with session) via `:Lazy profile`
- Unified floating layout across Snacks picker and floating nvim-tree
- **Tab** = toggle focus (list↔preview, float↔main); **`<C-t>`** = toggle side-panel mode

## Architecture

### Central Modules (`lua/config/`)

- `init.lua`: assembles the `Conf` global from the `config.*` tables below
- `size.lua`: popup dimensions (`sm`, `lg`, `vertical_sm`, `vertical_md`, `full`)
- `icons.lua`: all icons (diagnostics, git, file status, LSP kinds)
- `globals.lua`: 6 project globals (`Defer`, `Notifier`, `Conf`, `UI`, `Project`, plus `Snacks` set by snacks.nvim)
- `completion.lua`: completion tuning constants in `Conf.cmp` (AI item cap/timeout, ripgrep min keyword length)
- `picker.lua`: shared picker UI constants
- `keymap-registry.lua`: centralized keymap `desc` overrides

### Utils (`lua/utils/`)

- `ui/`: namespaces of the `UI` global
  - `layout.popup(size)` / `layout.picker_fn(size)`, `color.blend_hex()`, `pill.virt_text()`, `cursorline.set_cursorline()`
  - `integrations/`: `catppuccin(fn)` / `catppuccin.get_palette()`, `which_key({ specs?, rules?, triggers? })`, `statusline.refresh()`
- `notifier.lua`: notification wrapper; supports markdown, tuple lists for custom highlight groups
- `common.lua`: `buf_mapper()`, `link_popup()`, `override_buf_keymaps()`, `focus_win()`, `noautocmd()`
- `lazy-require.lua`: `Defer.on_index()`, `Defer.on_exported_call()`

### Complex Plugin Structure

Plugins with state or more than a few lines of helper logic use the directory form:

```
nvim-tree-lua/
  init.lua   -- lazy.nvim specs: UI.catppuccin, UI.which_key, then the plugin specs
  utils.lua  -- helpers, plus the M.state = {} table when the plugin keeps state
```

### LSP & Formatting

- Per-server configs in `lua/core/lsp/nvim-lspconfig/lsp/{server}.lua`
- Tool installation (LSP servers, formatters, linters) is handled by [mise-en-place](https://mise.jdx.dev/) via `~/.config/mise/config.toml`
- Async style-enforcement pipeline (formatters + linters) in `utils/style-enforcers/`

## Forks (author = hareki)

- 24 minimal-diff forks; updated via [wei/pull](https://github.com/wei/pull)
- Features toggleable: disabling custom bits reverts to upstream behavior
- Enable unified UX by exposing layout hooks, focus toggles, preview coordination, UI tweaks and more.

## Code Style

- stylua: 100-char lines, 2-space indent
- LuaLS `--- @class` / `--- @param` / `--- @return` annotations for public APIs
- All keymaps include `desc` in CMOS 18 title case
- Icons imported from `config/icons.lua`, never hardcoded

## Attribution

Inspired by [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim), [LazyVim](https://github.com/LazyVim/LazyVim) and [NvChad](https://github.com/NvChad/NvChad).
