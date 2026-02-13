#!/usr/bin/env bash
# Claude Code status line — mirrors Powerlevel10k Pure/Catppuccin Mocha style
# Colors: blue=#89b4fa, grey_vcs=#bac2de, grey=#7f849c, yellow=#f9e2af, cyan=#94e2d5, mauve=#cba6f7

input=$(cat)

blue='\033[38;2;137;180;250m'    # #89b4fa
grey_vcs='\033[38;2;186;194;222m' # #bac2de
grey='\033[38;2;127;132;156m'    # #7f849c
yellow='\033[38;2;249;226;175m'  # #f9e2af
cyan='\033[38;2;148;226;213m'    # #94e2d5
mauve='\033[38;2;203;166;247m'    # #cba6f7
reset='\033[0m'

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
# Shorten home directory to ~
cwd="${cwd/#$HOME/\~}"

# Git info (skip lock to avoid blocking)
git_info=""
if git --no-optional-locks -C "${cwd/#\~/$HOME}" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "${cwd/#\~/$HOME}" symbolic-ref --short HEAD 2>/dev/null \
           || git -C "${cwd/#\~/$HOME}" rev-parse --short HEAD 2>/dev/null | sed 's/^/@/')
  dirty=""
  if ! git --no-optional-locks -C "${cwd/#\~/$HOME}" diff --quiet 2>/dev/null \
     || ! git --no-optional-locks -C "${cwd/#\~/$HOME}" diff --cached --quiet 2>/dev/null \
     || [ -n "$(git -C "${cwd/#\~/$HOME}" ls-files --others --exclude-standard 2>/dev/null)" ]; then
    dirty="*"
  fi
  ahead=$(git -C "${cwd/#\~/$HOME}" rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
  behind=$(git -C "${cwd/#\~/$HOME}" rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
  sync=""
  if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
    sync=" ⇣⇡"
  elif [ "$ahead" -gt 0 ]; then
    sync=" ⇡"
  elif [ "$behind" -gt 0 ]; then
    sync=" ⇣"
  fi
  git_info="${branch}${dirty}"
fi

# Context window
context_info=""
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used" ]; then
  used_int=${used%.*}
  context_info=" ${used_int}%"
fi

# Model
model=$(echo "$input" | jq -r '.model.display_name // empty')

# Time
time_str=$(date +"%I:%M:%S %p")

[ -n "$model" ] && printf "${mauve}%s${reset}" "$model"
[ -n "$context_info" ] && printf " ${yellow}context%s${reset}" "$context_info"
# printf " ${blue}%s${reset}" "$cwd"
[ -n "$git_info" ] && printf " ${grey_vcs}%s${reset}" "$git_info"
[ -n "$sync" ] && printf "${cyan}%s${reset}" "$sync"
printf " ${grey}%s${reset}" "$time_str"
