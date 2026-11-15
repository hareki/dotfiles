local catfile = require('lib.catfile')
local util = require('lib.util')

local M = {}

-- What a file's hunks may add up to before it renders with tints only: the cost scales with the
-- hunks, not the file, and a whole-file change costs ~0.6s per megabyte.
local MAX_SECTION_LINES = 20000
local MAX_SECTION_BYTES = 1024 * 1024
-- Above this, a side is highlighted from its hunks instead of the full blob: a full-content parse
-- costs ~300ms per side for a half-megabyte file, however little of it the diff shows.
local MAX_HIGHLIGHT_BLOB_BYTES = 256 * 1024

local function read_worktree_file(path)
  local f = io.open(path, 'rb')
  if not f then
    return nil
  end
  local size = f:seek('end')
  f:seek('set')
  -- Too big to parse whole: no content keeps the file in fragment mode, highlighted from its hunks.
  local content = size <= MAX_HIGHLIGHT_BLOB_BYTES and f:read('*a') or nil
  f:close()
  return content
end

-- All zeros: no object in the database for the side (an unstaged or untracked file).
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

--- Whether each side's rows match the content's lines at their numbers, which full-content
--- highlighting relies on: a diff row is styled from the parsed line at the same number.
local function agrees_with_patch(file, old_lines, new_lines)
  for _, hunk in ipairs(file.hunks) do
    if not (side_agrees(hunk.old, old_lines) and side_agrees(hunk.new, new_lines)) then
      return false
    end
  end
  return true
end

--- Set each file's content_mode (full, fragment or plain) and, in full mode, its old_lines and
--- new_lines. `cwd` is the worktree root, which lazygit runs from and the patch's paths name.
function M.acquire(files, cwd)
  local requests = {} -- flat list of hashes for one batched cat-file call
  for _, file in ipairs(files) do
    file.content_mode = 'plain'
    -- Oversized sections render with tints only, classified here so they skip the cat-file fetch,
    -- size check and line split. A binary file has no hunks, so it never qualifies.
    local eligible = #file.hunks > 0
      and file.hunk_lines <= MAX_SECTION_LINES
      and file.hunk_bytes <= MAX_SECTION_BYTES
    if eligible then
      file.content_mode = 'fragment'
      if not is_zero_hash(file.old_hex) then
        requests[#requests + 1] = file.old_hex
      end
      if not is_zero_hash(file.new_hex) then
        requests[#requests + 1] = file.new_hex
      end
    end
  end

  -- Blobs past the highlight cap are sized, never fetched: a parse that large outcosts the render.
  local blobs = catfile.fetch(cwd, requests, MAX_HIGHLIGHT_BLOB_BYTES)

  for _, file in ipairs(files) do
    if file.content_mode == 'fragment' then
      local old_content, new_content = blobs[file.old_hex], blobs[file.new_hex]
      -- An unstaged or untracked diff has no blob for its new side: the file on disk is that side.
      if
        not new_content
        and not file.is_deleted
        and file.new_path
        and (file.is_new or old_content)
      then
        new_content = read_worktree_file(cwd .. '/' .. file.new_path)
      end
      if (file.is_new or old_content) and (file.is_deleted or new_content) then
        local old_lines = old_content and util.split_lines(old_content) or {}
        local new_lines = new_content and util.split_lines(new_content) or {}
        -- Only content that matches the patch can carry full-file highlighting: a worktree edited
        -- since, a reversed diff or an odd hash would style rows from text the file does not hold.
        if agrees_with_patch(file, old_lines, new_lines) then
          file.content_mode = 'full'
          file.old_lines, file.new_lines = old_lines, new_lines
        end
      end
    end
  end
end

return M
