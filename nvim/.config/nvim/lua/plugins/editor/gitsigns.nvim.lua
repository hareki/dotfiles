return {
  require('utils.ui').catppuccin(function(_, sub_palette)
    return {
      GitSignsStagedAdd = { fg = sub_palette.green },
      GitSignsStagedUntracked = { link = 'GitSignsStagedAdd' },
      GitSignsStagedChange = { fg = sub_palette.yellow },
      GitSignsStagedChangedelete = { link = 'GitSignsStagedChange' },
      GitSignsStagedDelete = { fg = sub_palette.red },
      GitSignsStagedTopDelete = { link = 'GitSignsStagedDelete' },
    }
  end),
  {
    'hareki/gitsigns.nvim',
    event = 'VeryLazy',
    opts = function()
      return {
        diff_opts = {
          -- Use native git diff instead of Neovim's built in xdiff to better match VS Code's diff behavior
          internal = false,

          ignore_whitespace = false,
          ignore_whitespace_change = false,
          ignore_whitespace_change_at_eol = false,
          ignore_blank_lines = false,
        },
        numhl = false,
        signcolumn = true,
        signs = {
          add = { text = '┃' },
          change = { text = '┃' },
          delete = { text = '' },
          topdelete = { text = '' },
          changedelete = { text = '┃' },
          untracked = { text = '┃' },
        },
        signs_staged = {
          add = { text = '┃' },
          change = { text = '┃' },
          delete = { text = '' },
          topdelete = { text = '' },
          changedelete = { text = '┃' },
        },
        preview_config = {
          border = 'rounded',
        },
        get_popup_max_height = function()
          return math.floor(vim.o.lines * require('configs.size').inline_popup.max_height)
        end,
        current_line_blame = true,
        current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
        current_line_blame_opts = {
          delay = 300,
          virt_text = true,
          virt_text_priority = 999,
        },
        on_attach = function(buffer)
          local gs = package.loaded.gitsigns

          local function current_map(mode, l, r, desc)
            vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
          end
          local function current_unmap(mode, l)
            pcall(function()
              vim.keymap.del(mode, l, { buffer = buffer })
            end)
          end

          local function setup_popup_navigation(popup_type)
            return function()
              local popup = require('gitsigns.popup')
              local popup_win_id = popup.is_open(popup_type)

              if not popup_win_id then
                return
              end

              local popup_buf_id = vim.api.nvim_win_get_buf(popup_win_id)

              local function popup_map(mode, l, r, desc)
                vim.keymap.set(mode, l, r, { buffer = popup_buf_id, desc = desc })
              end

              local function close_popup()
                if popup_win_id and vim.api.nvim_win_is_valid(popup_win_id) then
                  vim.api.nvim_win_close(popup_win_id, true)
                end
              end

              vim.api.nvim_create_autocmd('WinClosed', {
                pattern = tostring(popup_win_id),
                once = true,
                callback = function()
                  current_unmap('n', '<Esc>')
                  current_unmap('n', '<Tab>')
                end,
              })

              current_map('n', '<Esc>', function()
                close_popup()
              end, 'Close Popup')

              current_map('n', '<Tab>', function()
                local current_win_id = vim.api.nvim_get_current_win()

                if not popup_win_id or not vim.api.nvim_win_is_valid(popup_win_id) then
                  return
                end

                popup_map('n', 'q', function()
                  close_popup()
                end, 'Close Popup')

                popup_map('n', '<Esc>', function()
                  close_popup()
                end, 'Close Popup')

                popup_map('n', '<Tab>', function()
                  popup.ignore_cursor_moved = true
                  require('utils.common').focus_win(current_win_id)
                end, 'Focus Original Window')

                if current_win_id ~= popup_win_id then
                  popup.focus_open(popup_type)
                end
              end, 'Focus Popup Window')
            end
          end

          current_map('n', ']h', function()
            if vim.wo.diff then
              vim.cmd.normal({ ']c', bang = true })
            else
              gs.nav_hunk('next')
            end
          end, 'Next Hunk')

          current_map('n', '[h', function()
            if vim.wo.diff then
              vim.cmd.normal({ '[c', bang = true })
            else
              gs.nav_hunk('prev')
            end
          end, 'Previous Hunk')

          current_map('n', ']H', function()
            gs.nav_hunk('last')
          end, 'Last Hunk')

          current_map('n', '[H', function()
            gs.nav_hunk('first')
          end, 'First Hunk')

          current_map({ 'n', 'v' }, '<leader>hs', ':Gitsigns stage_hunk<CR>', 'Stage Hunk')
          current_map({ 'n', 'v' }, '<leader>hr', ':Gitsigns reset_hunk<CR>', 'Reset Hunk')
          current_map('n', '<leader>hS', gs.stage_buffer, 'Stage Buffer')
          current_map('n', '<leader>hu', gs.undo_stage_hunk, 'Undo Stage Hunk')
          current_map('n', '<leader>hR', gs.reset_buffer, 'Reset Buffer')

          current_map('n', '<leader>hB', function()
            gs.blame()
          end, 'Blame Buffer')

          current_map('n', '<leader>hd', gs.diffthis, 'Diff This')
          current_map('n', '<leader>hD', function()
            gs.diffthis('~')
          end, 'Diff This ~')
          current_map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', 'GitSigns Select Hunk')

          current_map('n', '<leader>hb', function()
            require('gitsigns').blame_line({ full = true }, setup_popup_navigation('blame'))
          end, 'Blame Line')

          current_map('n', '<leader>hp', function()
            require('gitsigns').preview_hunk()
            vim.schedule(setup_popup_navigation('hunk'))
          end, 'Preview Hunk')
        end,
      }
    end,
  },
}
