# The lines that lean on a plugin's private names (plugins.zsh, evals.zsh) still take effect with
# the plugins installed now, judged by what each exists to stop: a fork, a process, a dump, a hook.
# Worth a run after `yay` updates them. Scratch boots (lib/env.zsh): a cold one, then a warm one in
# the same HOME, with its caches built and zsh-patina's daemon running

source $ZT_LIB/helpers.zsh
source $ZT_LIB/env.zsh

local root=$ZT_TMP/off log=$ZT_TMP/calls.log
zt_home $root/home $ZT_REPO || exit 1

# Logging stand-ins, first on PATH (~/.local/bin/shims): each notes its arguments, then runs the real
# program
local tool dir real
for tool in who atuin zsh-patina; do
  real=
  for dir in $ZT_REAL_HOME/.local/opt/bin /opt/homebrew/bin /usr/bin; do
    [[ -x $dir/$tool ]] && real=$dir/$tool && break
  done
  if [[ -z $real ]]; then
    t_fail "$tool is installed"
    t_done
  fi
  cat >$root/home/.local/bin/shims/$tool <<EOF
#!/bin/sh
echo "$tool \$*" >>$log
exec $real "\$@"
EOF
  chmod +x $root/home/.local/bin/shims/$tool
done

export ZT_PROBE=$ZT_TMP/probe.zsh
cat >$ZT_PROBE <<'EOF'
print -r -- "should_dump: ${functions[_p9k_should_dump]//$'\n'/ }"
print -r -- "cwd_hook_defined: $+functions[omz_termsupport_cwd]"
print -r -- "precmd: $precmd_functions"
print -r -- "tab_widget: $widgets[fzf-tab-complete]"
EOF

if ! zt_boot $root/home $root/cold $ZT_REPO; then
  t_fail 'a cold boot'
  t_done
fi
mv $log $ZT_TMP/cold.log
local dump=$root/home/.cache/p10k-dump-$USER.zsh before
t_ok 'the cold boot wrote a p10k dump' test -f $dump
# A dump replaces the file, so a new inode or mtime means one happened
before=$(/usr/bin/stat -f '%i %Fm' $dump)
if ! zt_boot $root/home $root/warm $ZT_REPO; then
  t_fail 'a warm boot'
  t_done
fi
mv $log $ZT_TMP/warm.log
local cold=$ZT_TMP/cold.log warm=$ZT_TMP/warm.log

t_ok 'the logging stand-ins are on PATH' grep -q '^atuin init zsh' $cold
t_eq "p10k's SSH check runs no who" "$(cat $cold $warm | grep -c '^who')" 0
t_eq "atuin's init forks no atuin uuid" "$(cat $cold $warm | grep -c '^atuin uuid')" 0
t_eq 'nor starts its search index' "$(cat $cold $warm | grep -c 'prepare-search-index')" 0
t_eq 'zsh-patina start runs once, with the daemon down' "$(grep -c '^zsh-patina start' $cold)" 1
t_eq 'and not while the daemon runs' "$(grep -c '^zsh-patina start' $warm)" 0
t_eq 'a warm shell writes no p10k dump' "$(/usr/bin/stat -f '%i %Fm' $dump)" $before

local probe=$(<$root/cold/probe-1.txt)
local -a precmd=(${=${${(M)${(f)probe}:#precmd: *}#precmd: }})
t_match "_p9k_should_dump is this config's" "$probe" '*should_dump: *_p9k__state_dump_fd*'
t_eq "omz's cwd hook is out of precmd" ${precmd[(Ie)omz_termsupport_cwd]} 0
t_match 'under a name omz still defines' "$probe" '*cwd_hook_defined: 1*'
t_match "autosuggestions wrapped fzf-tab's Tab widget" "$probe" '*tab_widget: user:_zsh_autosuggest_bound_*'

# The _p9k_should_dump override suits only an instant prompt that is off
local on=$ZT_TMP/on
zt_home $on/home $ZT_REPO || exit 1
rm $on/home/.p10k.zsh
sed 's/POWERLEVEL9K_INSTANT_PROMPT=off/POWERLEVEL9K_INSTANT_PROMPT=verbose/' \
  $ZT_REPO/p10k/.p10k.zsh >$on/home/.p10k.zsh
t_ok 'a ~/.p10k.zsh with the instant prompt on' grep -q 'POWERLEVEL9K_INSTANT_PROMPT=verbose' $on/home/.p10k.zsh
if ! zt_boot $on/home $on/boot $ZT_REPO; then
  t_fail 'a boot with the instant prompt on'
  t_done
fi
t_match 'then p10k keeps its own _p9k_should_dump' "$(<$on/boot/probe-1.txt)" '*should_dump: *_p9k__prompt_idx*'

t_done
