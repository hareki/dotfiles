#!/bin/zsh

# Completions for autoloaded functions live in `function-compdef/`, one file per
# function, and are sourced by .zshrc so they work before the first call.

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
