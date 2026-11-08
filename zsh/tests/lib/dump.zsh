# Sourced by zdotdir/.zshrc after the config's own .zshrc. Once zsh-defer's queue has drained, the
# next precmd writes what the shell defines to $ZT_DUMP_DIR/dump-$SHLVL.txt, with the scratch paths
# made generic so two boots compare line by line. A precmd hook rather than a deferred task: zsh-defer
# runs its tasks under `emulate -L zsh`, which hides the shell's own options

_zt_dump() {
  (( $#_zsh_defer_tasks )) && return
  local -a on=(${(ok)options[(R)on]})
  precmd_functions=(${precmd_functions:#_zt_dump})
  setopt local_options extended_glob

  local out=$ZT_DUMP_DIR/dump-$SHLVL.txt name REPLY
  {
    print -r -- '## options set'
    print -rl -- $on

    print -r -- '## aliases'
    print -rl -- ${(o)${(f)"$(alias -L; alias -gL; alias -sL)"}}

    # Lengths, not bodies: enough to show a changed function without printing p10k's thousands
    print -r -- '## functions (name, body length)'
    for name in ${(ok)functions:#_zt_*}; do
      _zt_generic ${functions[$name]}
      print -r -- "$name ${#REPLY}"
    done

    print -r -- '## widgets'
    for name in ${(ok)widgets}; do
      print -r -- "$name ${widgets[$name]}"
    done

    print -r -- '## keymaps'
    bindkey -lL
    for name in ${(of)"$(bindkey -l)"}; do
      bindkey -LM $name
    done

    print -r -- '## zstyles'
    print -rl -- ${(o)${(f)"$(zstyle -L)"}}

    print -r -- '## completions'
    for name in ${(ok)_comps}; do
      print -r -- "$name ${_comps[$name]}"
    done

    print -r -- '## hooks'
    for name in chpwd periodic precmd preexec zshaddhistory zshexit; do
      print -r -- "$name: ${(P)${:-${name}_functions}}"
    done

    print -r -- '## exported'
    for name in ${(ok)parameters[(R)*export*]}; do
      case $name in
        (_|ZDOTDIR|ZT_*) ;;
        (*KEY*|*TOKEN*|*SECRET*|*PASSWORD*) print -r -- "$name=<redacted>" ;;
        (ATUIN_SESSION) print -r -- "$name=<random>" ;;
        (*) print -r -- "$name=${(P)name}" ;;
      esac
    done

    print -r -- '## arrays'
    for name in cdpath fpath manpath module_path path; do
      print -r -- "$name: ${(P)name}"
    done

    print -r -- '## modules'
    print -rl -- ${(o)${(f)"$(zmodload)"}}

    print -r -- '## parameters (name, type)'
    for name in ${(ok)parameters}; do
      [[ ${parameters[$name]} == *-local* || $name == _zt_* ]] || print -r -- "$name ${parameters[$name]}"
    done

    print -r -- '## values'
    for name in ${(o)parameters[(I)(POWERLEVEL9K_*|ZSH_*|HIST*|SAVEHIST|KEYTIMEOUT|WORDCHARS|PROMPT_EOL_MARK|zle_highlight|ANTIDOTE_HOME|ZSH)]}; do
      [[ $name == (ZSH_ARGZERO|ZSH_EVAL_CONTEXT|ZSH_SUBSHELL) || ${parameters[$name]} == *-local* ]] ||
        print -r -- "$name=${(P)name}"
    done

    # Without the times, which differ per boot
    print -r -- '## sched'
    print -rl -- ${${(f)"$(sched)"}##*[0-9]:[0-9][0-9]:[0-9][0-9] }
  } >| $out.tmp

  _zt_generic "$(<$out.tmp)"
  print -r -- $REPLY >| $out.tmp && mv -f $out.tmp $out
}

# Sets REPLY to the text with this boot's own paths made generic: its HOME, TMPDIR, tty and the
# tree its HOME links into
_zt_generic() {
  local tmp=${TMPDIR%/}
  REPLY=${1//$HOME/\~}
  REPLY=${REPLY//\/private$tmp/\$TMPDIR}
  REPLY=${REPLY//$tmp/\$TMPDIR}
  [[ -n $TTY ]] && REPLY=${REPLY//$TTY/\$TTY}
  [[ -n $ZT_TREE ]] && REPLY=${REPLY//$ZT_TREE/<tree>}
}

precmd_functions+=(_zt_dump)
