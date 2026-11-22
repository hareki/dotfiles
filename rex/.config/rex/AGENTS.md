# AGENTS.md

## Overview

Personal config for Rex, the terminal multiplexer app (`TERM_PROGRAM=rex`). Stow links this directory to `~/.config/rex`, where Rex reads `init.lua`.

`CLAUDE.md` is a symlink to this file and `.claude/skills` to `.agents/skills`: edit the real files, `AGENTS.md` through anchored replacements against a fresh read. Keep every line under 1000 characters, since some views of this file trim longer lines.

The rules for one kind of change live in `docs/`, one file per topic, written for people and agents alike: conventions in `docs/conventions/`, the testing guide beside them. A project skill in `.agents/skills/` points the agent at its doc and holds only the agent's own steps and checks, so a new convention goes in a doc.

Rex's API ships no type definitions: `.luarc.json` declares only the `rex` global, so LuaLS checks none of its fields. Look an API up before using it: the `superlogical` MCP server (`search_docs`, `read_doc`), or `https://www.superlogical.com/rex/docs/llms-full.txt`; `rex actions --json` lists the actions a client or the server offers.

## Code Style

Before writing or reviewing Lua, or naming a file, read `docs/conventions/code-style.md`.

## Tests

Run every live test in a probe session, never the user's (`docs/testing.md`). Leave actions that queue `client.tab.close`, `client.close` or `client.setting.*` untested live: they go to the user's one app client even from `rex do`, and the auto-mode classifier refuses `client.setting.*` probes.
