-- lazygit's OSC 1717 diff-line protocol, version 1. A record ahead of a
-- rendered row says which line of which file the row shows, which is what lets
-- lazygit stage, edit or copy the line under its cursor in a rendering that no
-- longer reads as a diff. lazygit offers the protocol through $OSC1717, and
-- learns that a renderer speaks it from a version-only handshake ahead of all
-- other output, which client.sh prints (see there). A record stays in effect
-- until the end of its row, so a side-by-side row needs one per side only
-- where its sides show different lines.

local diffparse = require('lib.diffparse')
local util = require('lib.util')

local M = {}

--- The record builder for the rows of one file, whose records name it by
--- `path`, the path git's patch has for it (which is how lazygit finds the line
--- again); nil when a record can't carry the path: a control byte (a BEL or ESC
--- above all) would end the record early and spill the rest of it onto the
--- screen.
---
--- The builder takes `kind`, one of c (context), a (added), d (deleted),
--- f (file header) or h (hunk header); `new_line`, the line's number in the new
--- file: for a deletion the line it sits at, for a hunk header the first line
--- of the hunk, nil for a file header; and `old_line`, a deleted line's number
--- in the old file, nil for every other kind. The path goes last so that it may
--- hold a ';'.
function M.recorder(path)
  if util.has_control(path) then
    return nil
  end
  local tail = ';' .. path .. '\7'
  return function(kind, new_line, old_line)
    return '\27]1717;1;' .. kind .. ';' .. (new_line or '') .. ';' .. (old_line or '') .. tail
  end
end

--- Give each side of a hunk the records of its rows, numbered as lazygit numbers
--- git's patch: a context line by its new-file line on both sides, an added line
--- by its new-file line, and a deleted line by the new-file line it sits at and
--- its own old-file line.
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
