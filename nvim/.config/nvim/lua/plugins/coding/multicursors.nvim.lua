local ui_utils = require('utils.ui')

return {
  ui_utils.catppuccin(function(palette)
    return {
      HydraRed = { fg = palette.red },
      HydraAmaranth = { fg = palette.maroon },
      HydraBlue = { fg = palette.blue },
      HydraTeal = { fg = palette.teal },
      HydraPink = { fg = palette.pink },
      MultiCursor = { bg = '#414e70' },
      MultiCursorMain = { bg = '#414e70' },
      MultiCursorSeparator = { link = 'WhichKeySeparator' },
    }
  end),
  {
    'hareki/multicursors.nvim',
    dependencies = { 'nvimtools/hydra.nvim' },
    cmd = { 'MCstart' },
    keys = {
      {
        mode = { 'x', 'n' },
        '<Leader>m',
        function()
          Snacks.words.disable()
          vim.cmd.MCstart()
        end,
        desc = 'Multicursors start',
      },
    },

    opts = function()
      local hint_separator = '➜'

      local N = require('multicursors.normal_mode')
      local E = require('multicursors.extend_mode')
      local I = require('multicursors.insert_mode')

      vim.api.nvim_create_autocmd('User', {
        pattern = 'MultiCursorExit',
        callback = function()
          Snacks.words.enable()
          Snacks.words.update()
        end,
      })

      vim.api.nvim_create_autocmd('FileType', {
        -- hydra.nvim uses ft=hydra; some setups report hydra_hint
        pattern = { 'hydra', 'hydra_hint' },
        callback = function(ev)
          vim.api.nvim_buf_call(ev.buf, function()
            vim.cmd([[syntax match MultiCursorSeparator /]] .. hint_separator .. [[/]])
          end)
        end,
      })

      return {
        default_mappings = false,
        normal_keys = {
          ['n'] = { method = N.find_next, opts = { desc = 'Next match' } },
          ['N'] = { method = N.find_prev, opts = { desc = 'Previous match' } },

          ['r'] = { method = N.replace, opts = { desc = 'Replace' } },

          ['d'] = { method = N.delete, opts = { desc = 'Delete', nowait = false } },
          ['dd'] = { method = N.delete_line, opts = { desc = 'Delete line' } },
          ['D'] = { method = N.delete_end, opts = { desc = 'Delete end' } },

          ['y'] = { method = N.yank, opts = { desc = 'Yank', nowait = false } },
          ['yy'] = { method = N.yank_line, opts = { desc = 'Yank line' } },
          ['Y'] = { method = N.yank_end, opts = { desc = 'Yank end' } },

          ['s'] = { method = N.skip_find_next, opts = { desc = 'Skip and next' } },
          ['S'] = { method = N.skip_find_prev, opts = { desc = 'Skip and previous' } },

          ['p'] = { method = N.paste_after, opts = { desc = 'Paste after' } },
          ['P'] = { method = N.paste_before, opts = { desc = 'Paste before' } },

          ['}'] = { method = N.skip_goto_next, opts = { desc = 'Undo next match' } },
          ['{'] = { method = N.skip_goto_prev, opts = { desc = 'Undo previous match' } },
          [']'] = { method = N.goto_next, opts = { desc = 'Goto next match' } },
          ['['] = { method = N.goto_prev, opts = { desc = 'Goto previous match' } },
          ['@'] = { method = N.run_macro, opts = { desc = 'Run macro' } },
          [':'] = { method = N.normal_command, opts = { desc = 'Normal command' } },
          ['.'] = { method = N.dot_repeat, opts = { desc = 'Dot repeat' } },

          ['gU'] = { method = N.upper_case, opts = { desc = 'Upper case' } },
          ['gu'] = { method = N.lower_case, opts = { desc = 'lower case' } },

          ['<C-a>'] = { method = N.find_all_matches, opts = { desc = 'All matches' } },
        },

        insert_keys = {
          ['<BS>'] = { method = I.BS_method, opts = { desc = 'Backspace' } },
          ['<CR>'] = { method = I.CR_method, opts = { desc = 'Newline' } },
          ['<Del>'] = { method = I.Del_method, opts = { desc = 'Delete' } },

          ['<A-BS>'] = {
            method = I.C_w_method,
            opts = { desc = 'Delete word backward' },
          },

          ['<A-Right>'] = { method = I.C_Right, opts = { desc = 'Word forward' } },
          ['<A-Left>'] = { method = I.C_Left, opts = { desc = 'Word backward' } },

          ['<Esc>'] = { method = nil, opts = { desc = 'exit' } },

          ['<End>'] = {
            method = I.End_method,
            opts = { desc = 'End of line' },
          },
          ['<Home>'] = {
            method = I.Home_method,
            opts = { desc = 'Start of line' },
          },
          ['<Right>'] = { method = I.Right_method, opts = { desc = 'Move right' } },
          ['<Left>'] = { method = I.Left_method, opts = { desc = 'Move left' } },
          ['<Down>'] = { method = I.Down_method, opts = { desc = 'Move down' } },
          ['<Up>'] = { method = I.UP_method, opts = { desc = 'Move up' } },
        },

        extend_keys = {
          ['w'] = { method = E.w_method, opts = { desc = 'Start word forward' } },
          ['b'] = { method = E.b_method, opts = { desc = 'Start word backward' } },
          ['e'] = { method = E.e_method, opts = { desc = 'End word forward' } },
          ['o'] = { method = E.o_method, opts = { desc = 'Toggle anchor' } },
          ['<Left>'] = { method = E.h_method, opts = { desc = 'Char left' } },
          ['<Down>'] = { method = E.j_method, opts = { desc = 'Char down' } },
          ['<Up>'] = { method = E.k_method, opts = { desc = 'Char up' } },
          ['<Right>'] = { method = E.l_method, opts = { desc = 'Char right' } },
          ['t'] = { method = E.node_parent, opts = { desc = 'Expand node' } },
          ['^'] = { method = E.caret_method, opts = { desc = 'Start of line' } },
          ['$'] = { method = E.dollar_method, opts = { desc = 'End of line' } },
          ['u'] = { method = E.undo_history, opts = { desc = 'Undo last extend' } },
          ['c'] = { method = E.custom_method, opts = { desc = 'Custom motion' } },
          ['<Esc>'] = { method = nil, opts = { desc = 'exit' } },
        },

        hint_config = {
          float_opts = {
            border = 'rounded',
          },
        },
        generate_hints = {
          config = {
            padding = { 1, 2 },
            hint_separator = hint_separator,
            max_hint_length = 30,
          },
        },
      }
    end,
  },
}
