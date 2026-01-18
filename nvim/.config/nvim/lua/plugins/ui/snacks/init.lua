return {
  Catppuccin(function(palette)
    return {
      SnacksPickerPrompt = { fg = palette.blue },
      SnacksPickerCursorLine = { bg = palette.base },
      SnacksPickerPreviewCursorLine = { link = 'CursorLine' },
      SnacksPickerKeymapLhs = { fg = palette.blue },
      SnacksPickerSelected = { bg = palette.base, fg = palette.text },
      SnacksPickerUnselected = { bg = palette.base, fg = palette.text },
      SnacksPickerDir = { fg = palette.overlay1 },
      SnacksPickerFile = { fg = palette.text },
      SnacksPickerTime = { fg = palette.text },
    }
  end),
  {
    'hareki/snacks.nvim',
    event = 'VeryLazy',
    keys = function()
      return {
        {
          '<leader>g',
          function()
            Snacks.lazygit()
          end,
          desc = 'Lazygit',
        },
        {
          '<leader><leader>',
          function()
            Snacks.picker.files()
          end,
          desc = 'Find Files',
        },
        {
          '<leader>fd',
          function()
            Snacks.picker.diagnostics_buffer()
          end,
          desc = 'Find Diagnostics Buffer',
        },
        {
          '<leader>fD',
          function()
            Snacks.picker.diagnostics()
          end,
          desc = 'Find Diagnostics',
        },
        {
          '<leader>f/',
          function()
            Snacks.picker.grep({
              title = 'Grep',
              regex = false,
            })
          end,
          desc = 'Find Text',
        },
        {
          '<leader>fb',
          function()
            Snacks.picker.buffers({
              title = 'Buffers',
            })
          end,
          desc = 'Find Buffers',
        },
        {
          '<leader>fR',
          function()
            Snacks.picker.registers()
          end,
          desc = "Find Registers' Contents",
        },
        {
          '<leader>fk',
          function()
            Snacks.picker.keymaps()
          end,
          mode = { 'n', 'x' },
          desc = 'Find Keymaps',
        },
        {
          '<leader>fu',
          function()
            Snacks.picker.undo()
          end,
          desc = 'Open Undo History',
        },

        {
          '<leader>fh',
          function()
            Snacks.picker.highlights()
          end,
          desc = 'Find Highlight Groups',
        },
        {
          '<leader>fH',
          function()
            Snacks.picker.help()
          end,
          desc = 'Find Helps',
        },
        {
          '<leader>fgb',
          function()
            Snacks.picker.git_branches()
          end,
          desc = 'Find Git Branches',
        },
        {
          '<leader>.',
          function()
            Snacks.scratch()
          end,
          desc = 'Toggle Scratch Buffer',
        },
        {
          '<leader>f.',
          function()
            Snacks.scratch.select()
          end,
          desc = 'Select Scratch Buffer',
        },
        {
          '<A-t>',
          function()
            Snacks.terminal.toggle(nil, { win = { position = 'float' } })
          end,
          mode = { 'n', 't', 'i' },
          desc = 'Toggle Floating Terminal',
        },
      }
    end,
    opts = function()
      local popup_config = require('utils.ui').popup_config
      local picker_config = require('configs.picker')
      local icons = require('configs.icons')
      local config = {
        input = popup_config('input'),
        full = popup_config('full'),
        sm = popup_config('sm', true),
        lg_border = popup_config('lg', true),
        lg = popup_config('lg'),
      }
      local select_width = config.sm.width

      local utils = require('plugins.ui.snacks.utils')
      local actions = require('plugins.ui.snacks.actions')

      return {
        words = { enabled = true },
        bigfile = { enabled = true },
        input = { enabled = true, start_in_insert = true },
        lazygit = { enabled = true, configure = false },
        scratch = { enabled = true },
        rename = { enabled = true },

        picker = {
          icons = {
            ui = {
              selected = icons.explorer.selected,
              unselected = icons.explorer.unselected,
            },
          },
          ui_select = true,
          prompt = picker_config.prompt_prefix,

          actions = {
            list_half_page_down = actions.scroll_half_page('down'),
            list_half_page_up = actions.scroll_half_page('up'),
            toggle_preview_focus = actions.toggle_preview_focus,
            select = actions.select,
            snacks_to_trouble = actions.snacks_to_trouble,
          },

          win = {
            preview = {
              keys = {
                ['<Tab>'] = { 'toggle_preview_focus', mode = { 'i', 'n' } },
                ['<CR>'] = { 'confirm' },
                ['<C-t>'] = { 'snacks_to_trouble', mode = { 'i', 'n' } },
              },
              wo = {
                number = true,
                relativenumber = true,
              },
            },
            input = {
              keys = {
                ['<PageDown>'] = { 'list_half_page_down', mode = { 'i', 'n' } },
                ['<PageUp>'] = { 'list_half_page_up', mode = { 'i', 'n' } },
                ['<Tab>'] = { 'toggle_preview_focus', mode = { 'i', 'n' } },

                ['<C-t>'] = { 'snacks_to_trouble', mode = { 'i', 'n' } },
                ['<C-Down>'] = { 'history_forward', mode = { 'i', 'n' } },
                ['<C-Up>'] = { 'history_back', mode = { 'i', 'n' } },

                ['<C-c>'] = { 'cancel', mode = { 'i', 'n' } },
                ['<C-p>'] = { 'select_and_prev', mode = { 'i', 'n' } },
                ['<C-n>'] = { 'select_and_next', mode = { 'i', 'n' } },
              },
            },
          },

          -- Default layout
          layout = {
            layout = {
              backdrop = false,
              width = config.lg_border.width,
              max_width = config.lg_border.width,
              height = config.lg_border.height,
              max_height = config.lg_border.height,
              border = 'none',
              box = 'vertical',
              {
                box = 'vertical',
                border = 'rounded',
                title = '{title} {live}',
                title_pos = 'center',
                { win = 'input', height = 1, border = 'bottom' },
                { win = 'list', border = 'none' },
              },
              {
                win = 'preview',
                title = picker_config.preview_title,
                height = 0.5,
                border = 'rounded',
              },
            },
          },

          sources = {
            select = {
              layout = {
                layout = {
                  width = select_width,
                  max_width = select_width,
                },
              },
            },

            buffers = {
              format = utils.buffer_format,
              matcher = { sort_empty = true }, -- Required for sort to work with empty search
              sort = utils.buffer_sort,
              win = {
                input = {
                  keys = {
                    ['x'] = { 'bufdelete', mode = { 'n' } }, -- close selected buffer from input (normal mode)
                  },
                },
              },
            },

            files = {
              hidden = true,
              transform = utils.files_transform,
            },

            scratch = {
              win = {
                input = {
                  keys = {
                    ['x'] = { 'scratch_delete', mode = { 'n' } },
                  },
                },
              },
            },

            keymaps = {
              layout = {
                preview = false,
                preset = 'default',
                layout = {
                  backdrop = false,
                  height = config.sm.height,
                  width = config.sm.width,
                  max_height = config.sm.height,
                  max_width = config.sm.width,
                  col = config.sm.col,
                  row = config.sm.row,
                },
              },
              transform = utils.keymap_transform,
              format = function(item, picker)
                return utils.keymap_format(item, picker, config.sm.width)
              end,
            },
          },
        },

        styles = {
          input = {
            height = config.input.height,
            width = config.input.width,
            col = config.input.col,
            row = config.input.row,
          },
          scratch = {
            height = config.lg.height,
            width = config.lg.width,
            col = config.lg.col,
            row = config.lg.row,
          },
          terminal = {
            title = ' Terminal ',
            title_pos = 'center',
            border = 'rounded',
            height = config.lg.height,
            width = config.lg.width,
            col = config.lg.col,
            row = config.lg.row,
          },
          lazygit = {
            backdrop = false,
            border = 'rounded',
            title = ' Lazygit ',
            title_pos = 'center',
            height = config.full.height,
            width = config.full.width,
            col = config.full.col,
            row = config.full.row,
          },
        },
      }
    end,
  },
}
