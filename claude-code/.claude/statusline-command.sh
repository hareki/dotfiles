#!/bin/bash
# Claude Code status line — mirrors Powerlevel10k Pure/Catppuccin Mocha style

input=$(cat)
# echo "$input" > /tmp/sl_debug.json # status line debug info

green='\033[38;2;166;227;161m' #a6e3a1
teal='\033[38;2;148;226;213m' #94e2d5
yellow='\033[38;2;249;226;175m' #f9e2af
peach='\033[38;2;250;179;135m' #fab387
red='\033[38;2;243;139;168m' #f38ba8
overlay1='\033[38;2;127;132;156m' #7f849c
subtext1='\033[38;2;186;194;222m' #bac2de
blue='\033[38;2;137;180;250m' #89b4fa
reset='\033[0m'

# `jq` first on $PATH is a mise shim, which costs ~115ms per spawn against ~3ms
# for the real binary. This script runs on every status line repaint.
jq_bin=/opt/homebrew/bin/jq
[ -x "$jq_bin" ] || jq_bin=jq

# Every field the status line reads, in one jq pass. Joined on U+001F rather than
# whitespace so that an absent field stays empty instead of collapsing into its
# neighbour and shifting all the later ones.
IFS=$'\037' read -r cwd used session_pct week_pct model_id display_name effort_level session_name <<<"$(
  "$jq_bin" -r '[
    .workspace.current_dir // .cwd,
    .context_window.used_percentage,
    .rate_limits.five_hour.used_percentage,
    .rate_limits.seven_day.used_percentage,
    .model.id,
    .model.display_name,
    .effort.level,
    .session_name
  ] | map(if . == null then "" else tostring end) | join("\u001f")' <<<"$input")"

# Git info (skip lock to avoid blocking). One porcelain=v2 call carries the branch,
# the upstream ahead/behind counts and every dirty or untracked entry.
git_info=""
sync=""
if git_status=$(git --no-optional-locks -C "$cwd" status --porcelain=v2 --branch 2>/dev/null); then
  branch=""
  ahead=0
  behind=0
  dirty=""
  while IFS= read -r line; do
    case $line in
      '# branch.head '*) branch=${line#'# branch.head '} ;;
      '# branch.ab '*)   ab=${line#'# branch.ab '}; ahead=${ab%% *}; behind=${ab#* } ;;
      '#'*)              ;;
      ?*)                dirty="*" ;;
    esac
  done <<<"$git_status"

  # A detached HEAD reports "(detached)"; show the short sha, as p10k does.
  [ "$branch" = '(detached)' ] && branch="@$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)"

  ahead=${ahead#+}
  behind=${behind#-}
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

# Each segment: icon and number both colorized by threshold — the number when
# present, "nil" (overlay1) otherwise.
add_usage_segment() {
  local pct=$1 icon=$2 int
  if [ -z "$pct" ]; then
    usage_segments+=("${overlay1}${icon} nil${reset}")
    return
  fi
  int=${pct%.*}
  usage_segments+=("$(usage_color "$int")${icon} ${int}%${reset}")
}

add_usage_segment "$used" ''
add_usage_segment "$session_pct" '󰥔'
add_usage_segment "$week_pct" ''

# Model — short family name inferred from the model id
# (display_name is verbose, e.g. "Opus 4.8 (1M context)")
case "$model_id" in
  *haiku*)  model="Haiku";  model_color="$green" ;;
  *sonnet*) model="Sonnet"; model_color="$yellow" ;;
  *opus*)   model="Opus";   model_color="$red" ;;
  *fable*)  model="Fable";  model_color="$red" ;;
  *)        model="$display_name"; model_color="$overlay1" ;;
esac

# Reasoning effort — shown next to the model name, colored by intensity
# (green = light, yellow = heavy, red = maximal).
case "$effort_level" in
  low)       effort="Low";       effort_color="$teal" ;;
  medium)    effort="Medium";    effort_color="$green" ;;
  high)      effort="High";      effort_color="$yellow" ;;
  xhigh)     effort="xHigh";     effort_color="$peach" ;;
  max)       effort="Max";       effort_color="$red" ;;
  # Ultracode is not a distinct effort level: it reports as "xhigh"
  # - Indistinguishable from plain xHigh in statusline script (no env/settings/JSON signal).
  # - It's advertised as "xHigh + dynamic workflows"
  # - Keep Ultracode in case they add a distinct signal later. 
  ultracode) effort="Ultracode"; effort_color="$red" ;;
  "")        effort="" ;;
  *)         effort=$(printf '%s' "$effort_level" | awk '{print toupper(substr($0,1,1)) substr($0,2)}'); effort_color="$overlay1" ;;
esac

# Session name — custom name (--name / /rename) when set, otherwise the
# auto-generated conversation title. The field is absent only when the session has
# neither, i.e. exactly the default display name this line deliberately hides.
[ -z "$session_name" ] && session_name="new session"

if [ -n "$model" ]; then
  printf "${model_color}%s${reset}" "$model"
  [ -n "$effort" ] && printf " ${effort_color}%s${reset}" "$effort"
fi

# Usage group: [  4% | 󰥔 30% |   21%] - brackets & pipes in subtext1
printf " ${subtext1}[${reset}"
for i in "${!usage_segments[@]}"; do
  [ "$i" -gt 0 ] && printf "${subtext1} | ${reset}"
  printf '%b' "${usage_segments[$i]}"
done
printf "${subtext1}]${reset} "

# printf " ${blue}%s${reset}" "${cwd/#$HOME/\~}"
[ -n "$git_info" ] && printf " ${subtext1}%s${reset}" "$git_info"
[ -n "$sync" ] && printf "${teal}%s${reset}" "$sync"
printf " ${overlay1}%s${reset}" "$session_name"
