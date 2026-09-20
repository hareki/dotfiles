-- Asking git for the objects a diff refers to.
--
-- A render needs two answers about the same object list -- how big is it, and
-- (only for the ones worth reading) what is in it -- and git's own startup is
-- ~8ms regardless of what is asked for, so a render that spawns twice can spend
-- more time starting git than rendering. The daemon outlives the request, so a
-- single `git cat-file --batch-command` is kept alive between renders and both
-- answers come back over its pipes.
--
-- Every failure mode -- no session, a dead one, a slow or malformed answer --
-- falls back to the one-shot `git cat-file` pair, so the worst case is the cost
-- this replaces and never a wrong render.

local M = {}

local READ_TIMEOUT_MS = 5000
--- The bound every git call a render makes is held to; lib.blob's own call
--- uses it rather than restating the number.
M.TIMEOUT_MS = READ_TIMEOUT_MS

--- Sizes and types only: "<oid> <type> <size>\n" or "<name> missing\n" per
--- input line, no payloads. Each record keeps its raw line as `header`: a
--- payload response repeats it verbatim ahead of the bytes.
local function parse_info(out, n)
  local infos = {}
  local i = 0
  for line in out:gmatch('([^\n]*)\n') do
    i = i + 1
    local kind, size = line:match('^%S+ (%S+) (%d+)$')
    if kind then
      infos[i] = { type = kind, size = tonumber(size), header = line }
    end
  end
  if i ~= n then
    return nil -- a line per object, or the stream is not what we think it is
  end
  return infos
end

