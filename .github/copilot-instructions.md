## AI Assistant Working Guidelines (Dotfiles Repo)

Purpose: Help you make safe, high‑signal edits to my personal dotfiles. These files are declarative system config, not an app build. Favor minimal, surgical changes; never introduce bulky frameworks or speculative refactors.

### 1. Repo Structure & Symlink Model

- Each top‑level directory (e.g. `nvim/`, `zsh/`, `tmux/`, `ghostty/`, `lazygit/`, `mise/`, `atuin/`, `zen-browser/`) mirrors the eventual target path under `$HOME` using GNU stow. Assume I run `stow <module>` from repo root to symlink into `$HOME`.
- Do NOT hard‑code absolute user paths; use env vars (`$HOME`, `$XDG_CONFIG_HOME`) when suggesting additions.
- Ignore macOS cruft: `.DS_Store` is globally excluded (`stow/.stow-global-ignore`).

### 2. Neovim Config Philosophy (`nvim/.config/nvim`)

- Built from scratch: one plugin per file under `lua/plugins/**` for isolation & easy diffing. When adding a plugin: create a new file in the most fitting category (`ui/`, `lsp/`, `coding/`, etc.) instead of appending to existing ones.
- Central bootstrap: `init.lua` -> `configs/*` -> `configs/lazy/init.lua` sets `spec` via `import` folders (order matters: `plugins.ui` first for palette hooks).
- Shared sizing & layout: `configs/size.lua` + `utils/ui.lua` unify popup geometry; reuse helpers like `require('utils.ui').popup_config('lg')` instead of ad‑hoc window math.
- Theme & palette layering: call `utils.ui.catppuccin` with a register fn to extend `opts.custom_highlights`. Don’t duplicate color literals—prefer `get_palette()`.
- Keymaps: all mappings in `configs/keymaps.lua` must include a concise `desc` (Title Case). If adding plugin-local keymaps inside a plugin spec, also supply `desc` for discoverability.
- Performance goals: preserve lazy loading (`lazy=true` default, load via events/keymaps). Avoid global mutation; plugin specs return tables only.

### 3. Shell / ZSH (`zsh/`)

- Startup tuned (~110ms): keep lazy loading patterns (Antidote static bundle, `evalcache`, `zcompile`). When adding a plugin: append to the managed plugins file (`plugins.zsh`) respecting existing format; don’t inline heavy init in `.zshrc`.
- Functions are autoloaded from `.config/zsh/functions`. New utilities go there (one file per function) — don’t source them manually; rely on `autoload` loop.
- Maintain separation: ordering loop `for cfg in aliases vi-mode compdef keymaps fzf zoxide; do ...`. Insert new topical config only if clearly justified (e.g. `git-tools`) and document rationale in a short comment.

### 4. Tmux (`tmux/`)

- Core file `.tmux.conf` only orchestrates plugin includes + keymaps/options split: `tmux.keymaps.conf`, `tmux.options.conf`. Preserve this layering; put new key bindings in `tmux.keymaps.conf` unless they are plugin‑specific (then create a dedicated `plugins/tmux.<name>.conf`).
- Prefix is `M-d` (Alt+d). Any helper docs or references should reflect that (avoid assuming default `C-b`).
- Visual + theme cohesion (Catppuccin + custom cursor styles) must not be broken; reuse existing color tokens when adjusting selection styles.

### 5. Terminal / Editor Ecosystem Integration

- `ghostty` keybind remaps translate macOS `cmd+<key>` to escape sequences consumed by zsh, tmux, and Neovim. When proposing new shortcuts ensure they do not collide with existing sequences in `ghostty/config` and are representable in tmux & nvim (avoid ambiguous ESC chains).
- Cross‑tool theme consistency: Catppuccin Mocha across Ghostty, Neovim, tmux, lazygit, atuin. If adding a new themed tool, align its palette with existing hex codes already present (e.g. `#89b4fa`, `#f38ba8`).

### 6. Tool Version & Runtime Management

- `mise/.config/mise/config.toml` pins versions (`go`, `node`). If suggesting adding a new language tool, add under `[tools]` and prefer stable semver over `latest`.
- PATH adjustments happen in `.zshenv` / `.zshrc`; do not sprinkle PATH exports in random plugin files.

### 7. Editing / Contribution Norms for the Assistant

- Be explicit about the target file(s) and minimal diff; avoid broad rewrites.
- Before adding a new abstraction in Neovim Lua, check for existing helpers in `lua/utils/` (e.g. `buffer.lua`, `tab.lua`, `path.lua`) and extend them if logically related.
- Do not invent testing frameworks—this repo isn’t test‑driven code; changes are manual & experiential.
- Preserve comments citing upstream references / links; they document intentional deviations (e.g. disabled default Vim plugins list in lazy config).

### 8. Safe Change Examples

- Adding a plugin: create `lua/plugins/ui/awesome-plugin.lua` returning spec table; add only plugin‑specific logic + keymaps inside its own file.
- Adding a ZSH function: create `zsh/.config/zsh/functions/rgf` containing function body; autoload handles it. Do not edit autoload loop.
- Adding a tmux plugin: append `set -g @plugin 'author/repo'` + create `plugins/tmux.<repo>.conf` with scoped settings; source it from `.tmux.conf` like existing patterns.

### 9. Things NOT To Do

- Don’t merge multiple plugin specs into a monolithic file.
- Don’t hardcode user-specific absolute paths (except where already present and unavoidable, e.g. Homebrew in evalcache lines).
- Don’t introduce unrelated tooling (Dockerfiles, language servers) unless the directory clearly uses them.
- Don’t refactor away lightweight fork hooks or remove “fork” comments—they are intentional for upstream parity.

### 10. When Uncertain

- If a change affects multi‑tool keybinding harmony (Ghostty ↔ tmux ↔ Neovim), outline the sequence flow before implementing.
- If proposing a structural shift (new directory, renaming categories), pause and request confirmation.

Feedback Welcome: Let me know if any area (lazy loading rules, keybinding collision policy, theme palette usage) needs deeper clarification, and I can provide more anchors.
