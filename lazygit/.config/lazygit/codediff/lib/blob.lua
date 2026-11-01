local catfile = require('lib.catfile')
local util = require('lib.util')

local M = {}

-- What a file's hunks may add up to before the section renders with tints only.
-- These bound what a render has to parse and draw, which is what the hunks hold
-- rather than what the file does: a small change to a huge file is as cheap as
-- any other, while a whole-file change costs ~0.6s per megabyte of it.
local MAX_SECTION_LINES = 20000
local MAX_SECTION_BYTES = 1024 * 1024
-- Above this, a side is highlighted from its hunk fragments instead of the
-- full blob: a full-content treesitter parse is O(file bytes) per side no
-- matter how little of the file the diff shows, and a half-megabyte file
-- costs ~300ms per side before a single span is extracted.
local MAX_HIGHLIGHT_BLOB_BYTES = 256 * 1024

local function read_worktree_file(path)
  local f = io.open(path, 'rb')
  if not f then
    return nil
  end
  local size = f:seek('end')
  f:seek('set')
  -- Past the highlight cap it is worth showing but not worth a full-content
  -- parse: no content means the file stays in fragment mode and is highlighted
  -- from its hunks.
  local content = size <= MAX_HIGHLIGHT_BLOB_BYTES and f:read('*a') or nil
  f:close()
  return content
end

-- An all-zero oid: the side has no object in the database (an unstaged or
-- untracked file), so there is nothing to ask for.
local function is_zero_hash(hex)
  return hex == nil or hex:match('^0+$') ~= nil
end

local function side_agrees(side, lines)
  for row, text in ipairs(side.rows) do
    if lines[side.start + row - 1] ~= text then
      return false
    end
  end
  return true
end

--- Does the acquired content actually hold the lines the patch says it does?
--- Each side's rows against the file they were taken from, which is the mapping
--- full-content highlighting relies on: a diff row is styled from the parsed line
--- at the same number.
local function agrees_with_patch(file, old_lines, new_lines)
  for _, hunk in ipairs(file.hunks) do
    if not (side_agrees(hunk.old, old_lines) and side_agrees(hunk.new, new_lines)) then
      return false
    end
  end
  return true
end

--- Attach full old/new file contents to each file block where possible.
--- Sets file.content_mode = "full" | "fragment" | "plain", and file.old_lines /
--- file.new_lines in full mode.
--- `cwd` is the worktree root: lazygit chdirs there before it runs anything, so
--- a patch's paths name files under it.
--- With `fragment_only`, files are classified but no git lookup is performed,
--- so a render stays reproducible outside the repo it was captured from.
function M.acquire(files, cwd, fragment_only)
  -- Which sides does each file actually need?
  local requests = {} -- flat list of hashes for one batched cat-file call
  local slots = {} -- parallel list of {file, side}
  for _, file in ipairs(files) do
    file.content_mode = 'plain'
    -- An oversized section renders with tints only. Classifying it here rather
    -- than after the fact keeps it from paying for a batched cat-file fetch, a
    -- size check and a line split whose result nothing then reads. A binary
    -- file has no hunks, so it never qualifies.
    local eligible = #file.hunks > 0
      and file.hunk_lines <= MAX_SECTION_LINES
      and file.hunk_bytes <= MAX_SECTION_BYTES
    if eligible then
      file.content_mode = 'fragment'
      if not is_zero_hash(file.old_hex) then
        requests[#requests + 1] = file.old_hex
        slots[#slots + 1] = { file = file, side = 'old' }
      end
      if not is_zero_hash(file.new_hex) then
        requests[#requests + 1] = file.new_hex
        slots[#slots + 1] = { file = file, side = 'new' }
      end
    end
  end

  if fragment_only then
    return
  end

  -- Blobs past the highlight cap are sized but never fetched: full-content
  -- highlighting is the only consumer of the bytes, and a full-file parse on
  -- something that large costs more than the render it decorates. The file
  -- keeps fragment mode and is highlighted from its hunks instead.
  local blobs = catfile.fetch(cwd, requests, MAX_HIGHLIGHT_BLOB_BYTES)
  for i, slot in ipairs(slots) do
    slot.file[slot.side .. '_content'] = blobs[i]
  end

  for _, file in ipairs(files) do
    if file.content_mode == 'fragment' then
      -- Worktree-side fallback: unstaged/untracked diffs have zero or
      -- odb-missing hashes on the new side; the file on disk is that side.
      -- Not taken for a blob skipped by the highlight cap (false): its hash is
      -- real, and the checked-out file may be another version entirely. Nor
      -- when the old side is missing, since full content needs both.
      if
        file.new_content == nil
        and not file.is_deleted
        and file.new_path
        and (file.is_new or file.old_content)
      then
        file.new_content = read_worktree_file(cwd .. '/' .. file.new_path)
      end
      if (file.is_new or file.old_content) and (file.is_deleted or file.new_content) then
        local old_lines = file.old_content and util.split_lines(file.old_content) or {}
        local new_lines = file.new_content and util.split_lines(file.new_content) or {}
        -- Only content that matches the patch can carry full-file
        -- highlighting. A worktree file edited since lazygit produced the
        -- diff, a reversed diff or an odd hash would otherwise style rows
        -- from text the file does not hold, so a file that disagrees stays in
        -- fragment mode, still highlighted from its own hunks.
        if agrees_with_patch(file, old_lines, new_lines) then
          file.content_mode = 'full'
          file.old_lines, file.new_lines = old_lines, new_lines
        end
      end
    end
    file.old_content, file.new_content = nil, nil
  end
end

return M
