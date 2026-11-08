# The snapshot store (tmux/.config/tmux/scripts/resurrect-snapshots.zsh) and the commands on top of
# it, tsave and trestore, through their own interfaces: the listing on fixture files with no
# server, then saves, expiry, tsave and a restore from scratch with tmux-resurrect itself, in a
# private server that loads this tree's tmux config

source $ZT_LIB/helpers.zsh
source $ZT_LIB/env.zsh

zt_home $HOME $ZT_REPO || exit 1
autoload -Uz $ZT_PKG/.config/zsh/functions/{tsave,trestore}
store=$HOME/.config/tmux/scripts/resurrect-snapshots.zsh
dir=$HOME/.local/share/tmux/resurrect
# The panes run sh: nothing here needs a zsh config booting in each one
export SHELL=/bin/sh

# fixture <timestamp> <session>...: a snapshot file holding one window and one pane per session
fixture() {
  local ts=$1 s
  shift
  mkdir -p $dir
  for s in $@; do
    print -r -- "pane"$'\t'"$s"$'\t'"1"
    print -r -- "window"$'\t'"$s"$'\t'"1"
  done >$dir/tmux_resurrect_$ts.txt
}

# Sets REPLY to the id of a snapshot timestamp
id_of() {
  REPLY=${1[1,4]}-${1[5,6]}-${1[7,8]}_${1[10,11]}-${1[12,13]}-${1[14,15]}
}

# Waits until every window's name follows its pane's command: a save before automatic-rename gets
# there records the name the window started with, so two saves of one layout would differ
settle() {
  local -a same
  repeat 40; do
    same=(${(f)"$(tmux list-windows -a -F '#{==:#{window_name},#{pane_current_command}}')"})
    (( ${same[(I)0]} )) || return 0
    sleep 0.1
  done
}

local today yesterday older weekday noon
strftime -s today %Y%m%d $EPOCHSECONDS
strftime -r -s noon '%Y%m%d %H' "$today 12"
strftime -s yesterday %Y%m%d $(( noon - 86400 ))
strftime -s older %Y%m%d $(( noon - 5 * 86400 ))
strftime -s weekday %a $(( noon - 5 * 86400 ))

# No server: the store falls back to the dir resurrect.conf pins
fixture ${today}T100000 alpha beta
fixture ${yesterday}T093000 alpha
fixture ${older}T120000 alpha beta gamma
ln -s tmux_resurrect_${yesterday}T093000.txt $dir/last
local -a expected
id_of ${today}T100000
expected+=("$REPLY  today 10:00, 2 sessions, 2 windows")
id_of ${yesterday}T093000
expected+=("$REPLY  yesterday 09:30, 1 session, 1 window, last")
id_of ${older}T120000
local older_id=$REPLY
expected+=("$REPLY  $weekday 12:00, 3 sessions, 3 windows")
t_eq 'trestore --list: newest first, by day, with counts and last marked' "$(trestore --list)" "${(F)expected}"

$store select $older_id
t_eq 'select <id> succeeds' $? 0
t_eq 'select <id> points last at it' "$(readlink $dir/last)" tmux_resurrect_${older}T120000.txt
$store select 1999-01-01_00-00-00
t_eq 'select of a missing snapshot fails' $? 1
t_eq 'and leaves last alone' "$(readlink $dir/last)" tmux_resurrect_${older}T120000.txt
$store select
t_eq 'select without an id succeeds while last exists' $? 0
rm $dir/last
$store select
t_eq 'select without an id or a last fails' $? 1
rm -rf $dir

# A private server: TMUX_TMPDIR is scratch, and run.zsh unset TMUX
if ! tmux new-session -d -s alpha -x 120 -y 30; then
  t_fail 'start a private tmux server'
  t_done
fi
t_eq "the server loads resurrect, its dir in the scratch HOME" "$(tmux show-option -gqv @resurrect-dir)" $dir

local out first id1 id2
settle
out=$($store save)
t_match 'save reports the new snapshot' "$out" 'saved <->-<->-<->_<->-<->-<->'
id1=${out#saved }
first=$(readlink $dir/last)
t_eq 'its id names the file last points at' tmux_resurrect_${${id1//-/}/_/T}.txt $first
t_ok 'the snapshot holds the session' grep -q "^pane"$'\t'"alpha"$'\t' $dir/$first

# Within the same second, so the store's wait for the next one is exercised too
out=$($store save)
t_eq 'an unchanged layout saves nothing new' "$out" "unchanged $id1"
t_eq 'last keeps its snapshot' "$(readlink $dir/last)" $first
local -a snapshots=($dir/tmux_resurrect_*.txt(N))
t_eq 'resurrect dropped the duplicate' $#snapshots 1

fixture 20200101T000000 expired
touch -t 202001010000 $dir/tmux_resurrect_20200101T000000.txt
fixture 20200102T000000 previous
touch -t 202001020000 $dir/tmux_resurrect_20200102T000000.txt
ln -fs tmux_resurrect_20200102T000000.txt $dir/last
tmux new-window -d -t alpha
settle
out=$($store save)
t_match 'a changed layout saves a new snapshot' "$out" 'saved <->-<->-<->_<->-<->-<->'
id2=${out#saved }
t_ok 'a snapshot past 3 days expires at the next save' test ! -e $dir/tmux_resurrect_20200101T000000.txt
t_ok 'unless last pointed at it before that save' test -e $dir/tmux_resurrect_20200102T000000.txt
t_ok 'newer snapshots stay' test -e $dir/$first

t_eq 'tsave -c on an unchanged layout' "$(tsave -c 2>&1)" "Unchanged since snapshot $id2, its expiry restarts"
t_eq 'tsave with no nvim in its panes' "$(tsave 2>&1)" "Unchanged since snapshot $id2, its expiry restarts"
tmux has-session 2>/dev/null
t_eq 'and then kills the server' $? 1

tmux new-session -d
$store pre-restore
t_eq 'pre-restore names a lone unnamed session 0' "$(tmux list-sessions -F '#{session_name}')" 0
tmux rename-session -t 0 work
$store pre-restore
t_eq 'and leaves a named one alone' "$(tmux list-sessions -F '#{session_name}')" work
tmux kill-server

tmux new-session -d -s busy \; split-window -d
t_eq 'trestore refuses a server with panes' "$(trestore 2>&1)" \
  'trestore: this server already has panes, so the restore would barely change it; use a fresh one, or --force'
t_eq 'trestore names a missing snapshot' "$(trestore 1999-01-01_00-00-00 --force 2>&1)" \
  'trestore: no snapshot 1999-01-01_00-00-00 (trestore --list shows them)'
tmux kill-server

# From scratch, as from a pane of the placeholder session (outside tmux, trestore attaches), whose
# $TMUX names that session for the hook that renames it: resurrect then replaces it
tmux new-session -d
local -a sessions
local client=$(tmux list-sessions -F '#{socket_path},#{pid},#{session_id}')
TMUX=${client/\$/} trestore $id1
t_eq 'trestore <id> from inside tmux' $? 0
t_eq 'it points last at that snapshot' "$(readlink $dir/last)" $first
repeat 40; do
  sessions=(${(f)"$(tmux list-sessions -F '#{session_name}' 2>/dev/null)"})
  [[ ${(j:,:)sessions} == alpha ]] && break
  sleep 0.25
done
t_eq 'the snapshot replaces the placeholder session' "${(j:,:)sessions}" alpha
t_eq 'with its windows' "$(tmux list-windows -t alpha -F '#{window_index}' | wc -l | tr -d ' ')" 1

t_done
