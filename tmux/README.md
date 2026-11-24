<h1 align="center">hareki's tmux config</h1>

<hr>

<h4 align="center">
  <a href="#-getting-started">Install</a>
  ·
  <a href="#-plugins">Plugins</a>
  ·
  <a href="#-snapshots">Snapshots</a>
</h4>

<div align="center"><p>
    <a href="https://github.com/tmux/tmux/releases">
      <img alt="tmux 3.6+" src="https://img.shields.io/badge/tmux-3.6%2B-a6e3a1?style=for-the-badge&logo=tmux&logoColor=D9E0EE&labelColor=302D41" />
    </a>
    <a href="https://github.com/hareki/dotfiles/commits/main/tmux">
      <img alt="Last commit" src="https://img.shields.io/github/last-commit/hareki/dotfiles?path=tmux&style=for-the-badge&logo=starship&color=8bd5ca&logoColor=D9E0EE&labelColor=302D41" />
    </a>
    <a href="https://github.com/hareki/dotfiles/blob/main/LICENSE.md">
      <img alt="License" src="https://img.shields.io/github/license/hareki/dotfiles?style=for-the-badge&logo=starship&color=ee999f&logoColor=D9E0EE&labelColor=302D41" />
    </a>
</p></div>

A tmux config managed by TPM, built around Neovim: pane moves shared with it, vi copy mode, image
passthrough for Snacks, and snapshots of every session that bring back each pane's Neovim and
Claude Code session.

![image](./assets/docs/demo.jpg)

## ✨ Features

