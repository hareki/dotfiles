# Tmux config

A personal tmux setup: TPM plugins, a Catppuccin status bar, and snapshots of every session, taken and restored by hand from the shell.

## Language

### Snapshots

**Snapshot**:
A tmux-resurrect save of every session's windows and panes, with each pane's directory and program, named by the second it was taken.
_Avoid_: backup, save file, session file

**Snapshot id**:
A snapshot's date and time as the commands show it and accept it, such as 2026-11-04_20-15-30.
_Avoid_: timestamp, snapshot name

**Last**:
The snapshot a restore picks when given none: the one most recently saved or restored.
_Avoid_: latest, current snapshot

**Snapshot store**:
The snapshots on disk together with their rules: how they are named, which one is last, how they are listed and when they expire.
_Avoid_: resurrect dir, backup folder

**Expiry**:
The removal of a snapshot three days after it was last saved; saving a layout identical to last counts as saving that snapshot again.
_Avoid_: pruning, cleanup

**Restore from scratch**:
A restore into a server holding a single pane, whose placeholder session the restored sessions replace.
_Avoid_: fresh restore, cold restore

**Placeholder session**:
The one unnamed session a server starts with, so that a restore from scratch has somewhere to run.
_Avoid_: dummy session
