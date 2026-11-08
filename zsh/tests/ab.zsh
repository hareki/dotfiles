#!/bin/zsh -f
# Boots a committed revision (HEAD by default) and this working tree side by side, each in a scratch
# HOME as a top-level login shell and as a login shell started from it, dumps what each defines once
# the deferred plugins have loaded (lib/dump.zsh) and prints the diff:
#
#   tests/ab.zsh          HEAD against the working tree
#   tests/ab.zsh <rev>    <rev> against the working tree
#
# ZT_AB_KEEP=<dir> keeps both dumps there. Exits 0 when they match, 1 when they differ, 2 when a boot
# failed. Boot rules: lib/env.zsh

() {
  local tests=$1 rev=${2:-HEAD}
  source $tests/lib/env.zsh
  local repo=${tests:h:h} run
  run=$(zt_tmpdir) || return 2
  {
    mkdir -p $run/old/tree || return 2
    # From the top: run inside a subdirectory, git archive leaves out paths outside it
    git -C $repo archive $rev zsh p10k tmux | tar -x -C $run/old/tree || return 2
    zt_home $run/old/home $run/old/tree && zt_home $run/new/home $repo || return 2
    zt_boot $run/old/home $run/old $run/old/tree && zt_boot $run/new/home $run/new $repo || return 2

    local shape label differ=0
    for shape label in 1 'top-level shell' 2 'shell started from it'; do
      diff -u --label "$rev, $label" --label "working tree, $label" \
        $run/old/dump-$shape.txt $run/new/dump-$shape.txt || differ=1
    done
    if [[ -n $ZT_AB_KEEP ]]; then
      mkdir -p $ZT_AB_KEEP/{old,new} &&
        cp $run/old/dump-*.txt $ZT_AB_KEEP/old/ && cp $run/new/dump-*.txt $ZT_AB_KEEP/new/
    fi
    return $differ
  } always {
    zt_cleanup $run
  }
} ${0:A:h} "$@"
