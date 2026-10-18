--- @class chrome.lualine.components.live-preview
local M = {}

--- @return string port e.g. "5500", empty (hiding the component) while no server runs
function M.get()
  local live_preview_utils = require('features.preview.live-preview-nvim.utils')
  return tostring(live_preview_utils.running_port() or '')
end

M.icon = Conf.icons.tools.LIVE_PREVIEW

return M
