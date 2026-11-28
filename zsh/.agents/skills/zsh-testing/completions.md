# Probing a completion

A compdef is proven by a TAB in a scratch boot that lists a candidate only that compdef can produce (e.g. `television` for `build t`). The boot goes through a pane of a private Rex server like `zt_boot`'s, since zpty's 0x0 pty stalls p10k.

Save this outside the repo (e.g. `/tmp/zt-tab/tab.zsh`):

```zsh
#!/bin/zsh -f
# tab.zsh <words>: boots the config in a scratch HOME, types <words> plus TAB, prints the pane
source $ZT_TREE/zsh/tests/lib/env.zsh
root=$(zt_tmpdir)
trap 'zt_cleanup $root' EXIT
zt_home $root/home $ZT_TREE || exit 1
zt_server $root/home $root/dump || exit 1
zt_rex $root/dump new boot --shell=none --cwd $root/home -- \
  env -u REX_BLOCK SHLVL=0 ZDOTDIR=$ZT_LIB/zdotdir ZT_DUMP_DIR=$root/dump \
  ZT_TREE=$ZT_TREE /bin/zsh -l >/dev/null || exit 1
# The dump marks the first prompt after the deferred plugins, fzf-tab among them, have loaded
zt_await $root/dump dump-1.txt || exit 1
zt_rex $root/dump send -s boot "$*"
zt_rex $root/dump send-key -s boot tab
sleep 1.5
zt_rex $root/dump capture -s boot --trim | grep -v '^$'
```

Run it from `env -i`, with the `rex` CLI on `PATH` (`env.zsh` takes `ZT_REX` from it; a Rex pane has it in `$REX_BIN_DIR`), from the repo root:

```zsh
env -i HOME=$HOME USER=$USER PATH=$REX_BIN_DIR:/usr/bin:/bin:/usr/sbin:/sbin ZT_TREE=$PWD \
  /bin/zsh -f /tmp/zt-tab/tab.zsh 'build '
```

The pane shows fzf-tab's `Completions` box with the candidates and their descriptions. The box holds only the rows the pane leaves it, so type a prefix that narrows the list to the candidate you assert on. Assert on a candidate, never on the typed words: the pane echoes those as typed.
