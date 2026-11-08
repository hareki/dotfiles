# Zsh config

A personal zsh setup for macOS: a startup tuned for a fast first prompt, the commands built on top of it, and the tests that check both.

## Language

### Startup

**Shape**:
How a shell starts: as a top-level login shell (a terminal's first, at SHLVL 1), or as a login shell started from one (a tmux pane's).
_Avoid_: mode, kind

**Override**:
A line that presets or replaces a plugin's private variable, function or hook, to spare every shell work the plugin would otherwise do.
_Avoid_: patch, hack, monkey-patch

### Tests

**Scratch boot**:
A start of this config's shell in a throwaway home laid out like the deployed one, which reaches none of the machine's live keys, caches or servers.
_Avoid_: sandbox, test shell

**State dump**:
Everything a booted shell defines once its deferred plugins have loaded, written so that two boots compare line by line.
_Avoid_: snapshot (a tmux term), environment dump
