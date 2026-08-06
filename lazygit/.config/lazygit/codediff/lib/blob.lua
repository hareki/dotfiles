local catfile = require("lib.catfile")
local util = require("lib.util")

local M = {}

-- Resolved lazily: only the worktree-side fallback below needs it, and a commit
-- diff (the whole commits panel) never reaches that. Memoized because the
-- daemon outlives the request and a cwd's repo root cannot change.
local root_cache = { cwd = nil, root = nil }

local function worktree_root(cwd)
  if root_cache.cwd ~= cwd then
    local root
    local ok, proc = pcall(vim.system, { "git", "rev-parse", "--show-toplevel" }, { cwd = cwd, text = true })
    if ok then
      local res = proc:wait()
      if res.code == 0 and res.stdout then
        root = vim.trim(res.stdout)
      end
    end
    root_cache = { cwd = cwd, root = root }
  end
  return root_cache.root
end

local function read_worktree_file(root, path, limits)
  local f = io.open(root .. "/" .. path, "rb")
  if not f then
    return nil
  end
  local size = f:seek("end")
  f:seek("set")
  if size > limits.max_blob_bytes then
    f:close()
    return nil, true -- oversized
  end
  if size > limits.max_highlight_blob_bytes then
    -- Worth showing but not worth a full-content parse: no content means the
    -- file stays in fragment mode and is highlighted from its hunks.
    f:close()
    return nil
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
      lines[#lines + 1] = l.text
    end
  end
  return lines
end

--- Attach full old/new file contents to each file block where possible.
--- Sets file.content_mode = "full" | "fragment" | "plain", and
--- file.old_lines / file.new_lines in full mode.
--- With `fragment_only`, files are classified but no git lookup is performed,
--- so a render stays reproducible outside the repo it was captured from.
--- Returns true when any file consulted the worktree, i.e. the render depends
--- on state the diff text does not capture.
function M.acquire(files, cwd, limits, fragment_only)
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

  if fragment_only then
    return false
  end

  -- Blobs past the highlight cap are sized but never fetched: full-content
  -- highlighting is the only consumer of the bytes, and a full-file parse on
  -- something that large costs more than the render it decorates. The file
  -- keeps fragment mode and is highlighted from its hunks instead.
  local infos, blobs = catfile.fetch(cwd, requests, limits.max_highlight_blob_bytes)
  for i, slot in ipairs(slots) do
    local rec = infos[i]
    if rec and rec.type == "blob" and rec.size > limits.max_blob_bytes then
      slot.file.oversized = true
    elseif rec and rec.type == "blob" and rec.size > limits.max_highlight_blob_bytes then
      slot.file.hl_skip = true
    elseif blobs[i] then
      slot.file[slot.side .. "_content"] = blobs[i]
    end
  end

  local worktree_dep = false
  for _, file in ipairs(files) do
    if file.content_mode == "fragment" then
      if file.oversized then
        file.content_mode = "plain"
      else
        -- Worktree-side fallback: unstaged/untracked diffs have zero or
        -- odb-missing hashes on the new side; the file on disk is that side.
        -- Not taken for a blob skipped by the highlight cap: its hash is real,
        -- and the checked-out file may be another version entirely.
        local root = file.need_new and not file.new_content and not file.hl_skip and file.new_path and worktree_root(cwd) or nil
        if root then
          worktree_dep = true
          local content, oversized = read_worktree_file(root, file.new_path, limits)
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
  return worktree_dep
end

return M
