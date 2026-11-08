#!/bin/zsh -f
# Runs the test files in tests/ (every *.zsh here but run.zsh and ab.zsh), each in its own `zsh -f`
# started from `env -i` (lib/env.zsh), with a private scratch dir as its HOME and TMPDIR:
#
#   tests/run.zsh              every test file
#   tests/run.zsh sync snap    the files whose name contains one of the words
#
# Exits 1 when a test fails or a file cannot run. Assertions: lib/helpers.zsh; scratch shells of the
# config and the rules they follow: lib/env.zsh

() {
  setopt local_options extended_glob
  local tests=$1
  shift
  source $tests/lib/env.zsh

  local file name word wanted tmp failed=0 ran=0
  for file in $tests/*.zsh~*/(run|ab).zsh(N); do
    name=${file:t:r}
    if (( $# )); then
      wanted=0
      for word in "$@"; do
        [[ $name == *$word* ]] && wanted=1
      done
      (( wanted )) || continue
    fi

    (( ran++ ))
    print -r -- "--- $name"
    tmp=$(zt_tmpdir) || return 1
    mkdir -p $tmp/home $tmp/tmp
    zt_env $tmp/home $tmp/tmp
    if ! $ZT_TIMEOUT env -i $reply PATH=$ZT_PATH ZT_REAL_HOME=$ZT_REAL_HOME ZT_TMUX=$ZT_TMUX \
      ZT_REPO=${tests:h:h} ZT_PKG=${tests:h} ZT_LIB=$tests/lib ZT_TMP=$tmp zsh -f $file; then
      failed=1
    fi
    zt_cleanup $tmp
  done

  if (( ! ran )); then
    print -u2 -r -- "no test file matches: $*"
    return 1
  fi
  return $failed
} ${0:A:h} "$@"
