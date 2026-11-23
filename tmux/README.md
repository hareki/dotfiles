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

The zsh functions `tsave` and `trestore` drive tmux-resurrect, and `scripts/resurrect-snapshots.zsh` owns the snapshot store: how resurrect names and replaces the files, which one `last` points at, the ids, the listing and the expiry. Both functions go through it, and so do resurrect's two hooks (after a save: expiry and the command that resumes each Claude Code session; before a restore from scratch: the placeholder session). Terms: [docs/GLOSSARY.md](./docs/GLOSSARY.md).

- **`tsave`**: snapshots every session, then quits each pane's nvim through its normal exit (so auto-session saves its session), one at a time, ends each pane's Claude Code session with SIGTERM (its clean exit: the SessionEnd hooks run) and kills the server
  - **`-c`/`--continue`**: snapshot only, leaving nvim, Claude Code and tmux running, like resurrect's own `prefix C-s`
  - Nothing is quit or killed while an nvim holds work a kill would lose: unsaved buffers, a nested nvim in a terminal buffer, a suspended nvim, or one it can't reach. Pane nvims publish their RPC address as the `@nvim-server` pane option for this (nvim's `core/auto-session/tsave.lua`)
  - Nor while a Claude Code session in a pane is anything but `idle`: `busy` (in the middle of a turn) or `waiting` (on a permission prompt or a dialog), so interrupt or answer it first. That counts the one in a pane nvim's terminal (claudecode.nvim), which the nvim's quit would end
  - From a pane nvim's terminal (`<A-t>`), it reruns itself from the tmux server so that nvim can quit too, and shows its report in view mode on that pane (`q` closes it)
- **`trestore [<id>]`**: restores a snapshot into a fresh server, from inside tmux or from a plain terminal
  - Without an id it restores `last`, the snapshot most recently saved or restored (also what `prefix C-r` restores)
  - Ids are the snapshot's date and time (`2026-11-04_20-15-30`); `trestore <TAB>` and `trestore --list` show them newest first
  - **`--force`**: restore into a server that already has panes (resurrect leaves those as they are), or, from a plain terminal, into a server already running, whose lone pane the restore replaces
- **Expiry**: resurrect's post-save hook (`resurrect-snapshots.zsh post-save`) deletes snapshots 3 days after their last save. The snapshot `last` pointed to before a save survives that save, so a stray save can't take the one you meant to restore. An unchanged layout restarts its snapshot's clock, which is also how `tsave` knows that save happened
- **nvim relaunch**: nvim panes relaunch as `nvim .` in nvim's directory, so auto-session reopens that directory's session. An `nvim <file>` pane comes back as its directory's session, not the file
- **Claude Code relaunch**: a pane running `claude` directly relaunches as `claude --resume <session id>`, the same conversation under the same id, whatever saved the snapshot (`tsave` or `prefix C-s`)
  - `scripts/claude-panes.zsh` finds those panes: the sessions `claude agents --json` lists, each matched to the pane whose tty its process is on, or else the nearest of its ancestors that is on one (a pane nvim's terminal is a tty of nvim's own). The session in the foreground of the pane's tty is the one the pane runs, and the post-save hook writes its resume command into the snapshot
  - The flags it was started with are not kept, and a session nothing was asked in yet has no conversation to resume, so its pane relaunches a bare `claude`
  - Not ended by `tsave` and not relaunched: a Claude in a pane nvim's terminal, which ends with that nvim, and one suspended with Ctrl-Z, which the server's kill takes. `tsave` still refuses until either is `idle`. The agents view is left alone, and background sessions belong to Claude Code's daemon, not to a pane

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

- **[docs/GLOSSARY.md](./docs/GLOSSARY.md)**: the terms for the status bar and the snapshots
- **[zsh/README.md](../zsh/README.md#-commands)**: `tsave`, `trestore` and `mux`, the commands that drive this config
