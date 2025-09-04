return {
  require('utils.ui').catppuccin(function(palette)
    return {
      SnacksPickerCursorLine = { bg = palette.base },
      SnacksPickerPrompt = { fg = palette.blue },
      SnacksPickerKeymapLhs = { fg = palette.blue },
    }
  end),
  {
    'folke/snacks.nvim',
    lazy = false,
    priority = 100,
    keys = {
      {
        '<leader>g',
        function()
          Snacks.lazygit()
        end,
        desc = 'Open Lazygit',
      },
      {
        '<leader>fk',
        function()
          Snacks.picker.keymaps()
        end,
        desc = 'Find Keymaps',
        mode = { 'n', 'x' },
      },
    },
    opts = function()
      local popup_config = require('utils.ui').popup_config
      local input_config = popup_config('input')
      local lazygit_config = popup_config('full')
      local picker_config = popup_config('sm', true)

      ---@param direction 'up' | 'down'
      local function scroll_half_page(direction)
        return function(picker)
          local list_win = picker.layout.opts.wins.list.win
          local h = vim.api.nvim_win_get_height(list_win)
          local row = vim.api.nvim_win_get_cursor(list_win)[1]
          local target_row = row
            + (math.max(1, math.floor(h / 2))) * (direction == 'up' and -1 or 1)
          local idx = picker.list:row2idx(target_row)
          picker.list:_move(idx, true, true)
        end
      end

      local snacks_utils = require('plugins.ui.snacks.utils')

      return {
        words = { enabled = true },
        bigfile = { enabled = true },
        input = { enabled = true },
        lazygit = { enabled = true, configure = false },

        picker = {
          prompt = require('configs.icons').telescope.prompt_prefix,
          actions = {
            list_half_page_down = scroll_half_page('down'),
            list_half_page_up = scroll_half_page('up'),
          },
          win = {
            input = {
              keys = {
                ['<PageDown>'] = { 'list_half_page_down', mode = { 'i', 'n' } },
                ['<PageUp>'] = { 'list_half_page_up', mode = { 'i', 'n' } },
              },
            },
          },
          sources = {
            keymaps = {
              layout = {
                preview = false,
                preset = 'default',
                layout = {
                  backdrop = false,
                  height = picker_config.height,
                  width = picker_config.width,
                  max_height = picker_config.height,
                  max_width = picker_config.width,
                  col = picker_config.col,
                  row = picker_config.row,
                },
              },
              transform = snacks_utils.keymap_transform,
              format = function(item, picker)
                return snacks_utils.keymap_format(item, picker, picker_config.width)
              end,
            },
          },
        },

        styles = {
          input = {
            height = input_config.height,
            width = input_config.width,
            col = input_config.col,
            row = input_config.row,
          },
          lazygit = {
            backdrop = false,
            border = 'rounded',
            title = ' Lazygit ',
            title_pos = 'center',
            height = lazygit_config.height,
            width = lazygit_config.width,
            col = lazygit_config.col,
            row = lazygit_config.row,
          },
        },
      }
    end,
  },
}
