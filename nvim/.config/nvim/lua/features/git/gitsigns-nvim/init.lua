return {
  UI.catppuccin(function(_, sub_palette)
    return {
      GitSignsStagedAdd = { fg = sub_palette.green },
      GitSignsStagedUntracked = { link = 'GitSignsStagedAdd' },

      GitSignsStagedChange = { fg = sub_palette.yellow },
      GitSignsStagedChangedelete = { link = 'GitSignsStagedChange' },

      GitSignsStagedDelete = { fg = sub_palette.red },
      GitSignsStagedTopDelete = { link = 'GitSignsStagedDelete' },
    }
  end),

  UI.which_key({
    specs = { '<leader>h', group = 'Gitsigns', mode = { 'n', 'v' } },
    rules = { pattern = 'gitsigns', icon = Conf.Icons.git.sign, color = 'yellow' },
  }),

  {
    'hareki/gitsigns.nvim',
    event = 'VeryLazy',
    opts = function()
      local hunk = Conf.Icons.git.hunk
      local hunk_delete = Conf.Icons.git.hunk_delete
      local utils = require('features.git.gitsigns-nvim.utils')
      local build_popup_navigation = utils.build_popup_navigation

      return {
        numhl = false,
        signcolumn = true,

        current_line_blame = true,
        current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
        current_line_blame_opts = {
          delay = 300,
          virt_text = true,
          virt_text_priority = 999,
        },

        get_popup_max_height = function()
          return math.floor(vim.o.lines * Conf.Size.inline_popup.max_height)
        end,
        preview_config = {
          border = 'rounded',
        },

        diff_opts = {
          -- Use native git diff instead of Neovim's xdiff to match VS Code's diff
          internal = false,

          ignore_whitespace = false,
          ignore_whitespace_change = false,
          ignore_whitespace_change_at_eol = false,
          ignore_blank_lines = false,
        },

        signs = {
          add = { text = hunk },
          change = { text = hunk },
          delete = { text = hunk_delete },
          topdelete = { text = hunk_delete },
          changedelete = { text = hunk },
          untracked = { text = hunk },
        },

        signs_staged = {
          add = { text = hunk },
          change = { text = hunk },
          delete = { text = hunk_delete },
          topdelete = { text = hunk_delete },
          changedelete = { text = hunk },
        },

        on_attach = function(buffer)
          local gs = package.loaded.gitsigns

          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = buffer, desc = desc, silent = true })
          end

          map('n', ']h', function()
            if vim.wo.diff then
              vim.cmd.normal({ ']c', bang = true })
            else
              gs.nav_hunk('next')
            end
          end, 'Next Hunk')

          map('n', '[h', function()
            if vim.wo.diff then
              vim.cmd.normal({ '[c', bang = true })
            else
              gs.nav_hunk('prev')
            end
          end, 'Previous Hunk')

          map('n', ']H', function()
            gs.nav_hunk('last')
          end, 'Last Hunk')

          map('n', '[H', function()
            gs.nav_hunk('first')
          end, 'First Hunk')

          map({ 'n', 'v' }, '<leader>hs', ':Gitsigns stage_hunk<CR>', 'Stage Hunk')
          map({ 'n', 'v' }, '<leader>hr', ':Gitsigns reset_hunk<CR>', 'Reset Hunk')
          map('n', '<leader>hS', gs.stage_buffer, 'Stage Buffer')
          map('n', '<leader>hu', gs.undo_stage_hunk, 'Undo Stage Hunk')
          map('n', '<leader>hR', gs.reset_buffer, 'Reset Buffer')

          map('n', '<leader>hB', function()
            gs.blame()
          end, 'Blame Buffer')

          map('n', '<leader>hd', gs.diffthis, 'Diff This')
          map('n', '<leader>hD', function()
            gs.diffthis('~')
          end, 'Diff This ~')
          map({ 'o', 'x' }, 'ih', '<cmd>Gitsigns select_hunk<cr>', 'Gitsigns Select Hunk')

          map('n', '<leader>hb', function()
            local gitsigns = require('gitsigns')
            gitsigns.blame_line({ full = true }, build_popup_navigation(buffer, 'blame'))
          end, 'Blame Line')

          map('n', '<leader>hp', function()
            local gitsigns = require('gitsigns')
            gitsigns.preview_hunk()
            vim.schedule(build_popup_navigation(buffer, 'hunk'))
          end, 'Preview Hunk')
        end,
      }
    end,
  },
}
