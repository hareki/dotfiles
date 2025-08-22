return {
  'LukasPietzschmann/telescope-tabs',
  keys = {
    {
      '<leader>ft',
      function()
        require('telescope-tabs').list_tabs()
      end,
      desc = 'Tabs',
    },
  },
  opts = {
    entry_formatter = function(tab_id, buffer_ids, file_names, file_paths, is_current)
      local idx = vim.api.nvim_tabpage_get_number(tab_id)
      local name = (vim.t[idx] and vim.t[idx].tab_name)
      if not name or name == '' then
        name = ('Tab %d'):format(idx)
      end
      -- return is_current and ('[' .. name .. ']') or name
      return name .. (is_current and ' ' or '')
    end,
    entry_ordinal = function(tab_id, buffer_ids, file_names)
      local idx = vim.api.nvim_tabpage_get_number(tab_id)
      local name = (vim.t[idx] and vim.t[idx].tab_name) or ('Tab ' .. idx)
      return name .. ' ' .. table.concat(file_names, ' ')
    end,
  },
  config = function(_, opts)
    require('telescope-tabs').setup(opts)
    require('telescope').load_extension('telescope-tabs')
  end,
}
