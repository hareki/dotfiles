# Neovim config

A personal Neovim setup: plugins filed by tier and domain, wired together through a few shared modules, plus the tools outside nvim that reach into it (lazygit, its diff renderer, the shell).

## Language

### Layout

**Tier**:
One of the three layers plugin specs are filed in: core (what everything else stands on), chrome (what the screen shows) and features (what the user does).
_Avoid_: layer, level

**Domain**:
A group of features serving one kind of work: navigation, completion, git, editing, search, diagnostics, formatting, ai, preview.
_Avoid_: category, area

**Spec**:
A lazy.nvim plugin spec: the table, or the file returning it, that says how and when a plugin loads.
_Avoid_: plugin file; spec for a test file

**Fragment**:
One of the specs a plugin bundling unrelated features is split into, each filed with the domain its feature serves.
_Avoid_: partial spec, sub-spec

**Entry point**:
A module that something outside nvim reaches by its path, such as lazygit's remote edit or the diff renderer's filetype rules.
_Avoid_: API, hook

**Defer proxy**:
A stand-in for a module that loads it on first use.
_Avoid_: lazy module, wrapper

### Editing

**Style enforcer**:
The run that formats and fixes a buffer, then saves it: its steps in a fixed order, one run per buffer at a time, ended by a time limit.
_Avoid_: save pipeline, formatter, linter

**Step**:
One stage of a style enforcer run: conform's formatting, or one language server's formatting or fixing.
_Avoid_: enforcer, linter, runner

**Built-in keymap**:
A key Neovim itself defines, whether a default mapping, a map an ftplugin sets, or a command such as `za`, whose title this config sets.
_Avoid_: default keymap, registry entry

**Language alias**:
A filetype whose text parses with another filetype's tree-sitter language, as mdx does with markdown.
_Avoid_: filetype mapping

### Windows

**Popup**:
A float tied to the window it opened from: it borrows keys there and closes once that window moves on.
_Avoid_: tooltip, overlay

**Source window**:
The window a popup opened from.

**Full-screen panel**:
A float over the whole editor: lazygit and the coding agent.
_Avoid_: modal, fullscreen terminal

**Picker source**:
What one picker lists and how: its finder, item format, confirm action and keys.
_Avoid_: picker, for the definition

**Pin**:
A file kept in harpoon's numbered list.
_Avoid_: mark, bookmark

**Integration**:
The reduced mode nvim runs in when another tool (lazygit, git, the coding agent) opens it as its editor.
_Avoid_: embedded mode

### Verification

**Test file**:
A file in tests/ whose tests run together in one booted nvim.
_Avoid_: spec

**A/B dump**:
Everything a fully booted config defines, written out row by row so two configs compare with a plain diff.
_Avoid_: snapshot
