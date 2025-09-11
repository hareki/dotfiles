return {
  'LukasPietzschmann/telescope-tabs',
  keys = {
    {
      '<leader>ft',
      function()
        require('telescope-tabs').list_tabs()
      end,
      desc = 'Find Tabs',
    },
  },
  opts = function()
    return {
      entry_formatter = function(tab_id, buffer_ids, file_names, file_paths, is_current)
        return require('utils.tab').get_tab_name(tab_id, buffer_ids)
          .. (is_current and ' ' or '')
      end,
      entry_ordinal = function(tab_id, buffer_ids, file_names)
        return require('utils.tab').get_tab_name(tab_id, buffer_ids)
          .. ' '
          .. table.concat(file_names, ' ')
      end,
    }
  end,
  config = function(_, opts)
    require('telescope-tabs').setup(opts)
    require('telescope').load_extension('telescope-tabs')
  end,
}
