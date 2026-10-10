local common = require('utils.common')

--- @class features.git.gitsigns.utils
local M = {}

--- Build a setup callback that links a gitsigns popup to the window it was opened from.
--- Returns a function that, when invoked after the popup opens, wires <Tab>/<Esc>
--- to toggle focus between the source window and the popup, or close it.
--- @param popup_type string Gitsigns popup type ('blame' | 'hunk')
function M.build_popup_navigation(popup_type)
  return function()
    local popup = require('gitsigns.popup')
    local popup_win_id = popup.is_open(popup_type)

    if not popup_win_id then
      return
    end

    common.link_popup(popup_win_id, {
      name = 'Popup',
      focus_popup = function()
        popup.focus_open(popup_type)
      end,
      before_focus = function(target)
        if target == 'source' then
          popup.ignore_cursor_moved = true
        end
      end,
    })
  end
end

return M
