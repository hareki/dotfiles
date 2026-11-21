#!/bin/zsh -f
# Runs the test files in tests/ (every *.zsh here but run.zsh and ab.zsh) side by side, each in its
# own `zsh -f` started from `env -i` (lib/env.zsh), with a private scratch dir as its HOME and TMPDIR:
#
#   tests/run.zsh              every test file
#   tests/run.zsh sync snap    the files whose name contains one of the words
#
# Prints each file's output once it has finished, in file order. Exits 1 when a test fails or a file
# cannot run. Assertions: lib/helpers.zsh; scratch shells of the config and the rules they follow:
# lib/env.zsh

() {
  setopt local_options extended_glob
  local tests=$1
  shift
  source $tests/lib/env.zsh

  local file name word wanted tmp pid failed=0
  # Name, scratch dir and pid of each file not yet reported
  local -a started
  trap return INT TERM
  {
    for file in $tests/*.zsh~*/(run|ab).zsh(N); do
      name=${file:t:r}
      if (( $# )); then
        wanted=0
        for word in "$@"; do
          [[ $name == *$word* ]] && wanted=1
        done
        (( wanted )) || continue
      fi

      tmp=$(zt_tmpdir) || return 1
      mkdir -p $tmp/home $tmp/tmp
      zt_env $tmp/home $tmp/tmp
      timeout 600 env -i $reply PATH=$ZT_PATH ZT_REAL_HOME=$ZT_REAL_HOME ZT_REX=$ZT_REX \
        ZT_REPO=${tests:h:h} ZT_PKG=${tests:h} ZT_LIB=$tests/lib ZT_TMP=$tmp zsh -f $file &>$tmp/run.log &
      started+=($name $tmp $!)
    done

    if (( ! $#started )); then
      print -u2 -r -- "no test file matches: $*"
      return 1
    fi
    for name tmp pid in $started; do
      print -r -- "--- $name"
      # Not `wait $pid || ...`: in such a list zsh drops the status an interrupt returns with
      wait $pid
      (( $? )) && failed=1
      cat $tmp/run.log
      zt_cleanup $tmp
      shift 3 started
    done
    return $failed
  } always {
    # What an interrupt leaves: a Ctrl-C doesn't reach a file, which runs in its timeout's own
    # process group
    for name tmp pid in $started; do
      kill $pid 2>/dev/null
      zt_cleanup $tmp
    done
  }
} ${0:A:h} "$@"
