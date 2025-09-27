## AI Assistant Project Instructions (tmux dotfiles)

Purpose: This repo is a modular tmux configuration. The root `.tmux.conf` is an orchestrator that sets up plugins (via TPM) and incrementally sources focused config files under `.config/tmux/`.

### Core Structure

- `.tmux.conf`: Entry point. Order matters: general keymaps/options first, then plugin declarations (`set -g @plugin ...`), then per‑plugin `source-file` lines, finally `run '~/.tmux/plugins/tpm/tpm'` to bootstrap TPM.
- `.config/tmux/tmux.keymaps.conf`: All key bindings (reload, splits, copy-mode tweaks, navigation helpers). Keep NON-plugin keymaps here.
- `.config/tmux/tmux.options.conf`: Session/window/pane behavioral options, terminal features, styling (cursor, mouse, truecolor, undercurl, copy-mode styles, focus, passthrough).
- `.config/tmux/plugins/`: One file per plugin named `tmux.<plugin-name>.conf` (convention); each sets only that plugin’s `@plugin`-scoped variables / mappings.

### Reload & Test Workflow

- Prefix is remapped to `M-d` (Meta/Alt + d). Avoid assuming the default `C-b`.
- Reload config: `Prefix (M-d) + r` (bound in `tmux.keymaps.conf`). Non-interactive alternative: `tmux source-file ~/.tmux.conf`.
- For experimental edits, open a disposable session: `tmux new -s test` before changing an existing workflow session.

### Key Customizations (Summarize for Context)

- Window & pane indices start at 1 (`base-index`, `pane-base-index`).
- Split bindings: `Prefix + -` (vertical), `Prefix + \\` (horizontal).
- Navigation with Vim inside tmux uses `vim-tmux-navigator` but remapped: Meta-m/n/e/i for Left/Down/Up/Right (see its plugin config file).
- Copy mode: Vi mode, custom PageUp/PageDown half-page recenters; `v` begins selection (char-wise); `Escape` enters copy-mode.
- Floating / overlay pane behavior via custom `hareki/tmux-floax`: toggle key is raw `M-t` (no prefix) and menu via `T` when pane toggled. Respect Neovim passthrough flag.

### Plugin Layer

Declared plugins (in order) currently:

1. `tpm` (manager) – must remain first.
2. `tmux-yank` (config file placeholder currently empty: safe to extend there).
3. `hareki/tmux-floax` (floating pane UX variables in its config).
4. `hareki/tmux-catppuccin` (theme & statusline segment variables; modifies status-left/right and colors; flavor set to mocha; dynamic session color on prefix state).
5. `christoomey/vim-tmux-navigator` (custom Meta mappings override defaults; removed the default C-\ binding).
6. `tmux-resurrect` (persistence dir overridden to `~/.local/share/tmux/resurrect`).
7. `tmux-continuum` (auto-save interval 15 min; auto-restore disabled — do NOT enable without user intent).

### Theming & Terminal Capabilities

- Truecolor + undercurl enabled via `terminal-features` and `terminal-overrides` additions; preserve these when adding overrides (append with commas, do not replace existing values).
- Cursor styles: both normal and prompt cursor explicitly set (prefer bar style for consistency with external tools like lazygit).
- Catppuccin statusline segments assembled manually: additional right segments appended with `-ag`. When altering order, edit only the sequence of `status-right` / `-ag` lines inside the catppuccin plugin config file, not in `.tmux.conf`.

### Adding a New Plugin (Follow This Pattern)

1. Add `set -g @plugin 'author/repo'` near related plugins in `.tmux.conf` (group thematically if possible: visual/theme vs navigation vs productivity).
2. Create `.config/tmux/plugins/tmux.<short-name>.conf` containing only its `@` variables / binds.
3. Add `source-file ~/.config/tmux/plugins/tmux.<short-name>.conf` immediately after the plugin line in `.tmux.conf`.
4. Reload, then install via TPM: `Prefix + I` (capital i). Update later with `Prefix + U`.

### Safe Editing Conventions

- Keep cross-cutting edits (indices, prefix, mouse, terminal overrides) in `tmux.options.conf` — do NOT scatter them.
- Avoid redefining bindings directly in plugin config files unless they are plugin-specific variables; core keymaps live in `tmux.keymaps.conf`.
- Empty plugin config files (e.g., `tmux.tmux-yank.conf`) signal future customization spots — populate rather than creating a new file.

### When Adjusting Statusline

- Modify Catppuccin-related variables (icons, colors, text formats) only inside its plugin config; they rely on theme variable interpolation (`#{@thm_*}`) and conditional expressions (`#{?client_prefix,...}`) — preserve those patterns.

### Persistence & Sessions

- `tmux-resurrect` storage path customized: scripts or docs referencing defaults must use `~/.local/share/tmux/resurrect`.
- Auto-restore off by choice; enabling `@continuum-restore 'on'` changes startup behavior — flag in PR description if you propose this.

### Cross-Tool Integration Notes

- Options like `allow-passthrough on` and `visual-activity off` coordinate with Neovim image preview (e.g., image.nvim) — retain when refactoring.
- Truecolor & undercurl are required for theming consistency; do not remove even if seemingly redundant.

### PR / Change Review Hints (For Generated Changes)

- Provide a short rationale comment above any newly added non-obvious `terminal-overrides` or `terminal-features` entries.
- Ensure new key bindings do not collide with existing Meta-based navigation (M-d prefix, M-m/n/e/i directional, M-t floater toggle).

Feedback: If any section lacks context you need for future automations (e.g., desired plugin grouping rules or test session patterns), ask and we can expand this file incrementally.
