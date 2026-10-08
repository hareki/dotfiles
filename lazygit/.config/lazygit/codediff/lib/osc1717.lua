-- lazygit's OSC 1717 diff-line protocol, version 1. A record ahead of a
-- rendered row says which line of which file the row shows, which is what lets
-- lazygit stage, edit or copy the line under its cursor in a rendering that no
-- longer reads as a diff. lazygit offers the protocol through $OSC1717, and
-- learns that a renderer speaks it from a version-only handshake ahead of all
-- other output, which client.sh prints (see there). A record stays in effect
-- until the end of its row, so a side-by-side row needs one per side only
-- where its sides show different lines.

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

--- The records for a hunk's rows, by side and fragment row (the rows
--- diffparse.hunk_fragment reconstructs), numbered as lazygit numbers git's
--- patch: a context line by its new-file line on both sides, an added line by
--- its new-file line, and a deleted line by the new-file line it sits at and
--- its own old-file line.
function M.hunk_records(hunk, record)
  local old, new = {}, {}
  local old_line, new_line = hunk.old_start, hunk.new_start
  for _, line in ipairs(hunk.lines) do
    if line.origin == ' ' then
      local context = record('c', new_line)
      old[#old + 1], new[#new + 1] = context, context
      old_line, new_line = old_line + 1, new_line + 1
    elseif line.origin == '-' then
      old[#old + 1] = record('d', new_line, old_line)
      old_line = old_line + 1
    else
      new[#new + 1] = record('a', new_line)
      new_line = new_line + 1
    end
  end
  return { old = old, new = new }
end

return M
