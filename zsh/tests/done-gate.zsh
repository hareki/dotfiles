# What holds Claude Code's done hooks (claude-code/.claude/hooks/done-gate.sh): the gate is sourced
# the way a hook sources it, with the background tasks a Stop payload lists, and so is each hook
# that starts with it

source $ZT_LIB/helpers.zsh

# What a hook reaches past the gate, neither of which a test should: afplay is a stand-in first on
# PATH, and $NVIM a server that isn't there
mkdir -p $ZT_TMP/bin
print -r -- '#!/bin/sh' >$ZT_TMP/bin/afplay
chmod +x $ZT_TMP/bin/afplay
path=($ZT_TMP/bin $path)
export NVIM=$ZT_TMP/no-nvim

# sourced <script> [<task>...]: `done` when the script in hooks/ runs to its end, nothing when the
# gate ends it. The trap waits out what a hook leaves in the background
sourced() {
  bash -c 'trap wait EXIT; . "$0"; echo done' $ZT_REPO/claude-code/.claude/hooks/$1 \
    <<<"{\"transcript_path\": \"$transcript\", \"background_tasks\": [${(j:, :)@[2,-1]}]}"
}

# gate [<task>...]: `done` when the gate lets a hook run on, nothing when it ends the hook
gate() {
  sourced done-gate.sh "$@"
}

# shell <command>: the task of a background shell running the command, which the payload clips
# at 1000 characters
shell() {
  jq -nc --arg command $1 '{type: "shell", command: ($command
    | if length > 1000 then .[0:1000] + "… [+\(length - 1000) chars]" else . end)}'
}

# ran <command>: the transcript line of a Bash call that ran the command in the background
ran() {
  jq -nc --arg command $1 \
    '{message: {content: [{type: "tool_use", name: "Bash", input: {$command, run_in_background: true}}]}}'
}

local command hook transcript=$ZT_TMP/transcript.jsonl filler=${(l:1000::x:):-}
local -a servers=(
  'npx --yes http-server public -p 5050 -c-1 > serve.log 2>&1'
  'NX_DAEMON=false npx nx serve app --port 3100'
  'ng serve'
  'npx firebase serve --only hosting --port 5050'
  'PORT=3105 npx nest start > server.log 2>&1'
  'npm start'
  'cd app && pnpm run start:api'
  'PORT=3137 npm run dev > dev.log 2>&1'
  'pnpm dev:lite'
  'bun run dev_lite'
  'yarn start'
  'node dist/main'
  'node dist/main.js'
  'chrome --headless=new --remote-debugging-port=9333 > chrome.log 2>&1'
  'ng serve > serve.log 2>&1 & wait $!'
  'npx tsc --watch & npx nx serve app'
  'pnpm --filter web dev'
  'yarn workspace web start'
  'npm --prefix app run dev'
  'npm  run dev'
  'npm run startReact'
  'npx nx run app:serve'
  'npx vite'
  'pgrep -f "nx serve" || npx nx serve app'
)
local -a lookalikes=(
  'echo "starting server tests" && pytest -x'
  'echo "an honest start" && pytest -x'
  'npx vitest run src/http-server.test.ts'
  'npm run build && node dist/main-migrate.js'
  'npm run devtools:build'
  'pnpm --filter web build'
  'mybun dev'
  'npx vite build'
  'pkill -f "nx serve"; npx nx build app'
)

t_eq 'nothing in flight: the hooks run' "$(gate)" done
t_eq 'a subagent holds them' "$(gate '{"type": "subagent"}')" ''
t_eq 'a workflow holds them' "$(gate '{"type": "workflow"}')" ''
t_eq 'a shell that ends holds them' "$(gate "$(shell 'npx nx test app > test.log 2>&1; echo "exit=$?"')")" ''
for command in $servers; do
  t_eq "a server does not: $command" "$(gate "$(shell $command)")" done
done
t_eq 'a server beside a shell that ends: held' "$(gate "$(shell 'ng serve')" "$(shell 'npx nx build app')")" ''
t_eq 'a server left in the background of a shell that ends: held' \
  "$(gate "$(shell $'npm run start > dev.log 2>&1 &\nuntil grep -q Compiled dev.log; do sleep 2; done')")" ''
for command in $lookalikes; do
  t_eq "a command that only resembles a server: held: $command" "$(gate "$(shell $command)")" ''
done
t_eq 'another script of a package manager: held' "$(gate "$(shell 'pnpm run build && yarn test')")" ''

# Commands of over 1000 characters that differ only past them: one in a subagent's transcript,
# two in the session's, one in neither
mkdir -p ${transcript:r}/subagents
ran "A=$filler npx nx serve app" >${transcript:r}/subagents/agent-a.jsonl
ran "A=$filler npx nx test app > test.log" >$transcript
ran "B=$filler npx nx build app" >>$transcript
t_eq 'a server named past where the payload clips its command does not' \
  "$(gate "$(shell "A=$filler npx nx serve app")")" done
t_eq 'a clipped command that ends and begins like that server: held' \
  "$(gate "$(shell "A=$filler npx nx test app > test.log")")" ''
t_eq 'a clipped command that ends: held' "$(gate "$(shell "B=$filler npx nx build app")")" ''
t_eq 'a clipped command no transcript has: held' "$(gate "$(shell "C=$filler npx nx serve app")")" ''

for hook in nvim-when-done.sh; do
  t_eq "$hook runs on with nothing in flight" "$(sourced $hook)" done
  t_eq "$hook ends at a held gate" "$(sourced $hook '{"type": "subagent"}')" ''
done

t_done
