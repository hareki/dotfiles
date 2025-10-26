#!/bin/zsh

_sync_d_autocomplete() {
  local -a dirs
  local repo_dir="$STOW_REPO"

  # Get a list of directories under $STOW_REPO excluding .git and feed them into completion
  dirs=(${(f)"$(fd --type d --max-depth 1 --exclude .git --base-directory $repo_dir --exec basename {})"})
  _describe 'stow directories' dirs
}

compdef _sync_d_autocomplete sync-d

_tv_autocomplete() {
  local -a files
  local cable_dir="$HOME/.config/television/cable"

  # Get list of files in cable directory, strip extensions
  if [[ -d "$cable_dir" ]]; then
    files=(${(f)"$(fd --type f --max-depth 1 --base-directory $cable_dir --exec basename {} | sed 's/\.[^.]*$//')"})
    _describe 'television cables' files
  fi
}

compdef _tv_autocomplete tv