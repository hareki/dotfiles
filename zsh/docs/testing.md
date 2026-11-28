# Testing

Every harness here builds on `tests/lib/`. Each file in it, and each test file, opens with a header that says what it covers and how.

## Pick the run

- **A config change** (`.zshenv`, `.zshrc`, `.zplugins`, a module): `tests/ab.zsh [rev]`. Two boots of one tree dump identically, so every diff row is a change to account for, a module moved in the `.zshrc` loop included.
- **An override, or after `yay`**: `tests/run.zsh overrides`.
- **A command, or a file of another package**: run every test file that names it, since a file's name doesn't bound what it covers (`done-gate` covers Claude Code's hooks). `grep -l <name> tests/*.zsh` lists them, and `tests/run.zsh <words>` runs the files whose name contains a word.
- **A completion**: a TAB in a scratch boot that lists a candidate only that compdef can produce (e.g. `television` for `build t`).
- **Before a commit**: `tests/run.zsh` with no words runs every file side by side (~13s).

## Write a test

A test file drives a command through its own interface, with stand-ins for what it reaches, and asserts through `tests/lib/helpers.zsh`.

- **Booting the config**: `zt_home` and `zt_boot` in `tests/lib/env.zsh`, and `zt_server` for a private Rex server to start other shells in. A test's own questions for a booted shell go in a file `ZT_PROBE` names.
- **Driving git**: `zt_repos` in `tests/lib/repos.zsh`, before anything else touches git.
