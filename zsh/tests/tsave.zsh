# tsave past its snapshot: what it does about the nvims in the panes, against real ones, and about
# the Claude Code sessions, against a stand-in (lib/claude.zsh). A pane nvim here is `nvim --clean`
# plus this tree's core/auto-session/tsave.lua, the entry point tsave calls, in a private server
# that loads this tree's tmux config. The snapshot itself is tests/snapshots.zsh's

source $ZT_LIB/helpers.zsh
source $ZT_LIB/env.zsh
source $ZT_LIB/claude.zsh
zmodload zsh/zselect

zt_home $HOME $ZT_REPO || exit 1
zt_claude
autoload -Uz $ZT_PKG/.config/zsh/functions/tsave
# The panes run sh, and nvim is typed into it: a job that Ctrl-Z can suspend
export SHELL=/bin/sh

# The nvim tsave's own RPC client is
nvim=/opt/homebrew/bin/nvim
[[ -x $nvim ]] || t_bail "$nvim is installed"

# What the config does for tsave, and no more: the entry point on the module path, the address
# published once the UI is up, and a file that only nvim's normal exit leaves
cat >$ZT_TMP/pane.lua <<EOF
package.path = '$ZT_REPO/nvim/.config/nvim/lua/?.lua;' .. package.path
local tsave = require('core.auto-session.tsave')
vim.api.nvim_create_autocmd('UIEnter', { callback = tsave.publish_tmux_server })
vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = function()
    vim.fn.writefile({}, '$ZT_TMP/left')
  end,
})
EOF
# The same nvim, whose exit then waits for the test to let it go
cat >$ZT_TMP/stalling.lua <<EOF
dofile('$ZT_TMP/pane.lua')
vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = function()
    vim.wait(10000, function()
      return vim.uv.fs_stat('$ZT_TMP/let-go') ~= nil
    end, 20)
  end,
})
EOF

# The same nvim, whose buffer changes between tsave's check and its quit
cat >$ZT_TMP/changing.lua <<EOF
dofile('$ZT_TMP/pane.lua')
local tsave = require('core.auto-session.tsave')
local unsaved, calls = tsave.unsaved, 0
tsave.unsaved = function()
  calls = calls + 1
  if calls == 2 then
    vim.bo.modified = true
  end
  return unsaved()
end
EOF

# The same nvim, whose exit takes a while and leaves a line as it starts and one as it ends, the
# ShaDa write being in between
cat >$ZT_TMP/logging.lua <<EOF
dofile('$ZT_TMP/pane.lua')
vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = function()
    vim.fn.writefile({ 'leaving ' .. vim.env.TMUX_PANE }, '$ZT_TMP/exits', 'a')
    vim.wait(300)
  end,
})
vim.api.nvim_create_autocmd('VimLeave', {
  callback = function()
    vim.fn.writefile({ 'left ' .. vim.env.TMUX_PANE }, '$ZT_TMP/exits', 'a')
  end,
})
EOF

# await <pane> <format> <pattern>: until the pane shows it
await() {
  local got
  repeat 80; do
    got=$(tmux display-message -p -t $1 $2 2>/dev/null)
    [[ $got == ${~3} ]] && return 0
    zselect -t 10
  done
  print -ru2 -- "await: $2 of $1 stayed ${(qq)got}"
  return 1
}

# nvim_in <pane> [<init>]: types an nvim into the pane's shell and waits for the address it
# publishes, a new one if the pane had one already
nvim_in() {
  local old=$(tmux display-message -p -t $1 '#{@nvim-server}')
  tmux send-keys -t $1 "$nvim --clean -u $ZT_TMP/${2:-pane.lua}" Enter
  await $1 '#{pane_current_command}' nvim && await $1 "#{!=:#{@nvim-server},$old}" 1
}

# server [<init>]: a private server whose one pane runs such an nvim
server() {
  tmux new-session -d -s alpha -x 120 -y 30 && nvim_in alpha $1
}

# run <tsave args>: tsave's stdout and stderr into out and err, its exit status into rc. Without
# `last` the store never waits out the second its newest snapshot is named for
run() {
  rm -f $HOME/.local/share/tmux/resurrect/last
  tsave "$@" >$ZT_TMP/out 2>$ZT_TMP/err
  rc=$?
}

