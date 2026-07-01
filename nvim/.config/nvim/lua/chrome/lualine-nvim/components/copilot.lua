--- @class chrome.lualine.components.copilot
local M = {}

local noice_spinners = require('noice.util.spinners')

M.symbols = {
  status = {
    icons = {
      enabled = Conf.Icons.kinds.CopilotEnabled,
      sleep = Conf.Icons.kinds.CopilotSleep,
      disabled = Conf.Icons.kinds.CopilotDisabled,
      warning = Conf.Icons.kinds.CopilotWarning,
      unknown = Conf.Icons.kinds.CopilotUnknown,
    },
  },

  spinners = noice_spinners.spinners.circleFull.frames,
}

-- Copilot icons are huge, takes almost 2 cells
M.padding = { left = 0, right = 3 }

return M
