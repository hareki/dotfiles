<h1 align="center">hareki's dotfiles</h1>

<hr>

<h4 align="center">
  <a href="#-getting-started">Install</a>
  ·
  <a href="#-packages">Packages</a>
  ·
  <a href="#-docs">Docs</a>
</h4>

<div align="center"><p>
    <a href="#-packages">
      <img alt="25 packages" src="https://img.shields.io/badge/packages-25-89b4fa?style=for-the-badge&logo=gnubash&logoColor=D9E0EE&labelColor=302D41" />
    </a>
    <a href="https://github.com/hareki/dotfiles/commits/main">
      <img alt="Last commit" src="https://img.shields.io/github/last-commit/hareki/dotfiles?style=for-the-badge&logo=starship&color=8bd5ca&logoColor=D9E0EE&labelColor=302D41" />
    </a>
    <a href="https://github.com/hareki/dotfiles/blob/main/LICENSE.md">
      <img alt="License" src="https://img.shields.io/github/license/hareki/dotfiles?style=for-the-badge&logo=starship&color=ee999f&logoColor=D9E0EE&labelColor=302D41" />
    </a>
</p></div>

The configs for my macOS machine, one [GNU Stow](https://www.gnu.org/software/stow/) package per
tool. Each top-level directory mirrors its destination under `$HOME`, so `nvim/.config/nvim`
links to `~/.config/nvim` and `zsh/.zshrc` to `~/.zshrc`.

## ✨ Features

- 🚀 Neovim starts in ~28ms and zsh reaches its first prompt in ~45ms
- ⌨️ Rex sends each <kbd>Cmd</kbd> key as the key Neovim, zsh or Claude Code binds, and Neovim hands pane navigation back to Rex at its edge
- 🧩 lazygit's diff panel is drawn by codediff.nvim's diff engine, which a headless Neovim daemon runs
- 🤖 Claude Code's settings, hooks, status line and theme, plus one skill set shared by every agent
- 🍴 Plugin and tool forks under `hareki/*`, each rebased onto upstream by `sync-forks`
- 🎨 Catppuccin Mocha across Neovim, Rex, Ghostty, lazygit, fzf, atuin, bat, eza and Claude Code

## 🤔 What is it?

- A personal setup for one machine: macOS, Homebrew at `/opt/homebrew/`, Ghostty, mise. It is
  public so the ideas can be borrowed, not installed as is.

- Every package is a plain Stow package. `stow/.stow-global-ignore` keeps each package's
  README, AGENTS.md, docs and tests out of `$HOME`, so a package can carry its own docs and test
  suite next to the config it deploys.

- Neovim, zsh, lazygit's codediff and Hammerspoon have their own test suites, which boot the
  config in scratch environments. Neovim and zsh also have a `tests/ab` script that diffs what
  two revisions define, so a refactor can show it changed nothing.

## ⚡️ Requirements

- **macOS** with **[Homebrew](https://brew.sh/)** at `/opt/homebrew/`
- **[GNU Stow](https://www.gnu.org/software/stow/)**
- **[Ghostty](https://ghostty.org/)** and a **[Nerd Font](https://www.nerdfonts.com/)** ([Maple Mono NF](https://github.com/subframe7536/maple-font))
- **[mise](https://mise.jdx.dev/)** for the language toolchains and the npm-based tools

Each package's own requirements are in its README: [nvim](./nvim/README.md#%EF%B8%8F-requirements), [zsh](./zsh/README.md#%EF%B8%8F-requirements).

## 🚀 Getting Started

`sync-dots` expects the clone at `~/Repositories/personal/dotfiles` (`$STOW_REPO`).

<details><summary>Install with Stow</summary>

- Clone the repo:

  ```sh
  git clone https://github.com/hareki/dotfiles ~/Repositories/personal/dotfiles
  ```

- Link `stow` first, so its ignore list applies to the packages after it, then `zsh`. Stow
  refuses to replace a real file, so move any conflicting config out of the way:

  ```sh
  stow -d ~/Repositories/personal/dotfiles -t ~ stow zsh
  ```

- Open a new shell and link the rest:

  ```sh
  sync-dots all
  ```

</details>

<details><summary>Using <code>sync-dots</code></summary>

`sync-dots` (autoloaded from `zsh/.config/zsh/functions/sync-dots`) runs stow with the repo and
`$HOME` filled in, and completes package names. It restows, which also removes the links into the
repo that point at nothing, such as a removed package's. A package is a directory git has a file
in, so `all` unstows a removed package's directory that stays behind with only ignored files
(`.DS_Store`):

```sh
# One package
sync-dots nvim

# Several
sync-dots zsh rex ghostty lazygit mise atuin

# Every package directory in $STOW_REPO
sync-dots all

# The same thing with plain stow
stow -R -d "$STOW_REPO" -t ~ nvim
```

</details>

## 📦 Packages

### Editor and terminal

- **[nvim](./nvim/)**: a from-scratch Lua config on lazy.nvim, one spec file per plugin, one float layout for the picker, the file tree and their previews
- **[ghostty](./ghostty/)**: the terminal, with <kbd>Cmd</kbd> keybindings that emit escape sequences for Neovim and zsh
- **[rex](./rex/.config/rex/)**: the terminal and multiplexer, configured in Lua, prefix <kbd>Cmd-d</kbd>

### Shell

- **[zsh](./zsh/)**: one static Antidote bundle, a local `_evalcache`, autoloaded functions, vi mode with OSC52 yank
- **p10k**: the powerlevel10k prompt
- **zsh-patina**: syntax highlighting theme and config
- **atuin**: shell history search
- **television**: fuzzy finder channels for files, repos and these dotfiles
- **eza**, **bat**, **tealdeer**, **fastfetch**: `ls`, `cat`, `tldr` and `neofetch` replacements

### Git

- **[lazygit](./lazygit/)**: Neovim as the editor, and the codediff renderer for the diff panel
- **git**: global attributes
- **ssh**: host config

### Toolchains and formatters

- **mise**: Node, Ruby, Rust, Go, Python and Bun, plus the language servers, oxfmt, oxlint, prettier and mermaid-cli
- **prettier**, **typos**: global configs for the formatter and the spell checker
- **mermaid-cli**: the render config and a Puppeteer config that uses the system Chrome

### AI agents

- **claude-code**: Claude Code's settings, keybindings, hooks, status line, theme and output styles
- **agents**: the instructions and skills every agent shares. `claude-code/.claude/CLAUDE.md` and `skills/` link here

### macOS

- **[hammerspoon](./hammerspoon/)**: trackpad gestures, a two-finger double tap for <kbd>Cmd-W</kbd> and a three-finger one for <kbd>Cmd-Shift-T</kbd>
- **raycast-scripts**: Raycast script commands to cycle the audio output, focus Slack, toggle sleep prevention and toggle the VPN

### Repo plumbing

- **stow**: the global ignore list that keeps package docs and tests out of `$HOME`
- **bin**: wrappers in `~/.local/bin/shims` that pin a binary, add default flags or set the env for `claude`, `codegraph`, `mmdc`, `nvim-claude` and the lazygit diff renderer

## 📂 File Structure

<pre>
dotfiles
├── nvim/.config/nvim           => ~/.config/nvim
├── zsh/                        => ~/.zshenv, ~/.zshrc, ~/.config/zsh
├── rex/.config/rex             => ~/.config/rex
├── ghostty/.config/ghostty     => ~/.config/ghostty
├── lazygit/.config/lazygit     => ~/.config/lazygit
├── claude-code/.claude         => ~/.claude
├── agents/.agents              => ~/.agents
├── hammerspoon/.hammerspoon    => ~/.hammerspoon
├── bin/.local/bin/shims        => ~/.local/bin/shims
├── stow/.stow-global-ignore    => ~/.stow-global-ignore
├── ...                         the other packages, same pattern
└── GLOSSARY-MAP.md             how the packages' glossaries relate
</pre>

## 📚 Docs

- **[nvim/README.md](./nvim/README.md)**: the Neovim config, its plugins and its conventions
- **[zsh/README.md](./zsh/README.md)**: the zsh config, its commands and its startup measurements
- **[lazygit/GLOSSARY.md](./lazygit/GLOSSARY.md)**: lazygit's edit commands and the codediff renderer
- **[hammerspoon/README.md](./hammerspoon/README.md)**: setup and the gesture tests
- **[GLOSSARY-MAP.md](./GLOSSARY-MAP.md)**: the glossary of each config and where one config reaches into another

## 📄 License

[MIT](./LICENSE.md)
