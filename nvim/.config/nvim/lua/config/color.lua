---@class config.color
local M = {}

local original = require('utils.ui').get_palette()
local extension = {
  blue0 = '#323c56', -- Darkest blue
  blue1 = '#414e70', -- Mid blue
  blue2 = '#495d83', -- Brightest blue

  green0 = '#394841', -- Darker green
  green1 = '#57735b', -- Brighter green

  surface15 = '#4f5164', -- Between palette surface1 and surface2
}

M.sub_cursor_bg = extension.blue1
M.visual_bg = extension.surface15

M.git_conflict_current_label_bg = extension.green1
M.git_conflict_current_bg = extension.green0
M.git_conflict_ancestor_label_bg = original.surface2
M.git_conflict_ancestor_bg = original.surface1
M.git_conflict_incoming_label_bg = extension.blue2
M.git_conflict_incoming_bg = extension.blue0

return M
