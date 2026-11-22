<h1 align="center">hareki's Ghostty config</h1>

<hr>

<h4 align="center">
  <a href="#-getting-started">Install</a>
  ·
  <a href="#%EF%B8%8F-keybindings">Keybindings</a>
  ·
  <a href="#-file-structure">Files</a>
</h4>

<div align="center"><p>
    <a href="https://github.com/hareki/dotfiles/commits/main/ghostty">
      <img alt="Last commit" src="https://img.shields.io/github/last-commit/hareki/dotfiles?path=ghostty&style=for-the-badge&logo=starship&color=8bd5ca&logoColor=D9E0EE&labelColor=302D41" />
    </a>
    <a href="https://github.com/hareki/dotfiles/blob/main/LICENSE.md">
      <img alt="License" src="https://img.shields.io/github/license/hareki/dotfiles?style=for-the-badge&logo=starship&color=ee999f&logoColor=D9E0EE&labelColor=302D41" />
    </a>
</p></div>

A [Ghostty](https://ghostty.org/) config in Catppuccin Mocha whose keybindings turn
<kbd>Cmd</kbd> keys into escape sequences, so tmux, Neovim and zsh can bind them.

## ✨ Features

- ⌨️ <kbd>Cmd</kbd> keys send <kbd>Alt</kbd> sequences, which a terminal app can bind and <kbd>Cmd</kbd> keys never reach
- 🔀 Shifted keys tunnel through `CSI 1;6` sequences, which Neovim reads as function keys
- 🔤 [Maple Mono NF](https://github.com/subframe7536/maple-font) SemiBold, with ligatures
- 🎨 Catppuccin Mocha with a hidden title bar and a faint background image
- 📋 Copy on select, straight to the clipboard

## 🤔 What is it?

- A personal config for one machine: macOS, tmux with prefix <kbd>Alt-d</kbd>, Neovim and zsh
  vi mode inside it.

- Every <kbd>Cmd</kbd> binding is the matching <kbd>Alt</kbd> key, so the bindings live in the
  app that handles them: `tmux/keymaps.conf`, Neovim's keymaps, `zsh/keymaps.zsh`.

- Shell integration runs with `no-cursor`, so Ghostty leaves the cursor shape to zsh's vi mode.

## ⚡️ Requirements

- **[Ghostty](https://ghostty.org/)** on macOS
- **[Maple Mono NF](https://github.com/subframe7536/maple-font)**, the Nerd Font build

## 🚀 Getting Started

The config lives in my [dotfiles](https://github.com/hareki/dotfiles), which
[GNU Stow](https://www.gnu.org/software/stow/) links into `$HOME`.

<details><summary>Install with Stow</summary>

- Clone the dotfiles and link the `ghostty` package:

  ```sh
  git clone https://github.com/hareki/dotfiles ~/dotfiles
  stow -d ~/dotfiles -t ~ ghostty
  ```

- Restart Ghostty, or reload its config with <kbd>Cmd-Shift-,</kbd>.

</details>

## ⌨️ Keybindings

`macos-option-as-alt` makes <kbd>Option</kbd> an <kbd>Alt</kbd> key too. The <kbd>Cmd</kbd> keys:

- **<kbd>Cmd-d</kbd>**: the tmux prefix
- **<kbd>Cmd-[</kbd>** / **<kbd>Cmd-]</kbd>**: previous / next tmux window. They send <kbd>Alt-h</kbd> / <kbd>Alt-l</kbd>, since `ESC [` starts a control sequence
- **<kbd>Cmd-m</kbd>/<kbd>n</kbd>/<kbd>e</kbd>/<kbd>i</kbd>**: move left, down, up and right across tmux panes and Neovim windows
- **<kbd>Cmd-a</kbd>**: Claude Code in Neovim (claudecode.nvim)
- **<kbd>Cmd-g</kbd>**: lazygit in Neovim
- **<kbd>Cmd-t</kbd>**: Neovim's floating terminal
- **<kbd>Cmd-p</kbd>**: Claude Code's model picker, or the Snacks picker's preview toggle
- **<kbd>Cmd-w</kbd>**: close the Neovim buffer
- **<kbd>Cmd-s</kbd>**: format and save in Neovim
- **<kbd>Cmd-r</kbd>**: reload the Neovim buffer
- **<kbd>Cmd-f</kbd>**: atuin history search in zsh
- **<kbd>Cmd-Space</kbd>**: open blink.cmp's menu in Neovim (the AI items when it is already open), Tab in zsh

The shifted keys, which a plain <kbd>Alt</kbd> sequence can't carry:

- **<kbd>Cmd-Shift-s</kbd>**: format and save all, <kbd>F40</kbd> in Neovim
- **<kbd>Cmd-Shift-w</kbd>**: close the other buffers, <kbd>Ctrl-Shift-End</kbd> in Neovim
- **<kbd>Ctrl-m</kbd>**: toggle a multicursor.nvim cursor, <kbd>F37</kbd> in Neovim
- **<kbd>Ctrl-Shift-y</kbd>**: `forward-word` in zsh, which accepts the autosuggestion's next word
- **<kbd>Shift-Enter</kbd>**: a new line in Claude Code

## 📂 File Structure

<pre>
~/.config/ghostty
├── config               theme, font, cursor, shell integration, keybindings
└── background-images    the background image, at 5.5% opacity
</pre>
