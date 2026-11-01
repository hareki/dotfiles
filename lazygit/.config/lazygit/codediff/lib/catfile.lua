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

local buffer = require('string.buffer')

local M = {}

local READ_TIMEOUT_MS = 5000

--- Read an `info` answer ("<oid> <type> <size>\n" or "<name> missing\n" per
--- object in `oids`). Returns the blobs worth streaming into the (long-lived)
--- daemon's memory -- never a gitlink's commit object, never an oversized blob --
--- and the exact byte count git's payload stream runs to for them. Nil unless
--- there is a line per object: the stream is not what we think it is.
local function parse_info(out, oids, max_bytes)
  local wanted, expected = {}, 0
  local i = 0
  for line in out:gmatch('([^\n]*)\n') do
    i = i + 1
    local kind, size = line:match('^%S+ (%S+) (%d+)$')
    if kind == 'blob' then
      size = tonumber(size)
      if size <= max_bytes then
        -- git repeats the info line, then the bytes and a newline
        local header_bytes = #line + 1
        wanted[#wanted + 1] = { oid = oids[i], header_bytes = header_bytes, size = size }
        expected = expected + header_bytes + size + 1
      end
    end
  end
  if i ~= #oids then
    return nil
  end
  return wanted, expected
end

--- The blobs in the "<oid> <type> <size>\n<bytes>\n" stream of `wanted`, which
--- runs to exactly the bytes parse_info worked out.
local function parse_blobs(out, wanted)
  local blobs = {}
  for _, rec in ipairs(wanted) do
    out:skip(rec.header_bytes)
    blobs[rec.oid] = out:get(rec.size)
    out:skip(1)
  end
  return blobs
end

-- ---------------------------------------------------------------- session ---

-- One live `git cat-file` per repo being served, most recently used first. The
-- daemon is shared by every lazygit the user has open, and two of them in
-- different repos would otherwise respawn git on every render -- the ~8ms of
-- startup this session exists to stop paying. Past the cap the least recently
-- used one is retired.
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

  local s = { cwd = cwd, out = buffer.new() }
  local ok, proc = pcall(vim.system, { 'git', 'cat-file', '--batch-command', '--buffer' }, {
    cwd = cwd,
    stdin = true,
    stderr = false,
    stdout = function(_, data)
      if data then
        s.out:put(data)
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

--- Whether `ready()` reported the response complete, rather than the process
--- dying or taking too long. Fast events only: they are all that git's output and
--- exit arrive as, and anything else this let in would be the next client's
--- render, starting in the middle of this one (see submit in daemon.lua).
local function await(s, ready)
  local ok = vim.wait(READ_TIMEOUT_MS, function()
    return s.proc:is_closing() or ready()
  end, 1, true)
  return ok and not s.proc:is_closing()
end

local function fetch_session(s, oids, max_bytes)
  local commands = {}
  for i, oid in ipairs(oids) do
    commands[i] = 'info ' .. oid .. '\n'
  end
  local answered = send(s, commands)
    and await(s, function()
      return select(2, s.out:tostring():gsub('\n', '')) >= #oids
    end)
  if not answered then
    return nil
  end
  local wanted, expected = parse_info(s.out:get(), oids, max_bytes)
  if not wanted then
    return nil
  end

  -- Only now, knowing the sizes, is anything asked for.
  if #wanted == 0 then
    return {}
  end
  commands = {}
  for k, rec in ipairs(wanted) do
    commands[k] = 'contents ' .. rec.oid .. '\n'
  end
  answered = send(s, commands) and await(s, function()
    return #s.out >= expected
  end)
  if not answered or #s.out ~= expected then
    return nil
  end
  local blobs = parse_blobs(s.out, wanted)
  -- Empty by now, but it would keep the capacity for as long as the session lives.
  s.out:free()
  return blobs
end

-- ------------------------------------------------------------------- fetch ---

--- The contents of the blobs in `oids` of at most `max_bytes`, keyed by oid. A
--- name left out is missing, not a blob at all, or too large to be worth reading.
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