--- The blobs worth streaming into the (long-lived) daemon's memory -- never a
--- gitlink's commit object, never an oversized blob -- as indices into `infos`,
--- plus the exact byte count git's payload stream runs to for them. Shared by
--- both fetch paths: they must agree on what counts as fetchable, or the
--- fallback renders differently from the fast path. The index is enough for
--- either caller to recover the oid it has to ask for.
local function select_wanted(infos, oids, max_bytes)
  local wanted, expected = {}, 0
  for i = 1, #oids do
    local rec = infos[i]
    if rec and rec.type == 'blob' and rec.size <= max_bytes then
      wanted[#wanted + 1] = i
      -- git repeats the info line, then the bytes and a newline
      expected = expected + #rec.header + 1 + rec.size + 1
    end
  end
  return wanted, expected
end

--- Blobs out of a "<oid> <type> <size>\n<bytes>\n" stream, keyed by their index
--- in `infos` and read in `wanted` order. Each record must open with the header
--- `info` already reported: anything else means the stream has desynced, and
--- every record after it would be read out of the wrong bytes, so collection
--- stops there. Returns the blobs plus whether the whole stream framed as
--- promised, leaving the desync policy to the caller.
local function parse_blobs(out, infos, wanted)
  local blobs = {}
  local pos = 1
  for _, i in ipairs(wanted) do
    local header = infos[i].header
    if out:sub(pos, pos + #header) ~= header .. '\n' then
      return blobs, false
    end
    pos = pos + #header + 1
    blobs[i] = out:sub(pos, pos + infos[i].size - 1)
    pos = pos + infos[i].size + 1
  end
  return blobs, true
end

-- ---------------------------------------------------------------- session ---

-- One live `git cat-file` per repo being served, most recently used first. A
-- single slot was enough while a daemon meant one lazygit, but it is shared by
-- every lazygit the user has open (daemon.lua watches several owners), and two
-- of them in different repos would alternate that slot and respawn git on every
-- render -- the ~8ms of startup this session exists to stop paying. Past the
-- cap the least recently used one is retired.
local SESSION_MAX = 2
local sessions = {}
-- vim.wait pumps the event loop, so a second render can arrive mid-request.
-- It gets the one-shot path rather than a second voice on the same pipe.
local busy = false

local function retire(s)
  for i, held in ipairs(sessions) do
    if held == s then
      table.remove(sessions, i)
      break
    end
  end
  pcall(function()
    s.proc:kill(9)
  end)
end

-- Drop the previous phase's bytes before asking for the next. Counting lines is
-- only for the info phase; over a payload phase it would be a scan of every
-- blob the diff touches.
local function reset(s, count_lines)
  s.buf, s.bytes, s.lines, s.counting = {}, 0, 0, count_lines
end

local function ensure(cwd)
  for i, held in ipairs(sessions) do
    if held.cwd == cwd then
      if not held.dead then
        table.remove(sessions, i)
        table.insert(sessions, 1, held)
        return held
      end
      retire(held)
      break
    end
  end

  local s = { cwd = cwd, dead = false }
  reset(s, false)
  local ok, proc = pcall(vim.system, { 'git', 'cat-file', '--batch-command', '--buffer' }, {
    cwd = cwd,
    stdin = true,
    stderr = false,
    text = false,
    stdout = function(_, data)
      if not data then
        return
      end
      s.buf[#s.buf + 1] = data
      s.bytes = s.bytes + #data
      if s.counting then
        s.lines = s.lines + select(2, data:gsub('\n', ''))
      end
    end,
  }, function()
    s.dead = true
  end)
  if not ok or not proc then
    return nil
  end
  s.proc = proc
  table.insert(sessions, 1, s)
  while #sessions > SESSION_MAX do
    retire(sessions[#sessions])
  end
  return s
end

local function send(s, commands)
  commands[#commands + 1] = 'flush\n'
  local ok = pcall(function()
    s.proc:write(table.concat(commands))
  end)
  return ok
end

--- Collected output once `ready()` reports the response complete, or nil if the
--- process died or took too long.
local function await(s, ready)
  local ok = vim.wait(READ_TIMEOUT_MS, function()
    return s.dead or ready()
  end, 1)
  if not ok or s.dead then
    return nil
  end
  return table.concat(s.buf)
end

local function fetch_session(s, oids, max_bytes)
  local n = #oids

  local commands = {}
  for i = 1, n do
    commands[i] = 'info ' .. oids[i] .. '\n'
  end
  reset(s, true)
  if not send(s, commands) then
    return nil
  end
  local out = await(s, function()
    return s.lines >= n
  end)
  if not out then
    return nil
  end
  local infos = parse_info(out, n)
  if not infos then
    return nil
  end

  -- Only now, knowing the sizes, is anything asked for.
  local wanted, expected = select_wanted(infos, oids, max_bytes)
  reset(s, false)
  if #wanted == 0 then
    return infos, {}
  end
  commands = {}
  for k = 1, #wanted do
    commands[k] = 'contents ' .. oids[wanted[k]] .. '\n'
  end
  if not send(s, commands) then
    return nil
  end
  out = await(s, function()
    return s.bytes >= expected
  end)
  reset(s, false)
  if not out or #out ~= expected then
    return nil
  end

  -- A desync retires the session rather than being served partially: the
  -- one-shot fallback below can still answer this render correctly.
  local blobs, framed = parse_blobs(out, infos, wanted)
  if not framed then
    return nil
  end
  return infos, blobs
end

-- --------------------------------------------------------------- fallback ---

local function git_batch(args, oids, cwd)
  local ok, proc = pcall(vim.system, args, {
    cwd = cwd,
    stdin = table.concat(oids, '\n') .. '\n',
    text = false,
  })
  if not ok then
    return nil
  end
  -- Bounded like the session reads: a git hung on a dead network mount or a
  -- stuck fsmonitor must fail this render, not wedge the daemon's event loop
  -- (and with it every queued client) indefinitely. On timeout wait() kills
  -- the process and reports code 124, so the nil path below covers it.
  local res = proc:wait(READ_TIMEOUT_MS)
  if res.code ~= 0 or not res.stdout then
    return nil
  end
  return res.stdout
end

local function fetch_oneshot(cwd, oids, max_bytes)
  local out = git_batch({ 'git', 'cat-file', '--batch-check' }, oids, cwd)
  if not out then
    return {}, {}
  end
  local infos = parse_info(out, #oids)
  if not infos then
    return {}, {}
  end

  local wanted = select_wanted(infos, oids, max_bytes)
  if #wanted == 0 then
    return infos, {}
  end

  -- The one caller that needs oid strings rather than indices: git_batch feeds
  -- them to `cat-file --batch` on stdin.
  local hashes = {}
  for k = 1, #wanted do
    hashes[k] = oids[wanted[k]]
  end
  out = git_batch({ 'git', 'cat-file', '--batch' }, hashes, cwd)
  if not out then
    return infos, {}
  end

  -- Records arrive in input order. There is nothing left to fall back to here,
  -- so a desync keeps whatever framed correctly ahead of it.
  local blobs = parse_blobs(out, infos, wanted)
  return infos, blobs
end

-- ------------------------------------------------------------------- fetch ---

--- Type and size of every object in `oids`, plus the contents of those that are
--- blobs of at most `max_bytes`. Returns two lists parallel to `oids`:
---   infos[i] = { type, size, header }  nil when the object is missing or unreadable
---   blobs[i] = the bytes               nil when it was not one worth fetching
function M.fetch(cwd, oids, max_bytes)
  if #oids == 0 then
    return {}, {}
  end
  if not busy then
    local s = ensure(cwd)
    if s then
      busy = true
      local ok, infos, blobs = pcall(fetch_session, s, oids, max_bytes)
      busy = false
      if ok and infos and blobs then
        return infos, blobs
      end
      -- The session is only as trustworthy as its last answer.
      retire(s)
    end
  end
  return fetch_oneshot(cwd, oids, max_bytes)
end

return M
