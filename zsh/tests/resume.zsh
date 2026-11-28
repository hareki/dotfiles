# A program Rex resumes starts through `zsh +m -ilc`, which has to stay in the terminal's foreground
# process group, or the program stops on its first read (p10k's `setopt monitor` once moved it out)

source $ZT_LIB/helpers.zsh
source $ZT_LIB/env.zsh

local root=$ZT_TMP/resume
zt_home $root/home $ZT_REPO || exit 1
# p10k starts gitstatus at source time only from the state an earlier shell dumped
zt_boot $root/home $root/boot $ZT_REPO || t_bail 'a boot to warm the caches'
zt_server $root/home $root/rex || t_bail 'a private Rex server'
# Under a plain sh, as Rex's own login holds the shell
zt_rex $root/rex new resume --shell=none --cwd $root/home -- /bin/sh -c \
  "zsh +m -ilc 'ps -o pgid= -o tpgid= -p \$\$ >$root/groups.txt'; :" >/dev/null ||
  t_bail 'a pane for the shell'
repeat 300; do
  [[ -s $root/groups.txt ]] && break
  sleep 0.1
done
[[ -s $root/groups.txt ]] || t_bail 'the shell ran its command'

local -a groups=(${=$(<$root/groups.txt)})
t_eq "the shell's process group is the terminal's foreground one" $groups[1] $groups[2]

t_done
