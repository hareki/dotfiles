# Sourced by the test files whose panes run Claude Code: a stand-in for `claude`, holding what tsave
# and the snapshot store (through the tmux package's claude-panes.zsh) reach of the real one:
#
# - `claude [--resume <id>]` is a session: a foreground job that SIGTERM ends, whose id is the
#   resumed one, or else $ZT_CLAUDE_SESSION
# - `claude agents --json` lists the sessions running, each with the status in $ZT_TMP/claude/status
#
# A session leaves its arguments in $ZT_TMP/claude/started, and its id in $ZT_TMP/claude/ended once
# SIGTERM has ended it
#
#   zt_claude                  puts the stand-in first on PATH; before the tmux server starts, as
#                              its panes and resurrect's hooks get the server's PATH
#   zt_claude_in <pane> [<keys>]  types <keys> into the pane (`claude`, for its shell) and waits for
#                              the session that starts, whose pid it leaves in REPLY

zmodload zsh/zselect

typeset -g ZT_CLAUDE_SESSION=5f0c9c1e-7d3a-4b6e-9a51-2e8d4c7b1a90

zt_claude() {
  local dir=$ZT_TMP/claude
  mkdir -p $dir/running $ZT_TMP/bin
  print idle >$dir/status
  cat >$ZT_TMP/bin/claude <<EOF
#!/bin/zsh -f
zmodload zsh/zselect
if [[ \$1 == agents ]]; then
  local session
  local -a sessions
  for session in $dir/running/*(N); do
    sessions+=("{\"pid\": \${session:t}, \"kind\": \"interactive\", \"status\": \"\$(<$dir/status)\", \"sessionId\": \"\$(<\$session)\"}")
  done
  print -r -- "[\${(j:, :)sessions}]"
  exit
fi

print -r -- "\$*" >>$dir/started
local id=$ZT_CLAUDE_SESSION
[[ \$1 == --resume ]] && id=\$2
print -r -- \$id >$dir/running/\$\$
trap "rm $dir/running/\$\$; print -r -- \$id >>$dir/ended; exit 143" TERM
while :; do zselect -t 10; done
EOF
  chmod +x $ZT_TMP/bin/claude
  path=($ZT_TMP/bin $path)
}

zt_claude_in() {
  local -a before=($ZT_TMP/claude/running/*(N)) new
  tmux send-keys -t $1 ${2:-claude} Enter
  repeat 80; do
    new=($ZT_TMP/claude/running/*(N))
    new=(${new:|before})
    if (( $#new )); then
      REPLY=${new:t}
      return 0
    fi
    zselect -t 10
  done
  print -ru2 -- "zt_claude_in: no session started in $1"
  return 1
}
