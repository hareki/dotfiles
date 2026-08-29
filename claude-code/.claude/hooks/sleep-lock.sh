#!/bin/bash

# Shared state for prevent-sleep.sh and allow-sleep.sh: where the per-session
# markers live, which caffeinate argv counts as ours, and the stale-session GC
#
# Sourced, never executed, so $PPID still resolves to Claude Code's own process

LOCK_DIR="/tmp/claude_caffeinate"
SESSIONS_DIR="$LOCK_DIR/sessions"

# How long the bounded fallback holds for when the pending count is unreadable
FALLBACK_SECONDS=1800

# Claude Code runs a caffeinate of its own, so ours is matched on exact argv.
# Both forms end in -w <claude pid>: it makes the argv session-unique (no other
# session's release can mistake it for its own) and self-reaping on Claude exit
HELD_ARGS="caffeinate -d -i -w"
FALLBACK_ARGS="caffeinate -d -i -t $FALLBACK_SECONDS -w"

# Classify a recorded pid with a single ps read: "held", "fallback", or
# nothing when the process is gone or was never one of ours
caffeinate_kind() {
    case "$(ps -p "$1" -o args= 2>/dev/null)" in
        "$HELD_ARGS $2") echo held ;;
        "$FALLBACK_ARGS $2") echo fallback ;;
    esac
}

# Marker mutations race between the synchronous hooks and the detached deferred
# jobs, so every check-then-act on a session's marker runs under this mutex;
# mkdir is the atomic primitive because macOS ships no flock(1). Returns nonzero
# when the lock cannot be had: callers skip their mutation, which always errs
# toward holding the assertion, and the next hook event retries. Only a lock
# whose recorded owner is dead (or that never got one and has sat idle) is
# broken; a live-but-slow holder is left alone rather than raced
lock_session() {
    local dir="$LOCK_DIR/lock.$1" tries=0 cycles=0 owner birth
    mkdir -p "$LOCK_DIR" 2>/dev/null
    # A LOCK_DIR that cannot exist (say, shadowed by a file) would make the
    # loop below spin its full budget on every single tool call
    [ -d "$LOCK_DIR" ] || return 1
    until mkdir "$dir" 2>/dev/null; do
        tries=$((tries + 1))
        if [ "$tries" -ge 100 ]; then
            cycles=$((cycles + 1))
            if [ "$cycles" -ge 2 ]; then
                return 1
            fi
            owner=$(cat "$dir/owner" 2>/dev/null)
            if [ -n "$owner" ] && kill -0 "$owner" 2>/dev/null; then
                return 1
            fi
            birth=$(stat -f '%m' "$dir" 2>/dev/null)
            if [ -z "$birth" ] || [ "$(($(date +%s) - birth))" -ge 5 ]; then
                rm -rf "$dir" 2>/dev/null
            fi
            tries=0
        fi
        sleep 0.05
    done
    echo $$ > "$dir/owner" 2>/dev/null
    return 0
}

# Ownership-checked so an ex-holder whose lock was broken cannot cascade the
# break by removing the new holder's lock on its way out
unlock_session() {
    local dir="$LOCK_DIR/lock.$1"
    if [ "$(cat "$dir/owner" 2>/dev/null)" = "$$" ]; then
        rm -rf "$dir" 2>/dev/null
    fi
}

# The staging name embeds $$ so concurrent writers can never clobber each
# other's half-written marker; the mv keeps the install itself atomic
write_marker() {
    echo "$2" > "$SESSIONS_DIR/$1.tmp.$$"
    mv "$SESSIONS_DIR/$1.tmp.$$" "$SESSIONS_DIR/$1"
}

# Spawn argv comes from the same variables the argv match reads, so the two
# can never drift apart
spawn_held() {
    nohup $HELD_ARGS "$1" > /dev/null 2>&1 &
    write_marker "$1" $!
}

spawn_fallback() {
    nohup $FALLBACK_ARGS "$1" > /dev/null 2>&1 &
    write_marker "$1" $!
}

# Generation token for a session's marker. prevent-sleep.sh reuses a live
# caffeinate instead of replacing it, so the recorded pid alone cannot tell a
# re-armed turn from the one a deferred release was spawned for; the mtime can
marker_token() {
    printf '%s|%s' "$(cat "$SESSIONS_DIR/$1" 2>/dev/null)" \
        "$(stat -f '%Fm' "$SESSIONS_DIR/$1" 2>/dev/null)"
}

# Drop markers whose Claude process is gone. Both caffeinate forms carry -w so
# they are reaped for us; the kill is a belt for the window where -w has not
# fired yet. Liveness greps comm and args together: a node-hosted Claude has a
# node comm, but its args still carry the claude path
clean_stale_sessions() {
    local f sid pid
    for f in "$SESSIONS_DIR"/*; do
        [ -f "$f" ] || continue
        sid=$(basename "$f")
        case "$sid" in
            '' | *[!0-9]*) continue ;;
        esac
        case "$(ps -p "$sid" -o comm=,args= 2>/dev/null)" in
            *claude*) ;;
            *)
                pid=$(cat "$f" 2>/dev/null)
                if [ -n "$pid" ] && [ "$(caffeinate_kind "$pid" "$sid")" = "fallback" ]; then
                    kill "$pid" 2>/dev/null
                fi
                rm -f "$f"
                ;;
        esac
    done
    # Staging files orphaned by a writer killed mid-install; the pattern also
    # sweeps the pre-rewrite "<pid>.tmp" spelling
    find "$SESSIONS_DIR" -name '*.tmp*' -mmin +1 -delete 2>/dev/null
}