# refused <what> <blocker pattern>...: the tsave that just ran kept its snapshot and named exactly
# these blockers, a line each, and the server and its panes are as they were
refused() {
  local what=$1 blocker want='tsave: snapshot <->-<->-<->_<->-<->-<-> kept, tmux left running:'
  for blocker in "${@[2,-1]}"; do
    want+=$'\n'"  alpha:<->.<->: $blocker"
  done
  t_eq "$what: exit status" $rc 1
  t_match "$what: the blockers" "$(<$ZT_TMP/err)" $want
  t_ok "$what: the server lives" tmux has-session -t alpha
}

# --- Its options

run --nope
t_eq 'an unknown option' "$rc $(<$ZT_TMP/err)" '1 tsave: unknown option: --nope'
run --help
t_match '--help' "$rc $(<$ZT_TMP/out)" '0 Usage: tsave *'

# --- From a pane nvim's terminal

# tsave can't finish there, as quitting that nvim ends it: the server reruns it. NVIM is all that
# tells tsave where it is
tmux new-session -d -s alpha -x 120 -y 30
NVIM=/nonexistent TMUX_PANE=$(tmux display-message -p -t alpha '#{pane_id}') run
t_eq 'inside a pane nvim: this tsave stops short' $rc 1
t_ok 'and the one the server reran took the snapshot' test -L $HOME/.local/share/tmux/resurrect/last
tmux has-session 2>/dev/null
t_eq 'then killed the server' $? 1

# --- Refusals: nothing is quit while any pane holds what a kill would lose

server || t_bail 'a pane nvim that published its address'
# An unsaved buffer, a second pane whose nvim tsave can't reach, and a second session sharing both
# panes, which tmux lists once per session
tmux send-keys -t alpha ihello Escape
tmux split-window -d -t alpha "$nvim --clean"
tmux new-session -d -s beta -t alpha
await alpha:.2 '#{pane_current_command}' nvim
run --continue
t_match '--continue with unsaved work: only the snapshot' "$rc $(<$ZT_TMP/out)" '0 Saved snapshot *'
run
refused 'unsaved work' '\[No Name\] \(buf <->\)' "nvim isn't reachable \(started before this config, or with --clean\)"
t_eq 'unsaved work: the buffer is still there' "$(tmux display-message -p -t alpha:.1 '#{pane_current_command}')" nvim

# Without a UTF-8 locale tmux prints the tabs between a pane's fields as `_`, unless asked not to
LC_ALL=C run
refused 'no UTF-8 locale' '\[No Name\] \(buf <->\)' "nvim isn't reachable \(started before this config, or with --clean\)"
tmux kill-session -t beta
tmux kill-pane -t alpha:.2

# At a prompt, nvim answers no request until a key ends it. tsave waits 2s for the answer, cut
# short here
tmux send-keys -t alpha ':set nomodified | echo "a\nb"' Enter
timeout() { command timeout 0.2 "${@[2,-1]}" }
run
unfunction timeout
refused 'nvim at a prompt' "nvim didn't answer \(waiting on a prompt\?\)"
tmux send-keys -t alpha Enter

# The address an nvim that has quit left on its pane, under one tsave can't reach
tmux split-window -d -t alpha
nvim_in alpha:.2 || t_bail 'a second pane nvim that published its address'
tmux send-keys -t alpha:.2 :q Enter
await alpha:.2 '#{pane_current_command}' '(ba|)sh'
tmux send-keys -t alpha:.2 "$nvim --clean" Enter
await alpha:.2 '#{pane_current_command}' nvim
run
refused 'an address left by an earlier nvim' "nvim isn't reachable \(started before this config, or with --clean\)"
tmux kill-pane -t alpha:.2

# A Claude Code session in the middle of a turn, beside an nvim that could quit
tmux split-window -d -t alpha
zt_claude_in alpha:.2 || t_bail 'a pane running Claude Code'
session=$REPLY
print busy >$ZT_TMP/claude/status
run
refused 'a busy Claude' 'claude is busy'
t_eq 'a busy Claude: the nvim beside it is still there' "$(tmux display-message -p -t alpha:.1 '#{pane_current_command}')" nvim
t_ok 'a busy Claude: and so is the session' test ! -e $ZT_TMP/claude/ended
# claude-panes.zsh lists the panes itself, for the same tabs
LC_ALL=C run
refused 'a busy Claude, without a UTF-8 locale' 'claude is busy'
# Only idle is one tsave may end
: >$ZT_TMP/claude/status
run
refused 'a Claude in no state it names' 'claude is in an unknown state'
# Suspended in the middle of a turn, it is no longer the pane's job, and the kill would still end it
print busy >$ZT_TMP/claude/status
tmux send-keys -t alpha:.2 C-z
await alpha:.2 '#{pane_current_command}' '(ba|)sh'
run
refused 'a busy Claude that is suspended' 'claude is busy'
# Not left to the pane's end, where a SIGTERM reaches it and leaves an `ended` for the quit below
# to read
kill -KILL $session
tmux kill-pane -t alpha:.2

