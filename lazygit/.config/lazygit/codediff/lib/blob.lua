local catfile = require('lib.catfile')
local util = require('lib.util')

local M = {}

-- Resolved lazily: only the worktree-side fallback below needs it, and a commit
-- diff (the whole commits panel) never reaches that. Memoized because the
-- daemon outlives the request and a cwd's repo root cannot change -- which
-- holds for an answer git gave (a root, or "not a repository", recorded as
-- `false`), not for a git that failed to start or hung: remembering that would
-- leave the cwd without worktree content for as long as the daemon keeps
-- rendering in it.
--
-- Keyed by cwd rather than held in one slot, because the daemon is shared by
-- every lazygit the user has open (daemon.lua watches several owners): two of
-- them in different repos would alternate a single slot and pay `git rev-parse`
-- on every render. Cleared wholesale at a cap, like the other caches here.
local ROOT_CACHE_MAX = 8
local roots, n_roots = {}, 0

-- vim.system's wait() reports a process it had to kill on timeout as this code.
local TIMED_OUT = 124

local function worktree_root(cwd)
  local hit = roots[cwd]
  if hit ~= nil then
    return hit or nil
  end
  local ok, proc = pcall(
    vim.system,
    { 'git', 'rev-parse', '--show-toplevel' },
    { cwd = cwd, text = true }
  )
  if not ok then
    return nil
  end
  -- The same bound as the object reads: a hung git (dead network mount,
  -- stuck fsmonitor) must fail this render, not wedge the daemon.
  local res = proc:wait(catfile.TIMEOUT_MS)
  if res.code == TIMED_OUT then
    return nil
  end
  local root = res.code == 0 and res.stdout and vim.trim(res.stdout) or nil
  if n_roots >= ROOT_CACHE_MAX then
    roots, n_roots = {}, 0
  end
  roots[cwd] = root or false
  n_roots = n_roots + 1
  return root
end

local function read_worktree_file(root, path, limits)
  local f = io.open(root .. '/' .. path, 'rb')
  if not f then
    return nil
  end
  local size = f:seek('end')
  f:seek('set')
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
  local content = f:read('*a')
  f:close()
  return content
end

-- An all-zero oid: the side has no object in the database (an unstaged or
-- untracked file), so there is nothing to ask for.
local function is_zero_hash(hex)
  return hex == nil or hex:match('^0+$') ~= nil
end

--- Does the acquired content actually hold the lines the patch says it does?
--- Walks each hunk's rows against the side they were taken from, which is the
--- mapping full-content highlighting relies on: a diff row is styled from the
--- parsed line at the same number.
local function agrees_with_patch(file, old_lines, new_lines)
  for _, hunk in ipairs(file.hunks) do
    local old_row, new_row = hunk.old_start, hunk.new_start
    for _, l in ipairs(hunk.lines) do
      if l.origin ~= '+' then
        if file.need_old and old_lines[old_row] ~= l.text then
          return false
        end
        old_row = old_row + 1
      end
      if l.origin ~= '-' then
        if file.need_new and new_lines[new_row] ~= l.text then
          return false
        end
        new_row = new_row + 1
      end
    end
  end
  return true
end

