# AGENTS.md

## Overview

Personal Neovim 0.12+ configuration using the lazy.nvim plugin manager. `docs/GLOSSARY.md` defines the terms this file, the docs, the skills and the code use.

`CLAUDE.md` is a symlink to this file and `.claude/skills` to `.agents/skills`: edit the real files. Keep every line under 1000 characters, since some views trim longer lines and a trimmed copy written back once deleted a rule.

## LuaLS Diagnostics

The LuaLS diagnostics surfaced to you come from the `nvim-lua-lsp@dotfiles` plugin, which gives the server LuaJIT, Neovim's runtime and the lazy plugin dir, so its reports are real, except in scratch files outside the repo, where it flags the globals from `config/globals.lua` as undefined. When it flags `vim` itself as an undefined global, the session runs the official `lua-lsp` instead (started outside the dotfiles), and its `undefined-global`, `undefined-doc-name` and `undefined-field` reports on `vim` or plugin names and types are **false positives**: ignore them.

## Code Style

Before writing or reviewing Lua, or naming a file or directory, read `docs/conventions/code-style.md`.

- **Nerd Font glyphs**: change a file that holds them (`config/icons.lua` among them) through anchored replacements, never a full rewrite, which has silently dropped private-use glyphs; a glyph can display as an empty string, so check one with `xxd` before treating it as empty

## Commands

- **Format**: run `stylua .` after editing Lua
- **Test**: every headless nvim boot goes through `tests/run.sh`, `tests/probe.sh` or `tests/ab.sh`, which apply the rules in `tests/lib/env.sh`, each of which cost a real incident: never override `XDG_DATA_HOME`, never dump the environment, and end a boot with `os.exit`
