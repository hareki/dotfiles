local util = require("lib.util")

local M = {}

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

--- Sizes and types only: "<oid> <type> <size>\n" or "<name> missing\n" per
--- input line, no payloads. Returns a parallel list of { type, size }.
local function batch_check(oids, cwd)
  if #oids == 0 then
    return {}
  end
  local out = git_batch({ "git", "cat-file", "--batch-check" }, oids, cwd)
  if not out then
    return {}
  end
  local info = {}
  local i = 0
  for line in out:gmatch("([^\n]*)\n") do
    i = i + 1
    local kind, size = line:match("^%S+ (%S+) (%d+)$")
    if kind then
      info[i] = { type = kind, size = tonumber(size) }
    end
  end
  return info
end

--- Fetch blob contents in input order. Oversized and non-blob objects must be
--- filtered out by the caller: git streams whatever is asked for straight into
--- memory, and a non-blob payload left in the stream would desync every
--- record after it.
local function batch_cat_file(hashes, cwd)
  if #hashes == 0 then
    return {}
  end
  local out = git_batch({ "git", "cat-file", "--batch" }, hashes, cwd)
  if not out then
    return {}
  end

  -- Records arrive in input order: "<oid> <type> <size>\n<bytes>\n" or "<name> missing\n".
  local results = {}
  local pos = 1
  for i = 1, #hashes do
    local nl = out:find("\n", pos, true)
    if not nl then
      break
    end
    local header = out:sub(pos, nl - 1)
    pos = nl + 1
    local kind, size = header:match("^%S+ (%S+) (%d+)$")
    if size then
      size = tonumber(size)
      if kind == "blob" then
        results[i] = { content = out:sub(pos, pos + size - 1), size = size }
      end
      -- Skip the payload either way; "missing" records have none.
      pos = pos + size + 1
    end
  end
  return results
end

local function read_worktree_file(root, path, max_bytes)
  local f = io.open(root .. "/" .. path, "rb")
  if not f then
    return nil
  end
  local size = f:seek("end")
  f:seek("set")
  if size > max_bytes then
    f:close()
    return nil, true -- oversized
  end
  local content = f:read("*a")
  f:close()
  return content
end

local function to_lines(content)
  local lines = util.split_lines(content)
  for j = 1, #lines do
    lines[j] = util.strip_cr(lines[j])
  end
  return lines
end

--- Reconstruct one side of a hunk from the diff itself (used when blobs are
--- unavailable). Returns the lines and the row offset the hunk starts at.
function M.hunk_fragment(hunk, side)
  local lines = {}
  local want_minus = side == "old"
  for _, l in ipairs(hunk.lines) do
    if l.origin == " " or (want_minus and l.origin == "-") or (not want_minus and l.origin == "+") then
      lines[#lines + 1] = util.strip_cr(l.text)
    end
  end
  return lines
end

--- Attach full old/new file contents to each file block where possible.
--- Sets file.content_mode = "full" | "fragment" | "plain", and
--- file.old_lines / file.new_lines in full mode.
function M.acquire(files, cwd, limits)
  local root
  do
    local ok, proc = pcall(vim.system, { "git", "rev-parse", "--show-toplevel" }, { cwd = cwd, text = true })
    if ok then
      local res = proc:wait()
      if res.code == 0 and res.stdout then
        root = vim.trim(res.stdout)
      end
    end
  end

  -- Which sides does each file actually need?
  local requests = {} -- flat list of hashes for one batched cat-file call
  local slots = {} -- parallel list of {file, side}
  for _, file in ipairs(files) do
    file.content_mode = "plain"
    local eligible = not (file.is_combined or file.is_binary) and #file.hunks > 0
    if eligible then
      file.content_mode = "fragment"
      file.need_old = not file.is_new
      file.need_new = not file.is_deleted
      if file.need_old and not util.is_zero_hash(file.old_hex) then
        requests[#requests + 1] = file.old_hex
        slots[#slots + 1] = { file = file, side = "old" }
      end
      if file.need_new and not util.is_zero_hash(file.new_hex) then
        requests[#requests + 1] = file.new_hex
        slots[#slots + 1] = { file = file, side = "new" }
      end
    end
  end

  -- Size/type pass first, so an oversized blob or a gitlink's commit object is
  -- never streamed into the (long-lived) daemon's memory at all.
  local info = batch_check(requests, cwd)
  local wanted, wanted_slots = {}, {}
  for i, slot in ipairs(slots) do
    local rec = info[i]
    if rec and rec.type == "blob" then
      if rec.size > limits.max_blob_bytes then
        slot.file.oversized = true
      else
        wanted[#wanted + 1] = requests[i]
        wanted_slots[#wanted_slots + 1] = slot
      end
    end
  end

  local fetched = batch_cat_file(wanted, cwd)
  for i, slot in ipairs(wanted_slots) do
    local rec = fetched[i]
    if rec then
      slot.file[slot.side .. "_content"] = rec.content
    end
  end

  for _, file in ipairs(files) do
    if file.content_mode == "fragment" then
      if file.oversized then
        file.content_mode = "plain"
      else
        -- Worktree-side fallback: unstaged/untracked diffs have zero or
        -- odb-missing hashes on the new side; the file on disk is that side.
        if file.need_new and not file.new_content and root and file.new_path then
          local content, oversized = read_worktree_file(root, file.new_path, limits.max_blob_bytes)
          if oversized then
            file.content_mode = "plain"
          else
            file.new_content = content
          end
        end
        local have_old = not file.need_old or file.old_content ~= nil
        local have_new = not file.need_new or file.new_content ~= nil
        if file.content_mode ~= "plain" and have_old and have_new then
          file.content_mode = "full"
          file.old_lines = file.old_content and to_lines(file.old_content) or {}
          file.new_lines = file.new_content and to_lines(file.new_content) or {}
        end
      end
    end
    file.old_content, file.new_content = nil, nil
  end
end

return M
