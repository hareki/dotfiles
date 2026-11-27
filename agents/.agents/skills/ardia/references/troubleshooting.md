# When `ardia browse` doesn't do what you expected

`ardia browse` takes agent-browser's commands, flags and output (text and `--json`), on the user's running Ardia.
These are the places it differs, and what to do when something goes wrong.

- Input that didn't land
- Background tabs
- Refs
- Custom inputs, covered elements, drag
- Refused commands
- Tabs and sessions
- The page's own world, console and errors
- Output cap
- Auth vault
- Exit status

## Input that didn't land

A click, key press, typing or scroll the page never received fails with `input_not_delivered` (`target_replaced` when
the page redrew the element first: find it again); one it only partly
received reports an unknown outcome. Check the page before retrying, and never repeat a submit blindly. Input is
instant; `--humanize` (or `AGENT_BROWSER_HUMANIZE=1`) gives curved mouse paths, human press timing, wheel scrolling
and per-character typing.

## Background tabs

A session starts with no tab and never takes the user's: until `open <url>` (a background tab of its own) or
`tab active` / `tab <id>`, commands that need a page fail with `no_session_tab`. `open` never navigates the user's
tab unless you picked it with `tab <id>`; `tab active` works in it and `open` then moves to a tab of your own. Later
`open`s navigate the session's own tab. A newer Ardia keeps the tab the CLI is attached to
live, so input works without switching the user's view. On one that doesn't, `open` says so, and `click`, `fill`,
`type`, `press`, `hover`, `drag` and `mouse` fail with the fix: `ardia browse tab t2 --show` (or
`open <url> --show`), which switches Ardia's window to the tab. Snapshots, `read`, `get`, `is`, `find … text`,
`eval`, screenshots, `scroll` and `wait` work in the background either way.

## Refs

A ref points only at the element it was issued for. When that element is gone (a navigation, a new document, a
redraw, an Ardia restart), the command fails with `stale_ref`: ``Stale ref @e4: … Run `ardia browse snapshot -i` again and use the new
refs``, or, when the same element came back under a new ref, `… is now @e19 … use that ref`. An element
keeps its number across snapshots of the same page, and a number never moves to another element. Long runs of one role fold into one line in change reports
(`+ 48 options in combobox "Start time" (…; e8…e55)`); the refs in it work.

In a `batch`, a line can carry its own flags (`--no-changes`), and a last line `close` closes your tabs once every
line succeeded. On `stale_ref`, take a new snapshot (or use the ref the error names) and rerun from that line.

## Custom inputs, covered elements, drag

- `covered by <…>`: act on the covering element first (close the dialog or editor), then retry. Click already dismisses cookie banners and scrolls past sticky headers by itself.
- A field that ignores `fill`: `focus @e1`, then `keyboard inserttext "text"` (or `keyboard type` for keystrokes).
- A typeahead or chip input: `select`, not `fill`; it types each value and clicks the match
  (`select @e5 "Priya Raman" alex@example.com`). When it lists two or no suggestions, pick an exact one.
- `find role` with several matches clicks nothing and lists them with refs; use the ref you mean.
- When `select` says no list is linked to the field, click the option: `find role option click --name "…"`.
- Selectors take CSS, `@e3`, `text=Save`, `role=button[name="Save"]` and `li:has-text("Ana")`; `[role=main]` also
  matches `<main>`.
- `drag @src @dst` drops on the target's far half, so the source takes its place; `--before` or `--after` picks the
  side. In a sortable list the answer names the new position (`moved to 5 of 5`). From a `draggable` source it does
  HTML5 drag and drop (the answer says `HTML5 drag and drop`, `the target didn't accept the drop`, or `plain mouse
  drag`). When the answer has no position, check with `read -s <list>`.

## Refused commands

