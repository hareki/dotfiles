#!/bin/bash

# Keep the Mac awake while a Bash tool background shell is still running
#
# Claude Code ships an inhibitor of its own (caffeinate -i -t 300, respawned
# every 240s, released 30s after the UI stops reading "busy") and it already
# covers active turns and delegated work: local agents, remote agents,
# in-process teammates and workflows all hold it. Background shells are the one
# kind of work left out, and deliberately so: the task registry tracks them as
# "local_bash", a type absent from the predicate behind "busy", so an idle
# session with a shell still working reads as idle and the system sleeps out
# from under it
#
# One assertion per shell, waited on with -w <shell pid>, so it self-reaps the
# moment that shell exits. That is the whole lifecycle: nothing to release, no
# lease to refresh, no state on disk, and no window for two events to race
#
# Display sleep is left alone on purpose (-i, not -d). Only the system has to
# stay up for the work to keep running

# Backstop for a shell that somehow outlives Claude and is never reaped. The
# two flags are first-to-fire, so a shell that exits normally ends its
# assertion long before this
LEASE=86400

# The main agent's own foreground shells are long gone by the time a turn ends,
# so what is still alive under this session is either a background shell or the
# foreground shell of delegated work still in flight, since both events fire
# before that work finishes. Both are worth staying awake for, so both are
# armed the same way. $PPID is Claude Code's own pid, since it spawns the hook
# directly
while read -r shell_pid; do
    # One string builds both the match and the spawn, so the argv looked for
    # and the argv started can never drift apart; the spawn leaves it unquoted
    # precisely so it splits back into that argv
    args="caffeinate -i -t $LEASE -w $shell_pid"

    # Both events fire for the same shell, and idle_prompt fires repeatedly.
    # The argv is unique per shell, so an assertion's own presence is the
    # idempotency check, and no marker file can disagree with the process table
    pgrep -qf -x "$args" && continue

    nohup $args > /dev/null 2>&1 < /dev/null &
done < <(pgrep -fP "$PPID" 'shell-snapshots/snapshot-' 2>/dev/null)

# Having no background shells is the normal case, so pgrep finding no match
# must not surface as a hook failure
exit 0
