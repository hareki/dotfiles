--- @class chrome.lualine.components.macro
local M = {}

--- @return string register Empty (hiding the component) while not recording
function M.get()
  return vim.fn.reg_recording()
end

M.icon = Conf.icons.misc.MACRO
M.color = 'red'

return M
