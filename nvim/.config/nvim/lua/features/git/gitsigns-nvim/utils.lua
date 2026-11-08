local popup = require('utils.popup')

--- @class features.git.gitsigns-nvim.utils
local M = {}

--- A callback for an opened gitsigns popup: <Tab> toggles focus with its origin, <Esc> closes it
--- @param popup_type string Gitsigns popup type ('blame' | 'hunk')
function M.build_popup_navigation(popup_type)
  return function()
    local gitsigns_popup = require('gitsigns.popup')
    local popup_win_id = gitsigns_popup.is_open(popup_type)

    if not popup_win_id then
      return
    end

    popup.link(popup_win_id, {
      name = 'Popup',
      focus_popup = function()
        gitsigns_popup.focus_open(popup_type)
      end,
    })
  end
end

return M
