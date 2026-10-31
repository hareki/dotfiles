--- @class core.nvim-treesitter.utils
local M = {}

local detach_patched = false

--- A highlighter's destroy() sources syntax/<ft>.vim (~12 ms for markdown) even from on_detach,
--- where the buffer is going away (a reload takes on_reload), so wiped popups paid for nothing
--- @return nil
function M.skip_syntax_on_detach()
  if detach_patched then
    return
  end
  detach_patched = true

  local common = require('utils.common')
  local highlighter = require('vim.treesitter.highlighter') --[[@as table]]
  local on_detach = highlighter.on_detach

  function highlighter:on_detach()
    common.noautocmd(function()
      on_detach(self)
    end)
  end
end

return M
