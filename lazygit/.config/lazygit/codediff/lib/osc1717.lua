-- lazygit's OSC 1717 diff-line protocol, version 1: a record ahead of a row names the file line it
-- shows, so lazygit can stage, edit or copy it. A record lasts to the end of its row.

local diffparse = require('lib.diffparse')
local util = require('lib.util')

local M = {}

--- The record builder for one file's rows, naming the file by git's patch path, last so it may hold
--- a ';'; nil when a control byte in the path (a BEL, an ESC) would end the record early. It takes:
---   kind      c (context), a (added), d (deleted), f (file header) or h (hunk header)
---   new_line  the new file's line: where a deletion sits, a hunk's first; nil for a file header
---   old_line  a deleted line's number in the old file, nil for every other kind
function M.recorder(path)
  if util.has_control(path) then
    return nil
  end
  local tail = ';' .. path .. '\7'
  return function(kind, new_line, old_line)
    return '\27]1717;1;' .. kind .. ';' .. (new_line or '') .. ';' .. (old_line or '') .. tail
  end
end

--- Give each side of a hunk its rows' records, numbered as lazygit numbers git's patch: every row
--- by its new-file line (a deletion by where it sits), a deleted one also by its old-file line.
function M.add_hunk_records(hunk, record)
  local old, new = {}, {}
  local old_base, new_base = hunk.old.start - 1, hunk.new.start - 1
  diffparse.walk_hunk(hunk, function(old_row, new_row)
    local context = record('c', new_base + new_row)
    old[old_row], new[new_row] = context, context
  end, function(change)
    local deleted_at = new_base + change.new_start
    for row = change.old_start, change.old_end - 1 do
      old[row] = record('d', deleted_at, old_base + row)
    end
    for row = change.new_start, change.new_end - 1 do
      new[row] = record('a', new_base + row)
    end
  end)
  hunk.old.records, hunk.new.records = old, new
end

return M
