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
-- gets one fresh session, and past that the render goes without the blobs, so
-- the worst case is a file highlighted from its hunks and never a wrong render.

local M = {}

local READ_TIMEOUT_MS = 5000

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
--- plus the exact byte count git's payload stream runs to for them, and the
--- answer so far: `false` for each blob declined for its size.
local function select_wanted(infos, n, max_bytes)
  local wanted, expected, blobs = {}, 0, {}
  for i = 1, n do
    local rec = infos[i]
    if rec and rec.type == 'blob' then
      if rec.size <= max_bytes then
        wanted[#wanted + 1] = i
        -- git repeats the info line, then the bytes and a newline
        expected = expected + #rec.header + 1 + rec.size + 1
      else
        blobs[i] = false
      end
    end
  end
  return wanted, expected, blobs
end

--- Fill in `blobs` from a "<oid> <type> <size>\n<bytes>\n" stream, keyed by their
--- index in `infos` and read in `wanted` order. Each record must open with the
--- header `info` already reported: anything else means the stream has desynced,
--- and every record after it would be read out of the wrong bytes, so the whole
--- answer is refused (nil).
local function parse_blobs(out, infos, wanted, blobs)
  local pos = 1
  for _, i in ipairs(wanted) do
    local header = infos[i].header
    if out:sub(pos, pos + #header) ~= header .. '\n' then
      return nil
    end
    pos = pos + #header + 1
    blobs[i] = out:sub(pos, pos + infos[i].size - 1)
    pos = pos + infos[i].size + 1
  end
  return blobs
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
      if not held.proc:is_closing() then
        table.remove(sessions, i)
        table.insert(sessions, 1, held)
        return held
      end
      retire(held)
      break
    end
  end

  local s = { cwd = cwd }
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
  })
  if not ok then
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
    return s.proc:is_closing() or ready()
  end, 1)
  if not ok or s.proc:is_closing() then
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
  local wanted, expected, blobs = select_wanted(infos, n, max_bytes)
  reset(s, false)
  if #wanted == 0 then
    return blobs
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
  return parse_blobs(out, infos, wanted, blobs)
end

-- ------------------------------------------------------------------- fetch ---

--- The contents of the blobs in `oids` of at most `max_bytes`, as a list parallel
--- to it:
---   blobs[i] = the bytes
---   blobs[i] = false  a blob too large to be worth reading
---   blobs[i] = nil    no blob by that name: missing, or not a blob at all
function M.fetch(cwd, oids, max_bytes)
  if #oids == 0 then
    return {}
  end
  for _ = 1, 2 do
    local s = ensure(cwd)
    if not s then
      break
    end
    local blobs = fetch_session(s, oids, max_bytes)
    if blobs then
      return blobs
    end
    -- The session is only as trustworthy as its last answer.
    retire(s)
  end
  return {}
end

return M
