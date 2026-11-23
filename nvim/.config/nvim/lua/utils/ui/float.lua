local snacks_util = require('snacks.util')

--- @class utils.ui.float
local M = {}

--- Run `callback` when focus lands in a normal window, as Snacks pickers close: other floats and
--- the cmdline window (E11) don't count. Deferred: nvim-tree's split hop and back loses no focus
--- @param group integer Augroup that lives as long as the float listens
--- @param callback fun()
--- @return nil
function M.on_focus_loss(group, callback)
  vim.api.nvim_create_autocmd('WinEnter', {
    group = group,
    callback = function()
      vim.schedule(function()
        if not snacks_util.is_float() and vim.fn.getcmdwintype() == '' then
          callback()
        end
      end)
    end,
  })
end

return M
