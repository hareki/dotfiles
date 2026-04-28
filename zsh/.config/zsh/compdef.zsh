#!/bin/zsh

_sync_dots_autocomplete() {
  local -a items
  local repo_dir="$STOW_REPO"
  local d

  items=(
    '--help:Show usage info'
    'all:Sync every package directory in $STOW_REPO'
  )

  # Get a list of directories under $STOW_REPO excluding .git and feed them into completion
  for d in ${(f)"$(fd --type d --max-depth 1 --exclude .git --base-directory $repo_dir --exec basename {})"}; do
    items+=("${d}:Sync ${d} configs")
  done

  _describe 'stow directories' items
}

compdef _sync_dots_autocomplete sync-dots

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
  commands=(${(f)"$(tmuxinator commands zsh)"})
  projects=(${(f)"$(tmuxinator completions start)"})

  if (( CURRENT == 2 )); then
    _alternative \
      'commands:: _describe -t commands "tmuxinator subcommands" commands' \
      'projects:: _describe -t projects "tmuxinator projects" projects'
  elif (( CURRENT == 3)); then
    case $words[2] in
      copy|cp|c|debug|delete|rm|open|o|start|s|stop|edit|e)
        _arguments '*:projects:($projects)'
      ;;
    esac
  fi

  return
}

compdef _tmuxinator tmuxinator
