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

_tv_autocomplete() {
  local -a files
  local cable_dir="$HOME/.config/television/cable"
  local file_path

  # Get list of files in cable directory and strip extensions
  if [[ -d "$cable_dir" ]]; then
    for file_path in "$cable_dir"/*(.N); do
      files+=("${${file_path:t}%.*}")
    done
    _describe 'television cables' files
  fi
}

compdef _tv_autocomplete tv

_build_autocomplete() {
  local -a targets
  targets=(
    '--help:Show usage info'
    'all:Build every target'
    'atuin:Build atuin from ~/Repositories/personal/atuin'
    'eza:Build eza from ~/Repositories/personal/eza'
    'television:Build television from ~/Repositories/personal/television'
    'worktrunk:Build worktrunk from ~/Repositories/personal/worktrunk'
    'lazygit:Build lazygit from ~/Repositories/personal/lazygit'
    'tmux:Build tmux from ~/Repositories/personal/tmux'
  )
  _describe 'build targets' targets
}

compdef _build_autocomplete build

# https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.zsh
_tmuxinator_autocomplete() {
  local commands projects

  if (( CURRENT == 2 )); then
    commands=(${(f)"$(tmuxinator commands zsh)"})
    projects=(${(f)"$(tmuxinator completions start)"})
    _alternative \
      'commands:: _describe -t commands "tmuxinator subcommands" commands' \
      'projects:: _describe -t projects "tmuxinator projects" projects'
  elif (( CURRENT == 3)); then
    case $words[2] in
      copy|cp|c|debug|delete|rm|open|o|start|s|stop|edit|e)
        projects=(${(f)"$(tmuxinator completions start)"})
        _arguments '*:projects:($projects)'
      ;;
    esac
  fi

  return
}

compdef _tmuxinator_autocomplete tmuxinator
