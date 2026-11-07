#!/bin/sh
# tmux-resurrect's post-save-layout hook ($1: the snapshot just written, not yet
# compared with `last`). Expires snapshots 3 days after their last save
new=$1
dir=${new%/*}
prev=$(readlink "$dir/last")

# Resurrect drops a save identical to `last` and keeps the older file:
# restart that file's clock, since it is the layout being saved
cmp -s "$new" "$dir/last" && touch "$dir/last"

# The previous `last` survives this save, so a stray save (prefix C-s in a fresh
# server) can't take the snapshot you meant to restore with it
find "$dir" -maxdepth 1 -name 'tmux_resurrect_*.txt' ! -name "$prev" \
  -mmin +$((3 * 24 * 60)) -delete
