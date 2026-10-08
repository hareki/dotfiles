-- lazygit's OSC 1717 diff-line protocol, version 1. A record ahead of a
-- rendered row says which line of which file the row shows, which is what lets
-- lazygit stage, edit or copy the line under its cursor in a rendering that no
-- longer reads as a diff. lazygit offers the protocol through $OSC1717, and
-- learns that a renderer speaks it from a version-only handshake ahead of all
-- other output, which client.sh prints (see there). A record stays in effect
-- until the end of its row, so a side-by-side row carries one per side.

local util = require('lib.util')

local M = {}

--- The record for the row that follows it. `kind` is one of c (context),
--- a (added), d (deleted), f (file header) or h (hunk header). `new_line` is
--- the line's number in the new file: for a deletion the line it sits at, for
--- a hunk header the first line of the hunk, nil for a file header. `old_line`
--- is a deleted line's number in the old file, nil for every other kind. The
--- path goes last so that it may hold a ';'.
function M.record(kind, new_line, old_line, path)
  return table.concat({
    '\27]1717;1;',
    kind,
    ';',
    new_line or '',
    ';',
    old_line or '',
    ';',
    path,
    '\7',
  })
end

--- `path` as a record can carry it, or nil: a control byte (a BEL or ESC above
--- all) would end the record early and spill the rest of it onto the screen.
function M.usable_path(path)
  if util.has_control(path) then
    return nil
  end
  return path
end

return M
