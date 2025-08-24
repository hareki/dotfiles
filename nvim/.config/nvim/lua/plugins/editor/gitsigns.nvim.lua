return {
  require('utils.ui').catppuccin(function(_, sub_palette)
    return {
      GitSignsStagedAddNr = { fg = sub_palette.green },
      GitSignsStagedUntrackedNr = { link = 'GitSignsStagedAddNr' },
      GitSignsStagedChangeNr = { fg = sub_palette.yellow },
      GitSignsStagedChangedeleteNr = { link = 'GitSignsStagedChangeNr' },
      GitSignsStagedDeleteNr = { fg = sub_palette.red },
      GitSignsStagedTopDeleteNr = { link = 'GitSignsStagedDeleteNr' },
    }
  end),
  {
    'hareki/gitsigns.nvim',
    event = 'LazyFile',
    opts = function()
      Snacks.toggle({
        name = 'Git Signs',
        get = function()
          return require('gitsigns.config').config.signcolumn
        end,
        set = function(state)
          require('gitsigns').toggle_signs(state)
        end,
      }):map('<leader>uG')

      return {
        numhl = true,
        signcolumn = false,
        signs = {
          add = { text = ' ┃' },
          change = { text = ' ┃' },
          delete = { text = '' },
          topdelete = { text = '' },
          changedelete = { text = ' ┃' },
          untracked = { text = ' ┃' },
        },
        signs_staged = {
          add = { text = ' ┃' },
          change = { text = ' ┃' },
          delete = { text = '' },
          topdelete = { text = '' },
          changedelete = { text = ' ┃' },
        },
        preview_config = {
          border = 'rounded',
        },
        current_line_blame = true,
        current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
        current_line_blame_opts = {
          delay = 300,
          virt_text = true,
          virt_text_priority = 999,
        },
        on_attach = function(buffer)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, desc)
            vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
          end

          local function unmap(mode, l)
            vim.keymap.del(mode, l, { buffer = buffer })
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
          end, 'Prev Hunk')
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
          map('n', '<leader>hp', gs.preview_hunk_inline, 'Preview Hunk Inline')
          map('n', '<leader>hb', function()
            gs.blame_line({ full = true })
          end, 'Blame Line')
          map('n', '<leader>hB', function()
            gs.blame()
          end, 'Blame Buffer')
          map('n', '<leader>hd', gs.diffthis, 'Diff This')
          map('n', '<leader>hD', function()
            gs.diffthis('~')
          end, 'Diff This ~')
          map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', 'GitSigns Select Hunk')

          unmap('n', '<leader>hp')
          map('n', '<leader>hp', function()
            require('gitsigns').preview_hunk()

            vim.schedule(function()
              map('n', '<Esc>', function()
                local popup = require('gitsigns.popup')
                pcall(vim.api.nvim_win_close, popup.is_open('hunk'), true)
              end)

              map('n', '<Tab>', function()
                local popup = require('gitsigns.popup')
                local preview_win_id = popup.is_open('hunk')
                local current_win_id = vim.api.nvim_get_current_win()

                if not preview_win_id or not vim.api.nvim_win_is_valid(preview_win_id) then
                  return
                end

                local preview_buf_id = vim.api.nvim_win_get_buf(preview_win_id)

                local preview_map = function(mode, l, r, desc)
                  vim.keymap.set(mode, l, r, { buffer = preview_buf_id, desc = desc })
                end

                preview_map('n', 'q', function()
                  vim.api.nvim_win_close(preview_win_id, true)
                end)

                preview_map('n', 'q', function()
                  vim.api.nvim_win_close(preview_win_id, true)
                end)

                preview_map('n', '<Esc>', function()
                  vim.api.nvim_win_close(preview_win_id, true)
                end)

                preview_map('n', '<Tab>', function()
                  require('utils.common').noautocmd(function()
                    popup.ignore_cursor_moved = true
                    vim.api.nvim_set_current_win(current_win_id)
                  end)
                end)

                if current_win_id ~= preview_win_id then
                  popup.focus_open('hunk')
                end
              end)
            end)
          end, 'Preview hunk')
        end,
      }
    end,
  },
}
