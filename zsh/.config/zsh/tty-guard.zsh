# Heals a prompt gone dead (keys echo until Ctrl+C) after an exiting node process
# restores its cooked startup termios: an empty `zle -M` takes Ctrl+C's path to raw mode

zmodload zsh/sched
zmodload -F zsh/system p:sysparams

_tty_guard_tick() {
  # forked copies of this shell (zpty children run zle too) inherit the sched entry
  [[ $sysparams[pid] == $_tty_guard_pid ]] || return 0
  sched +2 _tty_guard_tick
  zle || return 0
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
