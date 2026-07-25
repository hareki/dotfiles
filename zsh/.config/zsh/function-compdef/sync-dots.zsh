#!/bin/zsh

_sync_dots_autocomplete() {
  local -a items
  local repo_dir="$STOW_REPO"
  local d

  items=(
    '--help:Show usage info'
    'all:Sync every package directory in $STOW_REPO'
  )

  # Get package directories under $STOW_REPO and feed them into completion
  if [[ -n "$repo_dir" && -d "$repo_dir" ]]; then
    for d in "$repo_dir"/*(/N); do
      items+=("${d:t}:Sync ${d:t} configs")
    done
  fi

  _describe 'stow directories' items
}

compdef _sync_dots_autocomplete sync-dots
