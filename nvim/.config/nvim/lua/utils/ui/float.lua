--- @class utils.ui.float
local M = {}

--- Run `callback` whenever focus lands in a normal window, which is where a float closes itself,
--- like Snacks pickers: other floats keep it open, and so does the cmdline window, where closing a
--- window fails (E11). Deferred like the pickers' check, so that a hop through a split and back
--- (nvim-tree on file removal) loses no focus
--- @param group integer Augroup that lives as long as the float listens
--- @param callback fun()
--- @return nil
function M.on_focus_loss(group, callback)
  vim.api.nvim_create_autocmd('WinEnter', {
    group = group,
    callback = function()
      vim.schedule(function()
        if not Snacks.util.is_float() and vim.fn.getcmdwintype() == '' then
          callback()
        end
      end)
    end,
  })
end

return M
