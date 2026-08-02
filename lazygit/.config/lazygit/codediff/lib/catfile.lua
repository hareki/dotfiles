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

--- Sizes and types only: "<oid> <type> <size>\n" or "<name> missing\n" per
--- input line, no payloads.
local function parse_info(out, n)
  local infos, headers = {}, {}
  local i = 0
  for line in out:gmatch("([^\n]*)\n") do
    i = i + 1
    local kind, size = line:match("^%S+ (%S+) (%d+)$")
    if kind then
      infos[i] = { type = kind, size = tonumber(size) }
      headers[i] = line
    end
  end
  if i ~= n then
    return nil -- a line per object, or the stream is not what we think it is
  end
  return infos, headers
end

-- ---------------------------------------------------------------- session ---

local session = nil
-- vim.wait pumps the event loop, so a second render can arrive mid-request.
-- It gets the one-shot path rather than a second voice on the same pipe.
local busy = false

local function retire()
  local s = session
  session = nil
  if s then
    pcall(function()
      s.proc:kill(9)
    end)
  end
end

-- Drop the previous phase's bytes before asking for the next. Counting lines is
-- only for the info phase; over a payload phase it would be a scan of every
-- blob the diff touches.
local function reset(s, count_lines)
  s.buf, s.bytes, s.lines, s.counting = {}, 0, 0, count_lines
end

local function ensure(cwd)
  if session and session.cwd == cwd and not session.dead then
    return session
  end
  retire()

  local s = { cwd = cwd, dead = false }
  reset(s, false)
  local ok, proc = pcall(vim.system, { "git", "cat-file", "--batch-command", "--buffer" }, {
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
        local pos = 1
        while true do
          local nl = data:find("\n", pos, true)
          if not nl then
            break
          end
          s.lines = s.lines + 1
          pos = nl + 1
        end
      end
    end,
  }, function()
    s.dead = true
  end)
  if not ok or not proc then
    return nil
  end
  s.proc = proc
  session = s
  return s
end

local function send(s, commands)
  commands[#commands + 1] = "flush\n"
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

local function fetch_session(cwd, oids, max_bytes)
  local s = ensure(cwd)
  if not s then
    return nil
  end
  local n = #oids

  local commands = {}
  for i = 1, n do
    commands[i] = "info " .. oids[i] .. "\n"
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
  local infos, headers = parse_info(out, n)
  if not infos then
    return nil
  end

  -- Only now, knowing the sizes, is anything streamed into the (long-lived)
  -- daemon's memory: never a gitlink's commit object, never an oversized blob.
  local wanted, expected = {}, 0
  commands = {}
  for i = 1, n do
    local rec = infos[i]
    if rec and rec.type == "blob" and rec.size <= max_bytes then
      wanted[#wanted + 1] = i
      commands[#commands + 1] = "contents " .. oids[i] .. "\n"
      -- git repeats the info line, then the bytes and a newline
      expected = expected + #headers[i] + 1 + rec.size + 1
    end
  end
  if #wanted == 0 then
    reset(s, false)
    return infos, {}
  end
  reset(s, false)
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

  local blobs = {}
  local pos = 1
  for _, i in ipairs(wanted) do
    -- Each record must open with the header `info` already reported. Anything
    -- else means the stream has desynced, and every record after it would be
    -- read out of the wrong bytes.
    local header = headers[i]
    if out:sub(pos, pos + #header) ~= header .. "\n" then
      return nil
    end
    pos = pos + #header + 1
    blobs[i] = out:sub(pos, pos + infos[i].size - 1)
    pos = pos + infos[i].size + 1
  end
  return infos, blobs
end

-- --------------------------------------------------------------- fallback ---

local function git_batch(args, oids, cwd)
  local ok, proc = pcall(vim.system, args, {
    cwd = cwd,
    stdin = table.concat(oids, "\n") .. "\n",
    text = false,
  })
  if not ok then
    return nil
  end
  local res = proc:wait()
  if res.code ~= 0 or not res.stdout then
    return nil
  end
  return res.stdout
end

local function fetch_oneshot(cwd, oids, max_bytes)
  local out = git_batch({ "git", "cat-file", "--batch-check" }, oids, cwd)
  if not out then
    return {}, {}
  end
  local infos, headers = parse_info(out, #oids)
  if not infos then
    return {}, {}
  end

  local wanted = {}
  local hashes = {}
  for i = 1, #oids do
    local rec = infos[i]
    if rec and rec.type == "blob" and rec.size <= max_bytes then
      wanted[#wanted + 1] = i
      hashes[#hashes + 1] = oids[i]
    end
  end
  if #hashes == 0 then
    return infos, {}
  end

  out = git_batch({ "git", "cat-file", "--batch" }, hashes, cwd)
  if not out then
    return infos, {}
  end

  -- Records arrive in input order: "<oid> <type> <size>\n<bytes>\n".
  local blobs = {}
  local pos = 1
  for _, i in ipairs(wanted) do
    local header = headers[i]
    if out:sub(pos, pos + #header) ~= header .. "\n" then
      break
    end
    pos = pos + #header + 1
    blobs[i] = out:sub(pos, pos + infos[i].size - 1)
    pos = pos + infos[i].size + 1
  end
  return infos, blobs
end

-- ------------------------------------------------------------------- fetch ---

--- Type and size of every object in `oids`, plus the contents of those that are
--- blobs of at most `max_bytes`. Returns two lists parallel to `oids`:
---   infos[i] = { type, size }  nil when the object is missing or unreadable
---   blobs[i] = the bytes       nil when it was not one worth fetching
function M.fetch(cwd, oids, max_bytes)
  if #oids == 0 then
    return {}, {}
  end
  if not busy then
    busy = true
    local ok, infos, blobs = pcall(fetch_session, cwd, oids, max_bytes)
    busy = false
    if ok and infos then
      return infos, blobs
    end
    -- The session is only as trustworthy as its last answer.
    retire()
  end
  return fetch_oneshot(cwd, oids, max_bytes)
end

return M
