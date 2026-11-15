# ctb's flag file, through the three that spell its path: ctb, which creates and removes it, and
# Claude Code's Stop hook and status line (claude-code/.claude), which read it. Moved in one of them
# alone, the bell would never mute or the status line never say so

source $ZT_LIB/helpers.zsh

autoload -Uz $ZT_PKG/.config/zsh/functions/ctb
claude=$ZT_REPO/claude-code/.claude

# afplay, first on PATH: a line per sound a hook plays
mkdir -p $ZT_TMP/bin
print -rl -- '#!/bin/sh' "echo \"\$1\" >>$ZT_TMP/played" >$ZT_TMP/bin/afplay
chmod +x $ZT_TMP/bin/afplay
path=($ZT_TMP/bin $path)

# rings <hook>: how many sounds the hook plays for a main agent that is done. A hook leaves its
# sound playing in the background, which the trap waits out, so none lands in a later count
rings() {
  local -a played
  : >$ZT_TMP/played
  bash -c 'trap wait EXIT; . "$0"' $claude/hooks/$1 <<<'{"background_tasks": []}'
  played=(${(f)"$(<$ZT_TMP/played)"})
  print -r -- $#played
}

# bar: the status line of a session in a dir that is no repo, without SGR escapes
bar() {
  bash $claude/statusline-command.sh >$ZT_TMP/bar 2>&1 \
    <<<'{"workspace": {"current_dir": "'$ZT_TMP'"}, "session_id": "zt"}'
  t_plain $ZT_TMP/bar
}

# toggle: ctb's exit status and what it prints
toggle() {
  t_run $ZT_TMP/out $ZT_TMP/err ctb
  print -r -- "$? $(t_plain $ZT_TMP/out)$(<$ZT_TMP/err)"
}

t_eq 'unmuted: the Stop hook rings' $(rings bell-when-done.sh) 1
local unmuted=$(bar)

t_match 'ctb mutes' "$(toggle)" '0 BELL OFF *'
t_eq 'muted: the Stop hook stays quiet' $(rings bell-when-done.sh) 0
t_match 'muted: the status line says so' "$(bar)" "${(b)unmuted} ?*"
t_eq 'muted: a permission prompt still rings' $(rings bell.sh) 1

t_match 'ctb again unmutes' "$(toggle)" '0 BELL ON *'
t_eq 'unmuted again: the Stop hook rings' $(rings bell-when-done.sh) 1
t_eq 'unmuted again: the status line is as it was' "$(bar)" "$unmuted"

t_done