- ⌨️ Prefix <kbd>Alt-d</kbd>, which Ghostty sends for <kbd>Cmd-d</kbd>
- 🪟 <kbd>Alt-m</kbd>/<kbd>n</kbd>/<kbd>e</kbd>/<kbd>i</kbd> move between tmux panes and Neovim windows alike, through [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)
- 📋 Vi copy mode that yanks to the system clipboard with OSC 52 and `pbcopy`, no plugin
- 🖼️ Image passthrough for [snacks.image](https://github.com/folke/snacks.nvim/blob/main/docs/image.md)
- 💾 `tsave` / `trestore` snapshots that relaunch Neovim and resume Claude Code conversations
- 🎨 Catppuccin Mocha status bar at the top, from a fork of [catppuccin/tmux](https://github.com/catppuccin/tmux)

## 🤔 What is it?

- A personal config for one machine: macOS, Ghostty sending <kbd>Cmd</kbd> keys as
  <kbd>Alt</kbd>, Neovim running in most panes.

- `tmux.conf` only wires things up. It sources `options.conf` and `keymaps.conf`, then each
  plugin's own config from `plugins/`.

- Snapshots are taken by hand, never on a timer (no tmux-continuum). The zsh functions drive
  tmux-resurrect, and `scripts/` owns the snapshot files and finds the Claude Code sessions in
  the panes.

## ⚡️ Requirements

- **[tmux](https://github.com/tmux/tmux) 3.6+**, for the pane scrollbars. The zsh `build` function builds it from source
- **[Ghostty](https://ghostty.org/)** or another terminal with true color, undercurl and the kitty graphics protocol
- **[Nerd Font](https://www.nerdfonts.com/)** for the status bar icons
- **[zsh config](../zsh/)** from these dotfiles, for `tsave`, `trestore` and `mux`

## 🚀 Getting Started

The config lives in my [dotfiles](https://github.com/hareki/dotfiles), which
[GNU Stow](https://www.gnu.org/software/stow/) links into `$HOME`.

<details><summary>Install with Stow</summary>

- Clone the dotfiles and link the `tmux` package:

  ```sh
  git clone https://github.com/hareki/dotfiles ~/dotfiles
  stow -d ~/dotfiles -t ~ tmux
  ```

- Bootstrap TPM once:

  ```sh
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  ```

- Start tmux and install the plugins with <kbd>prefix</kbd> <kbd>I</kbd>.

</details>

TPM installs the plugins into `~/.tmux/plugins/`, pinned with `TMUX_PLUGIN_MANAGER_PATH`. Without
the pin, an XDG-located `tmux.conf` would make TPM install them into `~/.config/tmux/plugins/`,
which is this stowed directory. The `plugins/` directory here only holds their configs.

## 📦 Plugins

- Plugin management with [TPM](https://github.com/tmux-plugins/tpm)
- Status bar and theme with [tmux-catppuccin](https://github.com/hareki/tmux-catppuccin), a fork of [catppuccin/tmux](https://github.com/catppuccin/tmux), plus hand-built modules it lacks (`catppuccin-modules/zoom.conf`, the pane zoom indicator)
- Session snapshots with [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect), taken by hand only
- Pane moves across Neovim and tmux with [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator). Its tmux half is bound directly in `plugins/vim-tmux-navigator.conf` rather than loaded through TPM

The copy-mode yank keys need no plugin: tmux's `set-clipboard` sends each copy as OSC 52, and
`copy-command` pipes it to `pbcopy`.

## ⌨️ Keymaps

- **<kbd>prefix</kbd> <kbd>R</kbd>**: reload the config
- **<kbd>prefix</kbd> <kbd>-</kbd>** / **<kbd>prefix</kbd> <kbd>\\</kbd>**: split below / to the right
- **<kbd>prefix</kbd> <kbd>n</kbd>** / **<kbd>prefix</kbd> <kbd>N</kbd>**: new window / new session
- **<kbd>prefix</kbd> <kbd>r</kbd>**: rename the window
- **<kbd>prefix</kbd> <kbd>Left</kbd>** / **<kbd>Right</kbd>**: move the window left or right
- **<kbd>Alt-h</kbd>** / **<kbd>Alt-l</kbd>**: previous / next window, no prefix (Ghostty's <kbd>Cmd-[</kbd> / <kbd>Cmd-]</kbd>)
- **<kbd>prefix</kbd> <kbd>Esc</kbd>**: copy mode, where <kbd>v</kbd> selects, <kbd>h</kbd> yanks to the clipboard and <kbd>k</kbd> yanks and pastes

## 💾 Snapshots

`tsave` and `trestore` are zsh wrappers around tmux-resurrect. `scripts/resurrect-snapshots.zsh` manages the snapshot files for both of them and for resurrect's hooks. Terms: [GLOSSARY.md](./GLOSSARY.md).

- **`tsave`**: snapshots every session, quits each pane's nvim and Claude Code cleanly so they save their own state, then kills the server
  - **`-c`/`--continue`**: snapshot only and keep everything running, like `prefix C-s`
  - Quits nothing while an nvim has unsaved work or a Claude Code session is busy or waiting on a prompt
- **`trestore [<id>]`**: restores a snapshot into a fresh server. Without an id it restores `last`, the most recently saved or restored one, like `prefix C-r`
  - Ids are timestamps (`2026-11-04_20-15-30`). `trestore --list` and `trestore <TAB>` show them newest first
  - **`--force`**: restore into a server that is already running
- **Expiry**: snapshots are deleted 3 days after their last save. A save never deletes the snapshot `last` pointed to before it
- **Relaunch**: nvim panes reopen as `nvim .`, so auto-session restores the directory's session. `claude` panes come back as `claude --resume <session id>`, the same conversation without the original flags

## 📂 File Structure

<pre>
~/.config/tmux
├── tmux.conf                   entry point: sources everything, then the TPM plugins
├── options.conf                terminal, mouse, true color, image passthrough
├── keymaps.conf                keybindings, except pane navigation
├── typos.toml                  typos-lsp allowlist (@thm_* palette vars)
├── plugins
│   ├── catppuccin.conf         status bar layout, pane borders, icons, copy-mode and menu colors
│   ├── catppuccin-modules/     status modules catppuccin lacks (zoom.conf)
│   ├── vim-tmux-navigator.conf pane navigation keys, shared with Neovim
│   └── resurrect.conf          snapshot dir, the hooks, nvim and Claude Code relaunch
└── scripts
    ├── resurrect-snapshots.zsh the snapshot files: save, list, select, and resurrect's hooks
    └── claude-panes.zsh        the Claude Code sessions in the panes, with each one's id and status
</pre>

## 📚 Docs

- **[GLOSSARY.md](./GLOSSARY.md)**: the terms for the status bar and the snapshots
- **[zsh/README.md](../zsh/README.md#-commands)**: `tsave`, `trestore` and `mux`, the commands that drive this config
