--- @class chrome.lualine-nvim.components.coding-agent
local M = {}

--- @return boolean unseen Whether the agent finished with its panel out of sight
function M.cond()
  local done = require('features.ai.claudecode-nvim.done')
  return done.unseen()
end

--- @return string
function M.get()
  return Conf.icons.cmp_kinds.CodingAgent
end

M.color = 'green'

return M