--- Attach full old/new file contents to each file block where possible.
--- Sets file.content_mode = "full" | "fragment" | "plain", file.hunk_lines,
--- and file.old_lines / file.new_lines in full mode.
--- With `fragment_only`, files are classified but no git lookup is performed,
--- so a render stays reproducible outside the repo it was captured from.
--- Returns true when any file consulted the worktree, i.e. the render depends
--- on state the diff text does not capture.
function M.acquire(files, cwd, limits, fragment_only)
  -- Which sides does each file actually need?
  local requests = {} -- flat list of hashes for one batched cat-file call
  local slots = {} -- parallel list of {file, side}
  for _, file in ipairs(files) do
    file.content_mode = 'plain'
    -- Rows this file's hunks show: the section cap below, and the caller's
    -- highlighting budget, both spend it.
    local hunk_lines = 0
    for _, hunk in ipairs(file.hunks) do
      hunk_lines = hunk_lines + #hunk.lines
    end
    file.hunk_lines = hunk_lines
    -- An oversized section renders with tints only. Classifying it here rather
    -- than after the fact keeps it from paying for a batched cat-file fetch, a
    -- size check and a line split whose result nothing then reads.
    local eligible = not (file.is_combined or file.is_binary)
      and #file.hunks > 0
      and hunk_lines <= limits.max_file_section_lines
    if eligible then
      file.content_mode = 'fragment'
      file.need_old = not file.is_new
      file.need_new = not file.is_deleted
      if file.need_old and not is_zero_hash(file.old_hex) then
        requests[#requests + 1] = file.old_hex
        slots[#slots + 1] = { file = file, side = 'old' }
      end
      if file.need_new and not is_zero_hash(file.new_hex) then
        requests[#requests + 1] = file.new_hex
        slots[#slots + 1] = { file = file, side = 'new' }
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
    if rec and rec.type == 'blob' then
      if rec.size > limits.max_blob_bytes then
        slot.file[slot.side .. '_oversized'] = true
      elseif blobs[i] then
        slot.file[slot.side .. '_content'] = blobs[i]
      else
        -- catfile was handed the highlight cap and answers with the blobs it
        -- judged worth reading, so a real object missing from that answer is
        -- one it declined (too large) or could not frame. Reading its verdict
        -- rather than re-deriving it from the size keeps the cap on one side of
        -- the module boundary, and lands an unframed blob on the cautious
        -- branch: the hash is real, so the worktree file below is not it.
        slot.file.hl_skip = true
      end
    end
  end

  local worktree_dep = false
  for _, file in ipairs(files) do
    if file.content_mode == 'fragment' then
      -- Worktree-side fallback: unstaged/untracked diffs have zero or
      -- odb-missing hashes on the new side; the file on disk is that side.
      -- Not taken for a blob skipped by the highlight cap or the blob cap:
      -- its hash is real, and the checked-out file may be another version
      -- entirely.
      local root = file.need_new
          and not file.new_content
          and not file.hl_skip
          and not file.new_oversized
          and file.new_path
          and worktree_root(cwd)
        or nil
      if root then
        worktree_dep = true
        local content, oversized = read_worktree_file(root, file.new_path, limits)
        file.new_content = content
        if oversized then
          file.new_oversized = true
        end
      end
      -- Oversized is per side: that side just has no full content and keeps
      -- highlighting from its hunk fragments, whose cost is bounded by the
      -- input caps rather than the blob size. Only a file whose every needed
      -- side is oversized drops to plain, so a huge blob on one side cannot
      -- disable the engine and highlighting for the other, fully visible side.
      if
        (not file.need_old or file.old_oversized) and (not file.need_new or file.new_oversized)
      then
        file.content_mode = 'plain'
      else
        local have_old = not file.need_old or file.old_content ~= nil
        local have_new = not file.need_new or file.new_content ~= nil
        if have_old and have_new then
          local old_lines = file.old_content and util.split_lines(file.old_content) or {}
          local new_lines = file.new_content and util.split_lines(file.new_content) or {}
          -- Only content that matches the patch can carry full-file
          -- highlighting. A worktree file edited since lazygit produced the
          -- diff, a reversed diff or an odd hash would otherwise style rows
          -- from text the file does not hold. Asking here, where the bytes'
          -- provenance is known, leaves a file that disagrees in fragment mode
          -- -- still highlighted, from its own hunks -- where asking per
          -- rendered row could only drop that row's spans, and so left the
          -- whole file tint-only.
          if agrees_with_patch(file, old_lines, new_lines) then
            file.content_mode = 'full'
            file.old_lines, file.new_lines = old_lines, new_lines
          end
        end
      end
    end
    file.old_content, file.new_content = nil, nil
  end
  return worktree_dep
end

return M
