# Sourced by every test file. Each check prints one line, and t_done prints the tally and exits 1
# when anything failed:
#
#   t_ok <what> <command...>          the command exits 0
#   t_eq <what> <actual> <expected>   the strings are equal
#   t_match <what> <actual> <pattern> the string matches a zsh pattern (extended_glob)
#   t_done                            last line of a test file
#
# run.zsh starts each file with `zsh -f` from `env -i` (lib/env.zsh), its HOME and TMPDIR inside
# ZT_TMP (a private scratch dir, removed afterwards), and these set: ZT_REPO (the repo root under
# test), ZT_PKG (its zsh package), ZT_LIB (this directory)

typeset -gi T_PASSED=0 T_FAILED=0

t_pass() {
  (( T_PASSED++ ))
  print -r -- "ok    $1"
}

t_fail() {
  (( T_FAILED++ ))
  print -r -- "FAIL  $1"
  [[ -n $2 ]] && print -r -- "$2" | sed 's/^/      /'
  return 0
}

t_ok() {
  local what=$1
  shift
  if "$@"; then
    t_pass $what
  else
    t_fail $what "exit $?: ${(j: :)${(q-)@}}"
  fi
}

t_eq() {
  if [[ $2 == $3 ]]; then
    t_pass $1
  else
    t_fail $1 "expected: ${(qqq)3}"$'\n'"actual:   ${(qqq)2}"
  fi
}

t_match() {
  setopt local_options extended_glob
  if [[ $2 == ${~3} ]]; then
    t_pass $1
  else
    t_fail $1 "pattern: $3"$'\n'"actual:  ${(qqq)2}"
  fi
}

t_done() {
  print -r -- "$T_PASSED passed, $T_FAILED failed"
  exit $(( T_FAILED > 0 ))
}
