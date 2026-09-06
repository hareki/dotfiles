# Self-heal for the "prompt goes dead until Ctrl+C" state (keys echo, no
# highlighting, suggestions or bindings): the tty was put back into cooked mode
# (icanon/echo) while zle was still reading the line, so the kernel echoes and
# buffers keys until Enter and zle never sees them.
#
# Node.js does this on exit: it restores the termios it captured at startup and
# blocks SIGTTOU around the tcsetattr, so a node process born under a foreground
# command (an nx executor that outlives Ctrl+C, say) re-cooks the tty when it
# finally exits. Nothing inside zsh itself does it, so the only fix is to poll.
#
# sched only fires while zle is idle in its input loop, so a running command
# costs nothing. Each tick is one stty fork. An empty `zle -M` trashes and
# refreshes the display, which is the same resetneeded => zrefresh => zsetterm
# path Ctrl+C takes to put the tty back into raw mode. Only the redraw is
# wanted, so the message is empty and the heal leaves nothing on screen.

zmodload zsh/sched
zmodload -F zsh/system p:sysparams

_tty_guard_tick() {
  # forked copies of this shell (zpty children run zle too) inherit the sched entry
  [[ $sysparams[pid] == $_tty_guard_pid ]] || return 0
  sched +2 _tty_guard_tick
  zle && [[ -n $TTY ]] || return 0
  local g
  g=$(command stty -f $TTY -g 2>/dev/null) || return 0
  local lflag=${${g#*:lflag=}%%:*}
  # ICANON (0x100) or ECHO (0x8) set while zle is reading: cooked
  (( 0x$lflag & 0x108 )) || return 0
  zle -M ''
}

# re-sourcing .zshrc must not stack a second ticker
(( $+_tty_guard_pid )) || {
  typeset -g _tty_guard_pid=$sysparams[pid]
  sched +2 _tty_guard_tick
}
