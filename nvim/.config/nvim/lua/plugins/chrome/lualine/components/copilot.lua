---@class plugins.chrome.lualine.components.copilot
local M = {}

local noice_spinners = require('noice.util.spinners')

M.symbols = {
  status = {
    icons = {
      enabled = Icons.kinds.CopilotEnabled,
      sleep = Icons.kinds.CopilotSleep,
      disabled = Icons.kinds.CopilotDisabled,
      warning = Icons.kinds.CopilotWarning,
      unknown = Icons.kinds.CopilotUnknown,
    },
  },

  spinners = noice_spinners.spinners.circleFull.frames,
}

-- Copilot icons are huge, takes almost 2 cells
M.padding = { left = 0, right = 3 }

return M
