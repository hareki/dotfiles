#!/bin/bash
# Claude Code status line — mirrors Powerlevel10k Pure/Catppuccin Mocha style

input=$(cat)
# echo "$input" > /tmp/sl_debug.json # status line debug info

blue='\033[38;2;137;180;250m'    # #89b4fa
subtext1='\033[38;2;186;194;222m' # #bac2de
overlay1='\033[38;2;127;132;156m'    # #7f849c
yellow='\033[38;2;249;226;175m'  # #f9e2af
green='\033[38;2;166;227;161m'  # #a6e3a1
red='\033[38;2;243;139;168m'  # #f38ba8
cyan='\033[38;2;148;226;213m'    # #94e2d5
mauve='\033[38;2;203;166;247m'    # #cba6f7
peach='\033[38;2;250;179;135m'    # #fab387
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

# Usage group — context (always) plus 5h session & 7d week rate limits.
# Rate limits are absent until the first API response (and for non-Pro/Max),
# so each is included only when present. Threshold colors mirror the context.
usage_color() {
  if [ "$1" -gt 90 ]; then
    printf '%s' "$red"
  elif [ "$1" -gt 70 ]; then
    printf '%s' "$yellow"
  else
    printf '%s' "$green"
  fi
}

usage_segments=()

# Each segment: icon and number both colorized by threshold.

# Context window (always shown, defaults to 0%)
used=$(echo "$input" | jq -r '.context_window.used_percentage // "0"')
used_int=${used%.*}
usage_segments+=("$(usage_color "$used_int") ${used_int}%${reset}")

# 5h session window — only when present
session_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
if [ -n "$session_pct" ]; then
  session_int=${session_pct%.*}
  usage_segments+=("$(usage_color "$session_int")󰥔 ${session_int}%${reset}")
fi

# 7d week window — only when present
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
if [ -n "$week_pct" ]; then
  week_int=${week_pct%.*}
  usage_segments+=("$(usage_color "$week_int") ${week_int}%${reset}")
fi

# Model — short family name inferred from the model id
# (display_name is verbose, e.g. "Opus 4.8 (1M context)")
model_id=$(echo "$input" | jq -r '.model.id // empty')
case "$model_id" in
  *opus*)   model="Opus";   model_color="$red" ;;
  *sonnet*) model="Sonnet"; model_color="$yellow" ;;
  *haiku*)  model="Haiku";  model_color="$green" ;;
  *fable*)  model="Fable";  model_color="$peach" ;;
  *)        model=$(echo "$input" | jq -r '.model.display_name // empty'); model_color="$overlay1" ;;
esac

# Session name — custom name (--name / /rename) when set, otherwise the
# auto-generated conversation title from Claude Code's session store (by session_id).
session_name=$(echo "$input" | jq -r '.session_name // empty')
if [ -z "$session_name" ]; then
  sid=$(echo "$input" | jq -r '.session_id // empty')
  if [ -n "$sid" ]; then
    session_file=$(grep -l "$sid" ~/.claude/sessions/*.json 2>/dev/null | head -1)
    if [ -n "$session_file" ]; then
      session_name=$(jq -r 'if .nameSource == "derived" then "new session" else (.name // empty) end' "$session_file" 2>/dev/null)
    fi
  fi
fi

[ -n "$model" ] && printf "${model_color}%s${reset}" "$model"

# Usage group: [ 4% | 󰥔 30% |  21%] - brackets & pipes in subtext1
printf " ${subtext1}[${reset}"
for i in "${!usage_segments[@]}"; do
  [ "$i" -gt 0 ] && printf "${subtext1} | ${reset}"
  printf '%b' "${usage_segments[$i]}"
done
printf "${subtext1}]${reset} "

# printf " ${blue}%s${reset}" "$cwd"
[ -n "$git_info" ] && printf " ${subtext1}%s${reset}" "$git_info"
[ -n "$sync" ] && printf "${cyan}%s${reset}" "$sync"
[ -n "$session_name" ] && printf " ${overlay1}%s${reset}" "$session_name"
