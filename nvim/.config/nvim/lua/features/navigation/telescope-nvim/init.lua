-- [[ Only needed for nvim-notify as of now]]
return {
  UI.catppuccin(function(palette)
    return {
      TelescopeBufferMarker = { fg = palette.peach },
      TelescopePromptPrefix = { fg = palette.blue },
      TelescopeMultiIcon = { fg = palette.blue },
      TelescopeSelectionCaret = { fg = palette.blue },
      TelescopeSelection = {
        fg = 'NONE', -- Disable fg override
        style = {}, -- Disable default bold
      },
    }
  end),

  {
    'nvim-telescope/telescope.nvim',
    version = false, -- telescope did only one release, so use HEAD for now
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
      local builtin = require('telescope.builtin')
      local utils = require('features.navigation.telescope-nvim.utils')

      -- Unify the preview title for all pickers
      local default_picker_configs = {}
      for picker_name, _ in pairs(builtin) do
        default_picker_configs[picker_name] = {
          preview_title = Conf.Picker.TELESCOPE_PREVIEW_TITLE,
        }
      end

      utils.install_vertical_layout()
      utils.setup_previewer_autocmd()

      local scroll_results_up = utils.scroll_results('up')
      local scroll_results_down = utils.scroll_results('down')

      local layout_config = UI.telescope_layout
      local telescope_config = require('telescope.config')
      local default_get_status_text = telescope_config.values.get_status_text

      return {
        extensions = {
          undo = {
            use_delta = true,
            saved_only = true,
          },
        },
        defaults = {
          prompt_prefix = Conf.Picker.PROMPT_PREFIX,
          selection_caret = ' ',
          entry_prefix = ' ', -- keep list text aligned
          multi_icon = vim.trim(Conf.Icons.file_tree.selected) .. ' ',
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
          borderchars = Conf.Icons.borders.telescope,

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

        pickers = vim.tbl_deep_extend('force', default_picker_configs, {
          lsp_definitions = {
            mappings = {
              n = {
                ['<c-t>'] = utils.trouble_open('lsp_definitions'),
              },
              i = {
                ['<c-t>'] = utils.trouble_open('lsp_definitions'),
              },
            },
          },
          lsp_references = {
            mappings = {
              n = {
                ['<c-t>'] = utils.trouble_open('lsp_references'),
              },
              i = {
                ['<c-t>'] = utils.trouble_open('lsp_references'),
              },
            },
          },

          find_files = {
            find_command = utils.find_command,
            hidden = true,
          },

          diagnostics = {
            mappings = {
              n = {
                ['<c-t>'] = utils.trouble_open('diagnostics'),
              },
              i = {
                ['<c-t>'] = utils.trouble_open('diagnostics'),
              },
            },
          },
          buffers = {
            select_current = true,
            -- https://github.com/nvim-telescope/telescope.nvim/issues/1145#issuecomment-903161099
            mappings = {
              n = {
                ['x'] = actions.delete_buffer,
              },
            },
          },
        }),
      }
    end,

    config = function(_, opts)
      local telescope = require('telescope')

      telescope.setup(opts)
      for _, ext in ipairs({ 'fzf' }) do
        telescope.load_extension(ext)
      end

      vim.api.nvim_set_hl(0, 'TelescopeMultiSelection', {})
    end,
  },
}
