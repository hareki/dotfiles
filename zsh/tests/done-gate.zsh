# What holds Claude Code's done hooks (claude-code/.claude/hooks/done-gate.sh): the gate is sourced
# the way a hook sources it, with the background tasks a Stop payload lists

source $ZT_LIB/helpers.zsh

# gate [<task>...]: `done` when the gate lets a hook run on, nothing when it ends the hook
gate() {
  bash -c '. "$0"; echo done' $ZT_REPO/claude-code/.claude/hooks/done-gate.sh \
    <<<"{\"background_tasks\": [${(j:, :)@}]}"
}

# shell <command>: the task of a background shell running the command
shell() {
  jq -nc --arg command $1 '{type: "shell", $command}'
}

local command
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
  'chrome --headless=new --remote-debugging-port=9333 > chrome.log 2>&1'
)

t_eq 'nothing in flight: the hooks run' "$(gate)" done
t_eq 'a subagent holds them' "$(gate '{"type": "subagent"}')" ''
t_eq 'a workflow holds them' "$(gate '{"type": "workflow"}')" ''
t_eq 'a shell that ends holds them' "$(gate "$(shell 'npx nx test app > test.log 2>&1; echo "exit=$?"')")" ''
for command in $servers; do
  t_eq "a server does not: $command" "$(gate "$(shell $command)")" done
done
t_eq 'a server beside a shell that ends: held' "$(gate "$(shell 'ng serve')" "$(shell 'npx nx build app')")" ''
t_eq "a word that ends in a server's name: held" "$(gate "$(shell 'echo "starting server tests" && pytest -x')")" ''
t_eq 'another script of a package manager: held' "$(gate "$(shell 'pnpm run build && yarn test')")" ''

t_done
