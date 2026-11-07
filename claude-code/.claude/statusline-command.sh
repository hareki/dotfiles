#!/bin/bash
# Claude Code status line: mirrors Powerlevel10k Pure/Catppuccin Mocha style

input=$(</dev/stdin)
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

# Every field the status line reads, in one jq pass. Joined on U+001F rather than
# whitespace so that an absent field stays empty instead of collapsing into its
# neighbour and shifting all the later ones. The `exec` here and in the git call
# below saves a fork: with a redirect attached, bash keeps the subshell around.
IFS=$'\037' read -r cwd used session_pct week_pct model_id display_name effort_level session_name <<<"$(
  exec jq -r '[
    .workspace.current_dir,
    .context_window.used_percentage,
    .rate_limits.five_hour.used_percentage,
    .rate_limits.seven_day.used_percentage,
    .model.id,
    .model.display_name,
    .effort.level,
    .session_name
  ] | join("\u001f")' <<<"$input")"

# Git info (skip lock to avoid blocking). One porcelain=v2 call carries the branch,
# the upstream ahead/behind counts and every dirty or untracked entry. An entry only
# sets the dirty flag, so renames aren't worth detecting, and edits inside a submodule
# don't count, as in p10k (which also spares a git spawn in there).
branch="" dirty="" sync=""
while IFS= read -r line; do
  case $line in
    '# branch.oid '*)           oid=${line#'# branch.oid '} ;;
    # A detached HEAD reports "(detached)"; show the short sha, as p10k does.
    '# branch.head (detached)') branch="@${oid:0:8}" ;;
    '# branch.head '*)          branch=${line#'# branch.head '} ;;
    '# branch.ab +0 -0')        ;;
    '# branch.ab +0 '*)         sync=" ⇣" ;;
    '# branch.ab '*' -0')       sync=" ⇡" ;;
    '# branch.ab '*)            sync=" ⇣⇡" ;;
    # Entries follow the headers, so the first one settles it.
    [!#]*)                      dirty="*"; break ;;
  esac
done <<<"$(exec git --no-optional-locks -C "$cwd" status --porcelain=v2 --branch \
  --no-renames --ignore-submodules=dirty 2>/dev/null)"

# Usage group: context plus the 5h session and 7d week rate limits. Rate limits are
# absent until the first API response (and for non-Pro/Max). An absent figure reads
# "nil" (overlay1); otherwise icon and number are both colorized by threshold.
usage_segment() {
  local pct=${1%.*} icon=$2 color=$green
  if [ -z "$pct" ]; then
    printf "${overlay1}%s nil${reset}" "$icon"
    return
  fi
  if [ "$pct" -gt 90 ]; then
    color=$red
  elif [ "$pct" -gt 70 ]; then
    color=$yellow
  fi
  printf "${color}%s %s%%${reset}" "$icon" "$pct"
}

# Model: short family name inferred from the model id
# (display_name is verbose, e.g. "Opus 4.8 (1M context)")
case "$model_id" in
  *haiku*)  model="Haiku";  model_color="$green" ;;
  *sonnet*) model="Sonnet"; model_color="$yellow" ;;
  *opus*)   model="Opus";   model_color="$red" ;;
  *fable*)  model="Fable";  model_color="$red" ;;
  *)        model="$display_name"; model_color="$overlay1" ;;
esac

# Reasoning effort: shown next to the model name, colored by intensity.
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

# Session name: custom name (--name / /rename) when set, otherwise the
# auto-generated conversation title. The field is absent only when the session has
# neither, i.e. exactly the default display name this line deliberately hides.
[ -z "$session_name" ] && session_name="new session"

printf "${model_color}%s${reset}" "$model"
[ -n "$effort" ] && printf " ${effort_color}%s${reset}" "$effort"

# Usage group: [  4% | 󰥔 30% |   21%] - brackets & pipes in subtext1
printf " ${subtext1}[${reset}"
usage_segment "$used" ''
printf "${subtext1} | ${reset}"
usage_segment "$session_pct" '󰥔'
printf "${subtext1} | ${reset}"
usage_segment "$week_pct" ''
printf "${subtext1}]${reset} "

# printf " ${blue}%s${reset}" "${cwd/#$HOME/\~}"
[ -n "$branch" ] && printf " ${subtext1}%s${reset}" "$branch$dirty"
[ -n "$sync" ] && printf "${teal}%s${reset}" "$sync"
printf " ${overlay1}%s${reset}" "$session_name"
