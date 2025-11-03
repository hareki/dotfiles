return {
  require('utils.ui').catppuccin(function(palette)
    return {
      GitConflictCurrentLabel = { bg = '#57735b', fg = palette.text },
      GitConflictCurrent = { bg = '#394841' },

      GitConflictAncestorLabel = { bg = '#585b70', fg = palette.text },
      GitConflictAncestor = { bg = '#44465a' },

      GitConflictIncomingLabel = { bg = '#495d83', fg = palette.text },
      GitConflictIncoming = { bg = '#323c56' },
    }
  end),
  {
    'akinsho/git-conflict.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = function()
      local keymaps = {
        { lhs = '<leader>co', rhs = '<Plug>(git-conflict-ours)', desc = 'Choose OURS' },
        { lhs = '<leader>ct', rhs = '<Plug>(git-conflict-theirs)', desc = 'Choose THEIRS' },
        { lhs = '<leader>cb', rhs = '<Plug>(git-conflict-both)', desc = 'Choose BOTH' },
        { lhs = '<leader>cn', rhs = '<Plug>(git-conflict-none)', desc = 'Choose NONE' },
        { lhs = '[x', rhs = '<Plug>(git-conflict-prev-conflict)', desc = 'Previous Conflict' },
        { lhs = ']x', rhs = '<Plug>(git-conflict-next-conflict)', desc = 'Next Conflict' },
      }

      local group = vim.api.nvim_create_augroup('GitConflictKeymaps', { clear = true })

      vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'GitConflictDetected',
        callback = function(event)
          for _, map in ipairs(keymaps) do
            vim.keymap.set('n', map.lhs, map.rhs, {
              silent = true,
              desc = 'Git Conflict: ' .. map.desc,
              buffer = event.buf,
            })
          end
        end,
      })

      vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'GitConflictResolved',
        callback = function(event)
          for _, map in ipairs(keymaps) do
            if event.buf and vim.api.nvim_buf_is_valid(event.buf) then
              local ok = pcall(vim.keymap.del, 'n', map.lhs, { buffer = event.buf })
              if not ok then
                pcall(vim.keymap.del, 'n', map.lhs)
              end
            else
              pcall(vim.keymap.del, 'n', map.lhs)
            end
          end
        end,
      })

      local function in_diffview_tab()
        local tab_utils = require('utils.tab')
        local tab_name = vim.t.tab_name or tab_utils.get_tab_name()
        if type(tab_name) ~= 'string' then
          return false
        end

        return tab_name:find('^diffview%-tab') ~= nil
      end

      return {
        default_mappings = false,
        default_commands = false,
        cond = function()
          return not in_diffview_tab()
        end,
      }
    end,
  },
}
