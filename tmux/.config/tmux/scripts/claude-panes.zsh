#!/bin/zsh -f
# The panes running Claude Code directly, one line per pane whose foreground job is an interactive
# session:
#
#   <pane id> <target> <pid> <status> <session id>
#
# tab-separated, <target> being <session>:<window>.<pane> (a pane that grouped sessions share gets
# a line per session) and <status> one of idle, busy and waiting. The zsh function tsave reads it
# to end those sessions, and resurrect-snapshots.zsh to save the command that resumes each one.
# Exits 1 when Claude Code can't list its sessions.
#
# `claude agents --json` is Claude Code's own list of live sessions, and a session belongs to the
# pane on whose tty its process is in the foreground. That leaves out what a pane doesn't run
# itself: a Claude in a pane nvim's terminal (nvim's own tty), a background session (its daemon's),
# and one suspended with Ctrl-Z

setopt pipe_fail

# No Claude Code, no panes running it
(( $+commands[claude] )) || exit 0

local sessions line pid tty stat pane target
local -a fields
local -A status_of session_of claude_on
sessions=$(claude agents --json </dev/null |
  jq -r '.[] | select(.kind == "interactive") | [.pid, .status, .sessionId] | @tsv') || exit 1
for line in ${(f)sessions}; do
  fields=("${(@ps:\t:)line}")
  status_of[$fields[1]]=$fields[2]
  session_of[$fields[1]]=$fields[3]
done
(( $#status_of )) || exit 0

# `+`: in the foreground process group of its tty
ps -o pid=,tty=,stat= -p ${(kj:,:)status_of} | while read -r pid tty stat; do
  [[ $stat == *+* ]] && claude_on[$tty]=$pid
done

tmux list-panes -a -F $'#{pane_id}\t#{session_name}:#{window_index}.#{pane_index}\t#{pane_tty}' |
  while IFS=$'\t' read -r pane target tty; do
    pid=$claude_on[${tty#/dev/}]
    [[ -n $pid ]] && print -r -- $pane$'\t'$target$'\t'$pid$'\t'$status_of[$pid]$'\t'$session_of[$pid]
  done
exit 0
