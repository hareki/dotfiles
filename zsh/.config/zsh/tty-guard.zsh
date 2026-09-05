# Temporary self-heal + capture for the intermittent "prompt goes dead until
# Ctrl+C" bug (highlighting, suggestions and bindings all stop, keys echo).
#
# That state is the tty being put back into cooked mode (icanon/echo) while zle
# is still reading the line: the kernel echoes and buffers keys until Enter, so
# zle never sees them. Ctrl+C recovers because zle restarts and re-runs
# zsetterm(). Nothing inside zsh 5.9 does this on its own (every restore of the
# cooked settings is followed by a zsetterm), so another process flips the
# termios asynchronously and this file catches it in the act.
#
# sched only fires while zle is idle in its input loop, so a running command
# costs nothing. Each tick is one stty fork. A cooked tty triggers a report to
# $TTY_GUARD_LOG, then `zle -M` trashes and refreshes the display, which is the
# same resetneeded => zrefresh => zsetterm path Ctrl+C takes.

zmodload zsh/sched zsh/datetime
zmodload -F zsh/system p:sysparams

typeset -g TTY_GUARD_LOG=${TTY_GUARD_LOG:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh-tty-guard.log}
typeset -g _tty_guard_cmd _tty_guard_cmd_status _tty_guard_snapshot _tty_guard_cooked
typeset -gF _tty_guard_prompt_at _tty_guard_cmd_at

_tty_guard_preexec() {
  _tty_guard_cmd=$1
  _tty_guard_cmd_at=$EPOCHREALTIME
  # hend() has just restored this shell's own cooked settings; a report that
  # matches them byte for byte points at a forked copy of this shell restoring
  # shttyinfo on the inherited tty fd
  [[ -n $_tty_guard_cooked || -z $TTY ]] || _tty_guard_cooked=$(command stty -f $TTY -g 2>/dev/null)
}

_tty_guard_precmd() {
  _tty_guard_cmd_status=$?
  # zsh-defer replays precmd hooks from inside zle after each deferred load
  zle && return 0
  _tty_guard_prompt_at=$EPOCHREALTIME
  _tty_guard_snapshot=
}

_tty_guard_tick() {
  # forked copies of this shell (zpty children run zle too) inherit the sched entry
  [[ $sysparams[pid] == $_tty_guard_pid ]] || return 0
  sched +2 _tty_guard_tick
  zle && [[ -n $TTY ]] || return 0
  local g
  g=$(command stty -f $TTY -g 2>/dev/null) || return 0
  # what is still attached to the tty once the shell has gone idle after the last command
  [[ -n $_tty_guard_snapshot ]] ||
    _tty_guard_snapshot=$(command ps -o pid,ppid,pgid,tpgid,stat,etime,command -t ${TTY#/dev/} 2>&1)
  local lflag=${${g#*:lflag=}%%:*}
  # ICANON (0x100) or ECHO (0x8) set while zle is reading: cooked
  (( 0x$lflag & 0x108 )) || return 0
  _tty_guard_report "$g"
  zle -M "tty-guard: tty was cooked under zle, restored raw mode (report in $TTY_GUARD_LOG)"
}

_tty_guard_report() {
  local tty=${TTY#/dev/} now=$EPOCHREALTIME
  {
    print -r -- "===== $(strftime '%F %T' $EPOCHSECONDS) pid=$$ tty=$TTY pane=${TMUX_PANE:-none}${NVIM:+ nvim-terminal}"
    print -r -- "since prompt: $(( now - _tty_guard_prompt_at ))s"
    print -r -- "last command (exit ${_tty_guard_cmd_status:-?}, ran $(( _tty_guard_cmd_at ? _tty_guard_prompt_at - _tty_guard_cmd_at : 0 ))s): ${_tty_guard_cmd:-<none>}"
    print -r -- "stty -g now:    $1"
    print -r -- "stty -g cooked: ${_tty_guard_cooked:-<no command run yet>}  (this shell's own settings between commands)"
    command stty -f $TTY -a
    print -r -- "--- zle -F handlers"
    zle -F -L
    print -r -- "--- jobs"
    jobs -l
    print -r -- "--- processes on $tty now (tpgid should be $$)"
    command ps -o pid,ppid,pgid,tpgid,stat,etime,command -t $tty
    print -r -- "--- processes on $tty at the first idle tick after the prompt"
    print -r -- "$_tty_guard_snapshot"
    print -r -- "--- processes in this shell's process group (may change the tty without SIGTTOU)"
    command ps -axo pid,ppid,pgid,stat,etime,command | awk -v g=$$ 'NR == 1 || $3 == g'
    print -r -- "--- lsof $TTY"
    /usr/sbin/lsof -w $TTY
    print
  } >>$TTY_GUARD_LOG 2>&1
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _tty_guard_preexec
add-zsh-hook precmd _tty_guard_precmd

# re-sourcing .zshrc must not stack a second ticker
(( $+_tty_guard_pid )) || {
  typeset -g _tty_guard_pid=$sysparams[pid]
  sched +2 _tty_guard_tick
}
