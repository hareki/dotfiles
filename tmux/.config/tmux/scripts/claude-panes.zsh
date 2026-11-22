#!/bin/zsh -f
# The interactive Claude Code sessions in the panes, one line per session:
#
#   <pane id> <target> <pid> <status> <session id> <job>
#
# tab-separated, <target> being <session>:<window>.<pane> (a pane that grouped sessions share gets
# a line per session), <status> one of idle, busy and waiting, and <job> `foreground` for the
# session the pane runs as its foreground job or `within` for any other: one in a pane nvim's
# terminal, or one suspended with Ctrl-Z. The zsh function tsave reads it to end the foreground
# sessions and to refuse while any is busy, and resurrect-snapshots.zsh to save the command that
# resumes each foreground one. Exits 1 when Claude Code can't list its sessions.
#
# `claude agents --json` is Claude Code's own list of live sessions, and a session is in the pane
# whose tty its process is on, or else the nearest of its ancestors that is on one: a pane nvim's
# terminal is a tty of nvim's own, below the nvim on the pane's. That leaves out a background
# session, which is its daemon's

setopt pipe_fail

# No Claude Code, no panes running it
(( $+commands[claude] )) || exit 0

local sessions line pid ppid tty stat at job
local -a fields
local -A status_of session_of parent_of tty_of stat_of panes_on
sessions=$(claude agents --json </dev/null |
  jq -r '.[] | select(.kind == "interactive") | [.pid, .status, .sessionId] | @tsv') || exit 1
for line in ${(f)sessions}; do
  fields=("${(@ps:\t:)line}")
  status_of[$fields[1]]=$fields[2]
  session_of[$fields[1]]=$fields[3]
done
(( $#status_of )) || exit 0

# -u: to a client outside tmux without a UTF-8 locale, tmux prints each tab as `_`
for line in ${(f)"$(tmux -u list-panes -a -F $'#{pane_id}\t#{session_name}:#{window_index}.#{pane_index}\t#{pane_tty}')"}; do
  fields=("${(@ps:\t:)line}")
  panes_on[${fields[3]#/dev/}]+=$fields[1]$'\t'$fields[2]$'\n'
done

ps -axo pid=,ppid=,tty=,stat= | while read -r pid ppid tty stat; do
  parent_of[$pid]=$ppid
  tty_of[$pid]=$tty
  stat_of[$pid]=$stat
done

for pid in ${(k)status_of}; do
  at=$pid
  while [[ -n $at && -z $panes_on[$tty_of[$at]] ]]; do
    at=$parent_of[$at]
  done
  [[ -n $at ]] || continue
  job=within
  # `+`: in the foreground process group of its tty
  [[ $at == $pid && $stat_of[$pid] == *+* ]] && job=foreground
  for line in ${(f)panes_on[$tty_of[$at]]}; do
    print -r -- $line$'\t'$pid$'\t'$status_of[$pid]$'\t'$session_of[$pid]$'\t'$job
  done
done
exit 0
