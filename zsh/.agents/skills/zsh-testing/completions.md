# Probing a completion

A compdef is proven by a TAB in a scratch boot that lists a candidate only that compdef can produce (e.g. `television` for `build t`). The boot goes through a private tmux pane like `zt_boot`'s, since zpty's 0x0 pty stalls p10k, and the pane's size gives fzf-tab room to draw.

Save this outside the repo (e.g. `/tmp/zt-tab/tab.zsh`):

```zsh
#!/bin/zsh -f
# tab.zsh <words>: boots the config in a scratch HOME, types <words> plus TAB, prints the pane
source $ZT_TREE/zsh/tests/lib/env.zsh
root=$(zt_tmpdir)
trap 'zt_cleanup $root' EXIT
zt_home $root/home $ZT_TREE || exit 1
mkdir -p $root/tmp $root/dump
zt_env $root/home $root/tmp
sock=$root/tmux.sock
env -i $reply $ZT_TMUX -S $sock -f /dev/null new-session -d -x 160 -y 50 -c $root/home \
  env -u TMUX -u TMUX_PANE SHLVL=0 ZDOTDIR=$ZT_LIB/zdotdir ZT_DUMP_DIR=$root/dump ZT_TREE=$ZT_TREE \
  /bin/zsh -l || exit 1
# The dump marks the first prompt after the deferred plugins, fzf-tab among them, have loaded
zt_await $sock $root/dump/dump-1.txt || exit 1
$ZT_TMUX -S $sock send-keys -l -- "$*"
$ZT_TMUX -S $sock send-keys Tab
sleep 1.5
$ZT_TMUX -S $sock capture-pane -p | grep -v '^$'
$ZT_TMUX -S $sock kill-server
```

Run it from `env -i`, with the tmux build on `PATH` (`env.zsh` takes `ZT_TMUX` from it), from the repo root:

```zsh
env -i HOME=$HOME USER=$USER PATH=$HOME/.local/opt/bin:/usr/bin:/bin:/usr/sbin:/sbin ZT_TREE=$PWD \
  /bin/zsh -f /tmp/zt-tab/tab.zsh 'build '
```

The pane shows fzf-tab's `Completions` box with the candidates and their descriptions. The box holds only its first 9 rows (`build ` lists 11 and hides `tmux` and `worktrunk`), so type a prefix that narrows the list to the candidate you assert on. Assert on a candidate, never on the typed words: the pane echoes those as typed.