Not available yet on any released Ardia: cookies, `state save` (and `state load` of a file with cookies),
`set device|geo|offline|headers|credentials|media|permission`, `network route`, `upload`, `download` and
`wait --download`, `highlight`, `clipboard`, `trace`, `profiler`, `record` and `stream enable`. A DevTools method
through `cdp` off Ardia's list is refused too, though an older Ardia refuses some a current one allows, so there
updating may help. Ardia keeps them from the ardia command on purpose:
they fail with exit 1 and `code: "policy_refused"`, say it's a deliberate limit and what to do instead. Updating or
retrying won't help: ask the user to attach the file or download it, use `screenshot` instead of `record`, and
`storage local|session` or `eval` instead of cookies and `state`. `set viewport <w> <h>` works on a tab this session
opened and never showed: it goes off-screen, and `--show` or `set viewport reset` reloads it at its own size. A refusal that says
"which Ardia allows for the ardia command, but not …" is about the tab or address, not the command: it gives the
reason (`data.reason`) and, for a tab, what Ardia has there. Pick another tab or `open` a web page. Not here at all: `connect`, `install`, `upgrade`, `doctor`, `dashboard`, `chat`, `mcp`, `profiles`,
`confirm`/`deny`, iOS, cloud providers and launch flags (`--headed`, `--profile`, `--proxy`, …).

## Tabs and sessions

- A session never takes the user's tab on its own: until it opens one (`open`, `tab new`) or picks one (`tab active`,
  `tab <id>`), page commands fail with `no_session_tab`. `tab list` shows the user's tabs too; `tab close` refuses
  theirs, and `close` leaves open a tab another live session uses.
- `tN` ids are the same in every session and never move to another tab. `tab tab-…` takes the ids `ardia windows`
  prints.
- `tab_detached`: Ardia took the tab away mid-command (it closed, crashed or went to sleep). Run the command again;
  a multi-page `read` already retries that page in a new tab.
- `frame_gone`: the frame chosen with `ardia browse frame` is gone. Run `ardia browse frame main` or pick another frame.
- `attaches_unanswered`: Ardia hasn't answered DevTools attaches yet. Retry, or `ardia browse close` the session.
- `setup_lost`: the tab was attached again after Ardia detached it, but the init scripts, `set` overrides or routes the
  error names couldn't be put back, so they are off. Set them again, then rerun the command.
- `--session name` (or `AGENT_BROWSER_SESSION`) gives its own tabs, refs and captures; cookies and logins are the
  user's in every session. Use one session per task.

## The page's own world, console and errors

Snapshots, `read` and locating run in an isolated world or through the browser; the page sees only what a person's
input would cause. `eval`, `wait --fn`, `page.evaluate` in scripts, init scripts and `open --enable react-devtools` run
in the page's own world, where its globals are; `eval --isolated` (and `wait --fn … --isolated`) run in an isolated
world instead, which shares the DOM but leaves nothing the page can see. `console` and `errors` start capturing on first use (or with `open --capture-console`).

## Output cap

Text output stops at about 12,000 characters (20,000 for `script`) with one line, on stderr, saying how to narrow it
(for a snapshot, the `-s` of its biggest region). Narrow rather than reading the saved full output. Narrow with `-s <sel>`, `snapshot -i`, `read --links <pattern>`, or a script that
returns only the fields you need. `--json` and output redirected to a file (`> out.json`) are never cut.

## Auth vault

```sh
ardia browse auth save github --url https://github.com/login --username me --password-stdin < secret.txt
ardia browse auth login github
```

Passwords go to the macOS login Keychain (so `auth` doesn't work on Linux); `--password` is refused. `login` types only on the saved https origins and
stops if the page navigates, the frame changes or focus leaves the field. Never echo secrets yourself.

## Exit status

0 done; 1 the command failed (a stale ref, a refused command, an action whose outcome is unknown); 2 Ardia isn't
reachable or closed the connection (Stop was pressed or control was turned off: the session ends, and an interrupted
action is reported as unknown, never retried); 130 interrupted.
