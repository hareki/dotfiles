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
  for d in "$repo_dir"/*(/N); do
    items+=("${d:t}:Sync ${d:t} configs")
  done

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
    'lazygit:Build lazygit from ~/Repositories/personal/lazygit'
    'television:Build television from ~/Repositories/personal/television'
    'tmux:Build tmux from ~/Repositories/personal/tmux'
  )
  _describe 'build targets' targets
}

compdef _build_autocomplete build

_git_bwt_autocomplete() {
  local -a items
  if (( CURRENT == 2 )); then
    items=(
      '--help:Show usage info'
    )
    _describe 'git-bwt arguments' items
  fi
  # second positional arg is a free-form <remote-url>; no completion offered
}

compdef _git_bwt_autocomplete git-bwt

# https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.zsh
_tmuxinator() {
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

compdef _tmuxinator tmuxinator