# One in the pane nvim's terminal, which that nvim's quit would end. The snapshot keeps the pane
# as nvim's: `claude --resume` is for the pane that runs the session itself
zt_claude_in alpha ':terminal claude' || t_bail "a Claude Code session in the pane nvim's terminal"
session=$REPLY
print busy >$ZT_TMP/claude/status
run
refused "a busy Claude in nvim's terminal" "claude is busy in nvim's terminal"
t_ok "a busy Claude in nvim's terminal: the session is still there" kill -0 $session
t_eq "a busy Claude in nvim's terminal: its pane isn't saved as a Claude Code one" \
  "$(grep -c $'\t:claude' $HOME/.local/share/tmux/resurrect/last)" 0
print idle >$ZT_TMP/claude/status
# For that `ended` again
kill -KILL $session

# Suspended, the server's kill would take it along
tmux send-keys -t alpha C-z
await alpha '#{pane_current_command}' '(ba|)sh'
run
refused 'a suspended nvim' 'a suspended or background nvim, or one (ba|)sh runs'

# ...and so it would behind a second nvim that could itself quit
nvim_in alpha
run
refused 'a suspended nvim behind the running one' 'a suspended or background nvim besides the running one'
tmux kill-server

# --- The quit

rm -f $ZT_TMP/left
server || t_bail 'a pane nvim with nothing unsaved'
tmux split-window -d -t alpha
zt_claude_in alpha:.2 || t_bail 'a pane running an idle Claude Code session'
run
t_match 'nothing unsaved: the snapshot is reported' "$rc $(<$ZT_TMP/out)" '0 Saved snapshot *'
t_eq 'nothing unsaved: no complaint' "$(<$ZT_TMP/err)" ''
t_ok 'nvim left through its normal exit' test -e $ZT_TMP/left
t_eq 'the idle Claude was ended with SIGTERM' "$(<$ZT_TMP/claude/ended)" $ZT_CLAUDE_SESSION
tmux has-session 2>/dev/null
t_eq 'and the server is gone' $? 1

# Two pane nvims, each slow enough to exit that the second would start while the first is at it:
# nvims that write their ShaDa file at the same moment fail (E137) and wait at a prompt instead of
# exiting, so each has left before the next is asked to
server logging.lua || t_bail 'a pane nvim that logs its exit'
tmux split-window -d -t alpha
nvim_in alpha:.2 logging.lua || t_bail 'a second pane nvim that logs its exit'
panes=(${(f)"$(tmux list-panes -t alpha -F '#{pane_id}')"})
run
t_eq 'two nvims: exit status' $rc 0
t_lines 'two nvims: each left before the next began to' "$(<$ZT_TMP/exits)" \
  "leaving $panes[1]"$'\n'"left $panes[1]"$'\n'"leaving $panes[2]"$'\n'"left $panes[2]"

# An nvim still exiting when tsave gives up on it. tsave counts its 10s in sleeps, which return at
# once here
server stalling.lua || t_bail 'a pane nvim that is slow to exit'
sleep() { : }
run
unfunction sleep
t_eq 'nvim still exiting: exit status' $rc 1
t_match 'nvim still exiting: named, with the way out' "$(<$ZT_TMP/err)" \
  'tsave: snapshot <->-<->-<->_<->-<->-<-> kept, but still running: nvim in alpha:<->.<->'$'\n''  finish there, then run `tmux kill-server`:*'
t_ok 'nvim still exiting: the server lives' tmux has-session -t alpha
: >$ZT_TMP/let-go
await alpha '#{pane_current_command}' '(ba|)sh'
tmux kill-server

# Work an nvim gains after its check, while tsave quits the others, keeps it running
server changing.lua || t_bail 'a pane nvim whose buffer changes after the check'
run
t_eq 'changed after the check: exit status' $rc 1
t_match 'changed after the check: named as still running' "$(<$ZT_TMP/err)" \
  'tsave: snapshot <->-<->-<->_<->-<->-<-> kept, but still running: nvim in alpha:<->.<->'$'\n''*'
t_eq 'changed after the check: the nvim is still there' "$(tmux display-message -p -t alpha '#{pane_current_command}')" nvim
tmux kill-server

t_done
