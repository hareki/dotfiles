return {
  require('utils.ui').catppuccin(function(palette)
    return {
      SnacksPickerPrompt = { fg = palette.blue },
      SnacksPickerCursorLine = { bg = palette.base },
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
    keys = {
      {
        '<leader>g',
        function()
          Snacks.lazygit()
        end,
        desc = 'Open Lazygit',
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
        '<leader>fy',
        function()
          Snacks.picker.yanky()
        end,
        desc = 'Open Yanky History',
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
        desc = 'Find Keymaps',
        mode = { 'n', 'x' },
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
        '<leader>ft',
        function()
          require('plugins.ui.snacks.pickers.tabs')()
        end,
        desc = 'Find Tabs',
      },
    },
    opts = function()
      local popup_config = require('utils.ui').popup_config
      local picker_config = require('configs.picker')
      local icons = require('configs.icons')
      local input_popup_config = popup_config('input')
      local full_popup_config = popup_config('full')
      local sm_popup_config = popup_config('sm', true)
      local lg_popup_config = popup_config('lg', true)
      local select_width = sm_popup_config.width

      local utils = require('plugins.ui.snacks.utils')
      local actions = require('plugins.ui.snacks.actions')

      return {
        words = { enabled = true },
        bigfile = { enabled = true },
        input = { enabled = true },
        lazygit = { enabled = true, configure = false },

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
            },
            input = {
              keys = {
                ['<PageDown>'] = { 'list_half_page_down', mode = { 'i', 'n' } },
                ['<PageUp>'] = { 'list_half_page_up', mode = { 'i', 'n' } },
                ['<Tab>'] = { 'toggle_preview_focus', mode = { 'i', 'n' } },
                ['m'] = { 'select' },
                ['<C-t>'] = { 'snacks_to_trouble', mode = { 'i', 'n' } },
                ['<C-Down>'] = { 'history_forward', mode = { 'i', 'n' } },
                ['<C-Up>'] = { 'history_back', mode = { 'i', 'n' } },
                ['<C-c>'] = { 'cancel', mode = { 'i', 'n' } },
              },
            },
          },

          -- Default layout
          layout = {
            layout = {
              backdrop = false,
              width = lg_popup_config.width,
              max_width = lg_popup_config.width,
              height = lg_popup_config.height,
              max_height = lg_popup_config.height,
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
              -- ignored = true,
              -- follow = true,
            },

            keymaps = {
              layout = {
                preview = false,
                preset = 'default',
                layout = {
                  backdrop = false,
                  height = sm_popup_config.height,
                  width = sm_popup_config.width,
                  max_height = sm_popup_config.height,
                  max_width = sm_popup_config.width,
                  col = sm_popup_config.col,
                  row = sm_popup_config.row,
                },
              },
              transform = utils.keymap_transform,
              format = function(item, picker)
                return utils.keymap_format(item, picker, sm_popup_config.width)
              end,
            },
          },
        },

        styles = {
          input = {
            height = input_popup_config.height,
            width = input_popup_config.width,
            col = input_popup_config.col,
            row = input_popup_config.row,
          },
          lazygit = {
            backdrop = false,
            border = 'rounded',
            title = ' Lazygit ',
            title_pos = 'center',
            height = full_popup_config.height,
            width = full_popup_config.width,
            col = full_popup_config.col,
            row = full_popup_config.row,
          },
        },
      }
    end,
  },
}
