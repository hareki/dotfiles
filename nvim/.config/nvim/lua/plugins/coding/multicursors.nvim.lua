local ui_utils = require('utils.ui')

return {
  ui_utils.catppuccin(function(palette)
    return {
      HydraRed = { fg = palette.red },
      HydraAmaranth = { fg = palette.maroon },
      HydraTeal = { fg = palette.teal },

      -- HACK: switching up the colors to make it look good like "which-key" panel
      HydraBlue = { fg = palette.yellow },
      HydraPink = { fg = palette.blue },

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
        desc = 'Multicursors: Start',
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
          ['n'] = { method = N.find_next, opts = { desc = 'Next Match' } },
          ['N'] = { method = N.find_prev, opts = { desc = 'Previous Match' } },

          ['r'] = { method = N.replace, opts = { desc = 'Replace' } },

          ['d'] = { method = N.delete, opts = { desc = 'Delete', nowait = false } },
          ['dd'] = { method = N.delete_line, opts = { desc = 'Delete Line' } },
          ['D'] = { method = N.delete_end, opts = { desc = 'Delete End' } },

          ['y'] = { method = N.yank, opts = { desc = 'Yank', nowait = false } },
          ['yy'] = { method = N.yank_line, opts = { desc = 'Yank Line' } },
          ['Y'] = { method = N.yank_end, opts = { desc = 'Yank End' } },

          ['s'] = { method = N.skip_find_next, opts = { desc = 'Skip and Next' } },
          ['S'] = { method = N.skip_find_prev, opts = { desc = 'Skip and Previous' } },

          ['p'] = { method = N.paste_after, opts = { desc = 'Paste After' } },
          ['P'] = { method = N.paste_before, opts = { desc = 'Paste Before' } },

          ['}'] = { method = N.skip_goto_next, opts = { desc = 'Undo Next Match' } },
          ['{'] = { method = N.skip_goto_prev, opts = { desc = 'Undo Previous Match' } },
          [']'] = { method = N.goto_next, opts = { desc = 'Goto Next Match' } },
          ['['] = { method = N.goto_prev, opts = { desc = 'Goto Previous Match' } },
          ['@'] = { method = N.run_macro, opts = { desc = 'Run Macro' } },
          [':'] = { method = N.normal_command, opts = { desc = 'Normal Command' } },
          ['.'] = { method = N.dot_repeat, opts = { desc = 'Dot Repeat' } },

          ['gU'] = { method = N.upper_case, opts = { desc = 'Uppercase' } },
          ['gu'] = { method = N.lower_case, opts = { desc = 'Lowercase' } },

          ['<C-a>'] = { method = N.find_all_matches, opts = { desc = 'All Matches' } },
        },

        insert_keys = {
          ['<BS>'] = { method = I.BS_method, opts = { desc = 'Backspace' } },
          ['<CR>'] = { method = I.CR_method, opts = { desc = 'Newline' } },
          ['<Del>'] = { method = I.Del_method, opts = { desc = 'Delete' } },

          ['<A-BS>'] = {
            method = I.C_w_method,
            opts = { desc = 'Delete Word Backward' },
          },

          ['<A-Right>'] = { method = I.C_Right, opts = { desc = 'Word Forward' } },
          ['<A-Left>'] = { method = I.C_Left, opts = { desc = 'Word Backward' } },

          ['<Esc>'] = { method = nil, opts = { desc = 'exit' } },

          ['<End>'] = {
            method = I.End_method,
            opts = { desc = 'End of Line' },
          },
          ['<Home>'] = {
            method = I.Home_method,
            opts = { desc = 'Start of Line' },
          },
          ['<Right>'] = { method = I.Right_method, opts = { desc = 'Move Right' } },
          ['<Left>'] = { method = I.Left_method, opts = { desc = 'Move Left' } },
          ['<Down>'] = { method = I.Down_method, opts = { desc = 'Move Down' } },
          ['<Up>'] = { method = I.UP_method, opts = { desc = 'Move Up' } },
        },

        extend_keys = {
          ['w'] = { method = E.w_method, opts = { desc = 'Start Word Forward' } },
          ['b'] = { method = E.b_method, opts = { desc = 'Start Word Backward' } },
          ['e'] = { method = E.e_method, opts = { desc = 'End Word Forward' } },
          ['o'] = { method = E.o_method, opts = { desc = 'Toggle Anchor' } },
          ['<Left>'] = { method = E.h_method, opts = { desc = 'Character Left' } },
          ['<Down>'] = { method = E.j_method, opts = { desc = 'Character Down' } },
          ['<Up>'] = { method = E.k_method, opts = { desc = 'Character Up' } },
          ['<Right>'] = { method = E.l_method, opts = { desc = 'Character Right' } },
          ['t'] = { method = E.node_parent, opts = { desc = 'Expand Node' } },
          ['^'] = { method = E.caret_method, opts = { desc = 'Start of Line' } },
          ['$'] = { method = E.dollar_method, opts = { desc = 'End of Line' } },
          ['u'] = { method = E.undo_history, opts = { desc = 'Undo Last Extend' } },
          ['c'] = { method = E.custom_method, opts = { desc = 'Custom Motion' } },
          ['<Esc>'] = { method = nil, opts = { desc = 'Exit' } },
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
