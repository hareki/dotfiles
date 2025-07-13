return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  opts = {
    menu = {
      width = vim.api.nvim_win_get_width(0) - 4,
    },
    settings = {
      save_on_toggle = true,
    },
  },
  keys = function()
    local harpoon = require('harpoon')

    -- harpoon telecope integration
    -- https://github.com/ThePrimeagen/harpoon/tree/harpoon2?tab=readme-ov-file#telescope
    local function toggle_telescope(harpoon_files)
      local conf = require('telescope.config').values
      local pickers = require('telescope.pickers')

      local file_paths = {}

      for _, item in ipairs(harpoon_files.items) do
        table.insert(file_paths, item.value)
      end

      local make_finder = function()
        local paths = {}

        for _, item in ipairs(harpoon_files.items) do
          table.insert(paths, item.value)
        end

        return require('telescope.finders').new_table({
          results = paths,
        })
      end

      pickers
        .new({}, {
          preview_title = Constant.telescope.PREVIEW_TITLE,
          prompt_title = 'Harpoon',
          finder = require('telescope.finders').new_table({
            results = file_paths,
          }),
          previewer = conf.grep_previewer({}),
          sorter = conf.generic_sorter({}),

          -- Delete harpooned file mapping
          -- https://github.com/prdanelli/dotfiles/blob/05a0fe693c622ac8b8e60c8ba8b7a3cdf9cb5057/neovim-lazy/lua/plugins/harpoon.lua#L13
          attach_mappings = function(prompt_buffer_number, map)
            map('n', 'x', function()
              local state = require('telescope.actions.state')
              local selected_entry = state.get_selected_entry()
              local current_picker = state.get_current_picker(prompt_buffer_number)

              table.remove(harpoon:list().items, selected_entry.index)
              current_picker:refresh(make_finder())
            end)

            return true
          end,
        })
        :find()
    end

    local keys = {
      {
        '<leader>H',
        function()
          harpoon:list():add()
          -- Full path of the current buffer
          local filepath = vim.api.nvim_buf_get_name(0)

          -- local filename = vim.fn.fnamemodify(filepath, ':t')
          local relpath = vim.fn.fnamemodify(filepath, ':.')

          Util.notify.info({
            { 'Added ', 'Normal' },
            { relpath, 'NotifyWARNTitle' },
          }, { title = 'harpoon' })
        end,
        desc = 'Harpoon File',
      },
      {
        '<leader>h',
        function()
          toggle_telescope(harpoon:list())
        end,
        desc = 'Harpoon quick menu',
      },
    }

    for i = 1, 5 do
      table.insert(keys, {
        '<leader>' .. i,
        function()
          require('harpoon'):list():select(i)
        end,
        desc = 'Harpoon to File ' .. i,
      })
    end
    return keys
  end,
}
