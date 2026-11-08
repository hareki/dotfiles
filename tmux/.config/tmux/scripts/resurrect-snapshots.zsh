#!/bin/zsh -f
# The tmux-resurrect snapshots in @resurrect-dir: how resurrect names and replaces them, which one
# `last` points at, and when they expire. The zsh functions tsave and trestore call it, and
# resurrect runs `prune` after every save (plugins/resurrect.conf):
#
#   save           snapshot every session now and print `saved <id>` or `unchanged <id>`;
#                  exit 1 without tmux-resurrect, 2 when nothing was saved
#   list           one `<id>  <when>, <n> sessions, <n> windows[, last]` line per snapshot, newest
#                  first (_trestore splits a line at its two spaces)
#   select [<id>]  point `last` at <id>, or without one check that `last` exists; exit 1 when the
#                  snapshot doesn't
#   prune <file>   the post-save-layout hook, <file> being the save resurrect just wrote
#   pre-restore    the pre-restore-all hook
#
# An id is a snapshot's date and time: 2026-11-04_20-15-30 is tmux_resurrect_20261104T201530.txt

zmodload zsh/datetime
zmodload -F zsh/stat b:zstat

# Sets REPLY to the snapshot dir; without a server, to the path resurrect.conf pins
snapshot_dir() {
  REPLY=$(tmux show-option -gqv @resurrect-dir 2>/dev/null)
  [[ -n $REPLY ]] || REPLY=$HOME/.local/share/tmux/resurrect
}

# Sets REPLY to the file `last` points at (empty when there is none)
last_of() {
  local -a link
  zstat -L -A link +link $1/last 2>/dev/null
  REPLY=$link[1]
}

# Sets REPLY to the id of a snapshot file name
id_of() {
  local ts=${${1:t:r}#tmux_resurrect_}
  REPLY=${ts[1,4]}-${ts[5,6]}-${ts[7,8]}_${ts[10,11]}-${ts[12,13]}-${ts[14,15]}
}

save() {
  local script dir prev now start
  script=$(tmux show-option -gqv @resurrect-save-script-path 2>/dev/null)
  [[ -n $script ]] || return 1
  snapshot_dir
  dir=$REPLY
  last_of $dir
  prev=$REPLY

  # Resurrect names snapshots by the second, and a second save within one deletes itself
  strftime -s now %Y%m%dT%H%M%S $EPOCHSECONDS
  [[ $prev == tmux_resurrect_$now.txt ]] && sleep 1

  # save.sh exits 0 whatever happens, so `last` (re)written from here on is the proof. An unchanged
  # layout rewrites nothing, but `prune` touches `last` for it
  start=$EPOCHSECONDS
  tmux run-shell "$script quiet"
  [[ -f $dir/last ]] && (( $(zstat +mtime $dir/last) >= start )) || return 2

  last_of $dir
  local snap=$REPLY
  id_of $snap
  if [[ $snap == $prev ]]; then
    print -r -- "unchanged $REPLY"
  else
    print -r -- "saved $REPLY"
  fi
}

list() {
  snapshot_dir
  local dir=$REPLY today yesterday noon
  strftime -s today %Y%m%d $EPOCHSECONDS
  # From today's noon, so a DST shift can't land on the wrong day
  strftime -r -s noon '%Y%m%d %H' "$today 12"
  strftime -s yesterday %Y%m%d $(( noon - 86400 ))

  last_of $dir
  local prev=$REPLY f ts epoch when s w mark
  local -a lines sessions windows
  for f in $dir/tmux_resurrect_*.txt(N.On); do
    ts=${${f:t:r}#tmux_resurrect_}
    strftime -r -s epoch %Y%m%dT%H%M%S $ts
    case ${ts[1,8]} in
      $today) strftime -s when 'today %H:%M' $epoch ;;
      $yesterday) strftime -s when 'yesterday %H:%M' $epoch ;;
      *) strftime -s when '%a %H:%M' $epoch ;;
    esac

    lines=(${(f)"$(<$f)"})
    sessions=(${(u)${${(M)lines:#pane$'\t'*}#pane$'\t'}%%$'\t'*})
    windows=(${(M)lines:#window$'\t'*})
    s=s w=s mark=
    (( $#sessions == 1 )) && s=
    (( $#windows == 1 )) && w=
    [[ ${f:t} == $prev ]] && mark=', last'
    id_of $f
    print -r -- "$REPLY  $when, $#sessions session$s, $#windows window$w$mark"
  done
}

select_snapshot() {
  snapshot_dir
  local dir=$REPLY
  if [[ -z $1 ]]; then
    [[ -e $dir/last ]]
    return
  fi
  local file=tmux_resurrect_${${1//-/}/_/T}.txt
  [[ -f $dir/$file ]] && ln -fs $file $dir/last
}

prune() {
  local new=$1 dir=${1:h} prev
  last_of $dir
  prev=$REPLY

  # Resurrect drops a save identical to `last` and keeps the older file: restart that file's clock,
  # since it is the layout being saved
  cmp -s $new $dir/last && touch $dir/last

  # Expired 3 days after their last save. The previous `last` survives this save, so a stray save
  # (prefix C-s in a fresh server) can't take the snapshot you meant to restore with it
  local -a expired=($dir/tmux_resurrect_*.txt(N.mm+4320))
  rm -f ${expired:#$dir/$prev}
}

# A restore from scratch (a lone pane) drops the placeholder session only when it's named 0, and
# this tmux build names unnamed sessions session-<id>. A one-line bash hook did this before, but
# macOS's bash 3.2 misparses a format inside "$(...)", which only bash 5 earlier on PATH hid
pre_restore() {
  local -a sessions=(${(f)"$(tmux list-panes -a -F '#{session_name}')"})
  (( $#sessions == 1 )) && [[ $sessions[1] == session-<-> ]] && tmux rename-session -t $sessions[1] 0
}

case $1 in
  save | list) $1 ;;
  select) select_snapshot $2 ;;
  prune) prune $2 ;;
  pre-restore) pre_restore ;;
  *)
    print -u2 -r -- "usage: ${0:t} save | list | select [<id>] | prune <file> | pre-restore"
    exit 64
    ;;
esac
