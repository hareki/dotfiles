local M = {}

local function current_tab_index()
  return vim.api.nvim_tabpage_get_number(vim.api.nvim_get_current_tabpage())
end

function M.lualine_component()
  local name = vim.t.tab_name
  if not name or name == '' then
    name = 'Tab ' .. current_tab_index()
  end
  return name
end

local autocommand_group = vim.api.nvim_create_augroup('TabDefaultNames', { clear = true })

vim.api.nvim_create_autocmd('TabEnter', {
  group = autocommand_group,
  callback = function()
    vim.schedule(function()
      local old_name = vim.t.tab_name
      local diffview = require('diffview.lib').get_current_view()
      if diffview then
        vim.t.tab_name = 'Diffview'
      else
        vim.t.tab_name = 'Tab ' .. current_tab_index()
      end

      if old_name ~= vim.t.tab_name then
        require('lualine').refresh({ place = { 'statusline' } })
      end
    end)
  end,
})

vim.api.nvim_create_user_command('TabRename', function(command_opts)
  vim.t.tab_name = command_opts.args
  require('lualine').refresh({ place = { 'statusline' } })
end, { nargs = 1 })

return M
