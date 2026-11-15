# The lines that lean on a plugin's private names (plugins.zsh, evals.zsh) still take effect with
# the plugins installed now, judged by what each exists to stop: a fork, a process, a dump, a hook.
# Worth a run after `yay` updates them. Scratch boots (lib/env.zsh): a cold one, then a warm one in
# the same HOME, with its caches built and zsh-patina's daemon running. The cold one also answers for
# what the test libs copy from the config: the keys a boot is given, the options a command runs under

source $ZT_LIB/helpers.zsh
source $ZT_LIB/env.zsh

local root=$ZT_TMP/off log=$ZT_TMP/calls.log cold=$ZT_TMP/cold.log warm=$ZT_TMP/warm.log
zt_home $root/home $ZT_REPO || exit 1

# Logging stand-ins, first on PATH (~/.local/bin/shims): each notes its arguments, then runs the real
# program
local tool real
for tool in who atuin zsh-patina; do
  real=$(PATH=$ZT_REAL_HOME/.local/opt/bin:/opt/homebrew/bin:/usr/bin whence -p $tool) ||
    t_bail "$tool is installed"
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
# By name only: a value never leaves the shell
() {
  local name
  local -a real
  for name in ${(ok)parameters[(R)*export*]}; do
    [[ $name == (*KEY*|*TOKEN*|*SECRET*|*PASSWORD*) && ${(P)name} != dummy ]] && real+=($name)
  done
  print -r -- "real_secrets: ${real:-none}"
}
EOF

zt_boot $root/home $root/cold $ZT_REPO || t_bail 'a cold boot'
mv $log $cold
local dump=$root/home/.cache/p10k-dump-$USER.zsh before
t_ok 'the cold boot wrote a p10k dump' test -f $dump
# A dump replaces the file, so a new inode or mtime means one happened
before=$(/usr/bin/stat -f '%i %Fm' $dump)
zt_boot $root/home $root/warm $ZT_REPO || t_bail 'a warm boot'
mv $log $warm

t_ok 'the logging stand-ins are on PATH' grep -q '^atuin init zsh' $cold
t_eq "p10k's SSH check runs no who" "$(cat $cold $warm | grep -c '^who')" 0
t_eq "atuin's init forks no atuin uuid" "$(cat $cold $warm | grep -c '^atuin uuid')" 0
t_eq 'nor starts its search index' "$(cat $cold $warm | grep -c 'prepare-search-index')" 0
t_eq 'zsh-patina start runs once, with the daemon down' "$(grep -c '^zsh-patina start' $cold)" 1
t_eq 'and not while the daemon runs' "$(grep -c '^zsh-patina start' $warm)" 0
t_eq 'a warm shell writes no p10k dump' "$(/usr/bin/stat -f '%i %Fm' $dump)" $before

local probe=$(<$root/cold/probe-1.txt)
local -a precmd=(${=${${(M)${(f)probe}:#precmd: *}#precmd: }})
# p10k's own reads _p9k__prompt_idx too, to dump at each shell's first prompt
t_match "_p9k_should_dump is this config's" "$probe" '*should_dump: *_p9k__state_dump_fd*~*_p9k__prompt_idx*'
t_eq "omz's cwd hook is out of precmd" ${precmd[(Ie)omz_termsupport_cwd]} 0
t_match 'under a name omz still defines' "$probe" '*cwd_hook_defined: 1*'
t_match "autosuggestions wrapped fzf-tab's Tab widget" "$probe" '*tab_widget: user:_zsh_autosuggest_bound_*'

# zt_env names the keys .zshenv would otherwise read from the keychain: one it misses shows here
t_match 'a scratch boot holds no key but the dummies' "$probe" '*real_secrets: none*'

# The options helpers.zsh sets for a test file are those of this boot, bar the ones only a login
# shell on a terminal has, and rcs, which the `zsh -f` of a test file turns off
local from='## options set' to='## aliases'
local -a dump=("${(@f)$(<$root/cold/dump-1.txt)}")
local -a booted=(${dump[${dump[(ie)$from]}+1,${dump[(ie)$to]}-1]}) mine=(${(ok)options[(R)on]})
local -a only_booted=(${booted:|mine}) only_mine=(${mine:|booted})
t_eq "the command suites' options are a booted shell's" \
  "$only_booted | $only_mine" 'interactive login monitor rcs shinstdin stdin zle | '

# The _p9k_should_dump override suits only an instant prompt that is off
local on=$ZT_TMP/on
zt_home $on/home $ZT_REPO || exit 1
rm $on/home/.p10k.zsh
sed 's/POWERLEVEL9K_INSTANT_PROMPT=off/POWERLEVEL9K_INSTANT_PROMPT=verbose/' \
  $ZT_REPO/p10k/.p10k.zsh >$on/home/.p10k.zsh
t_ok 'a ~/.p10k.zsh with the instant prompt on' grep -q 'POWERLEVEL9K_INSTANT_PROMPT=verbose' $on/home/.p10k.zsh
zt_boot $on/home $on/boot $ZT_REPO || t_bail 'a boot with the instant prompt on'
t_match 'then p10k keeps its own _p9k_should_dump' "$(<$on/boot/probe-1.txt)" '*should_dump: *_p9k__prompt_idx*'

t_done
