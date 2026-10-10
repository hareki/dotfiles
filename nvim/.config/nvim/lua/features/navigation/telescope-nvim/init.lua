-- [[ Only needed for nvim-notify as of now]]
return {
  UI.catppuccin(function(palette)
    return {
      TelescopeBufferMarker = { fg = palette.peach },
      TelescopePromptPrefix = { fg = palette.blue },
      TelescopeMultiIcon = { fg = palette.blue },
      TelescopeSelectionCaret = { fg = palette.blue },
      TelescopeSelection = { link = 'ListCursorLine' },
      TelescopeMultiSelection = {},
    }
  end, 'telescope.nvim'),

  {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope',
    dependencies = {
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        -- https://github.com/nvim-telescope/telescope-fzf-native.nvim/issues/120#issuecomment-2200296884
        build = 'make',
      },
    },

    opts = function()
      local actions = require('telescope.actions')
      local utils = require('features.navigation.telescope-nvim.utils')

      utils.install_vertical_layout()
      utils.setup_previewer_autocmd()

      local scroll_results_up = utils.scroll_results('up')
      local scroll_results_down = utils.scroll_results('down')

      local layout_config = UI.layout.telescope
      local telescope_config = require('telescope.config')
      local default_get_status_text = telescope_config.values.get_status_text

      return {
        defaults = {
          prompt_prefix = Conf.picker.PROMPT_PREFIX,
          selection_caret = ' ',
          entry_prefix = ' ', -- keep list text aligned
          multi_icon = vim.trim(Conf.icons.file_tree.SELECTED) .. ' ',
          get_status_text = function(self, opts)
            -- Prevent flashing the loading asterisk indicator
            opts = opts or {}
            opts.completed = true

            local text = default_get_status_text(self, opts)
            if text == '' then
              return ''
            end

            -- Remove spaces around /
            return text:gsub('%s*/%s*', '/') .. ' '
          end,
          -- Merge prompt and results windows
          results_title = false,
          borderchars = Conf.icons.telescope_borders,

          -- Make results appear from top to bottom
          -- https://github.com/nvim-telescope/telescope.nvim/issues/1933
          sorting_strategy = 'ascending',

          layout_strategy = 'vertical',
          layout_config = {
            vertical = vim.tbl_extend('error', {
              mirror = true,
              preview_height = 0.45,
              preview_cutoff = 1, -- Preview should always show (unless previewer = false)
              prompt_position = 'top',
            }, layout_config('lg')),
          },

          -- Open files in the first window that is an actual file.
          -- Use the current window if no other window is available.
          get_selection_window = function()
            local wins = vim.api.nvim_list_wins()
            table.insert(wins, 1, vim.api.nvim_get_current_win())
            for _, win in ipairs(wins) do
              local buf = vim.api.nvim_win_get_buf(win)
              if vim.bo[buf].buftype == '' then
                return win
              end
            end
            return 0
          end,

          mappings = {
            n = {
              ['q'] = actions.close,
              ['<Tab>'] = utils.toggle_focus_preview,
              ['<C-n>'] = actions.toggle_selection + actions.move_selection_worse,
              ['<C-p>'] = actions.toggle_selection + actions.move_selection_better,
              ['<PageUp>'] = scroll_results_up,
              ['<PageDown>'] = scroll_results_down,
              ['<c-t>'] = utils.telescope_to_trouble,
            },
            i = {
              ['<Tab>'] = utils.toggle_focus_preview,
              ['<C-n>'] = actions.toggle_selection + actions.move_selection_worse,
              ['<C-p>'] = actions.toggle_selection + actions.move_selection_better,
              ['<PageUp>'] = scroll_results_up,
              ['<PageDown>'] = scroll_results_down,
              ['<c-t>'] = utils.telescope_to_trouble,
            },
          },
        },
      }
    end,

    config = function(_, opts)
      local telescope = require('telescope')

      telescope.setup(opts)
      telescope.load_extension('fzf')
    end,
  },
}
