# Sourced by every test file. Each check prints one line, and t_done prints the tally and exits 1
# when anything failed:
#
#   t_ok <what> <command...>          the command exits 0
#   t_eq <what> <actual> <expected>   the strings are equal
#   t_match <what> <actual> <pattern> the string matches a zsh pattern (extended_glob)
#   t_lines <what> <actual> <expected> the texts are equal, shown as a diff of their lines if not
#   t_done                            last line of a test file
#
# And for the command a test file drives:
#
#   t_run <out> <err> <command...>    runs it the way an interactive shell does, its stdout and
#                                     stderr into the two files, and returns its exit status
#   t_plain <file>                    prints the file without SGR escapes
#
# run.zsh starts each file with `zsh -f` from `env -i` (lib/env.zsh), its HOME and TMPDIR inside
# ZT_TMP (a private scratch dir, removed afterwards), and these set: ZT_REPO (the repo root under
# test), ZT_PKG (its zsh package), ZT_LIB (this directory)

typeset -gi T_PASSED=0 T_FAILED=0

# A command of this config runs inside an interactive shell, so t_run runs it under that shell's
# options: those `setopt` lists in one, bar the interactive-only ones (the "options set" in a
# tests/ab.zsh dump, which tests/overrides.zsh compares this list with)
typeset -ga T_INTERACTIVE_OPTIONS=(
  multios long_list_jobs interactive_comments prompt_subst auto_cd combining_chars
  extended_history hist_expire_dups_first hist_ignore_dups hist_ignore_space hist_verify
  share_history complete_in_word always_to_end auto_menu hash_dirs no_flow_control no_global_rcs
)

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

t_lines() {
  t_ok $1 diff -u --label expected --label actual <(print -r -- "$3") <(print -r -- "$2")
}

t_run() {
  setopt local_options $T_INTERACTIVE_OPTIONS
  "${@[3,-1]}" >$1 2>$2
}

t_plain() {
  setopt local_options extended_glob
  local text=$(<$1)
  print -r -- "${text//$'\e'\[[0-9;]#m}"
}

t_done() {
  print -r -- "$T_PASSED passed, $T_FAILED failed"
  exit $(( T_FAILED > 0 ))
}
