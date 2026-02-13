#!/usr/bin/env bash
# Claude Code status line — mirrors Powerlevel10k Pure/Catppuccin Mocha style

input=$(cat)

blue='\033[38;2;137;180;250m'    # #89b4fa
grey_vcs='\033[38;2;186;194;222m' # #bac2de
grey='\033[38;2;127;132;156m'    # #7f849c
yellow='\033[38;2;249;226;175m'  # #f9e2af
green='\033[38;2;166;227;161m'  # #a6e3a1
red='\033[38;2;243;139;168m'  # #f38ba8
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
used=$(echo "$input" | jq -r '.context_window.used_percentage // "0"')
used_int=${used%.*}
if [ "$used_int" -gt 90 ]; then
  ctx_color="$red"
elif [ "$used_int" -gt 70 ]; then
  ctx_color="$yellow"
else
  ctx_color="$green"
fi
context_info=" ${used_int}%"

# Model (use model.id — display_name is bugged, see claude-code#18270)
model_id=$(echo "$input" | jq -r '.model.id // empty')
model_version=$(echo "$model_id" | sed -n 's/.*claude-[a-z]*-\([0-9]*\)-\([0-9]*\).*/\1.\2/p')
if [[ "$model_id" == *opus* ]]; then
  model="Opus${model_version:+ $model_version}"
  model_color="$red"
elif [[ "$model_id" == *sonnet* ]]; then
  model="Sonnet${model_version:+ $model_version}"
  model_color="$yellow"
elif [[ "$model_id" == *haiku* ]]; then
  model="Haiku${model_version:+ $model_version}"
  model_color="$green"
else
  model=""
  model_color="$grey"
fi

# Time
time_str=$(date +"%I:%M:%S %p")

[ -n "$model" ] && printf "${model_color}%s${reset}" "$model"
printf " ${ctx_color}context%s${reset}" "$context_info"
# printf " ${blue}%s${reset}" "$cwd"
[ -n "$git_info" ] && printf " ${grey_vcs}%s${reset}" "$git_info"
[ -n "$sync" ] && printf "${cyan}%s${reset}" "$sync"
printf " ${grey}%s${reset}" "$time_str"
