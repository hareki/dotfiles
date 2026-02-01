return {
  Catppuccin(function(palette)
    local color = require('configs.color')
    return {
      GitConflictCurrentLabel = { bg = color.git_conflict_current_label_bg, fg = palette.text },
      GitConflictCurrent = { bg = color.git_conflict_current_bg },

      GitConflictAncestorLabel = { bg = color.git_conflict_ancestor_label_bg, fg = palette.text },
      GitConflictAncestor = { bg = color.git_conflict_ancestor_bg },

      GitConflictIncomingLabel = { bg = color.git_conflict_incoming_label_bg, fg = palette.text },
      GitConflictIncoming = { bg = color.git_conflict_incoming_bg },
    }
  end),
  {
    'hareki/git-conflict.nvim',
    event = 'VeryLazy',
    opts = function()
      local keymaps = {
        { lhs = '<leader>co', rhs = '<Plug>(git-conflict-ours)', desc = 'Choose Ours' },
        { lhs = '<leader>ct', rhs = '<Plug>(git-conflict-theirs)', desc = 'Choose Theirs' },
        { lhs = '<leader>cb', rhs = '<Plug>(git-conflict-both)', desc = 'Choose Both' },
        { lhs = '<leader>cn', rhs = '<Plug>(git-conflict-none)', desc = 'Choose None' },
        { lhs = '[x', rhs = '<Plug>(git-conflict-prev-conflict)', desc = 'Previous Conflict' },
        { lhs = ']x', rhs = '<Plug>(git-conflict-next-conflict)', desc = 'Next Conflict' },
      }

      local ui = require('utils.ui')
      local utils = require('plugins.editor.git-conflict.utils')
      local palette = ui.get_palette()
      local highlight = ui.highlight

      local group = vim.api.nvim_create_augroup('GitConflictKeymaps', { clear = true })

      -- Track cursor movement in conflict buffers
      local cursor_autocmd_ids = {}
      local last_conflict_state = {}
      local is_diffview_tab = nil

      vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'GitConflictDetected',
        callback = function(event)
          for _, map in ipairs(keymaps) do
            vim.keymap.set('n', map.lhs, map.rhs, {
              desc = 'Git Conflict: ' .. map.desc,
              buffer = event.buf,
            })
          end

          if not cursor_autocmd_ids[event.buf] then
            last_conflict_state[event.buf] = nil -- Reset state for this buffer

            cursor_autocmd_ids[event.buf] = vim.api.nvim_create_autocmd(
              { 'CursorMoved', 'CursorMovedI' },
              {
                group = group,
                buffer = event.buf,
                callback = function()
                  local in_conflict, region = utils.cursor_in_conflict()
                  local should_increase_contrast = in_conflict
                    and (
                      is_diffview_tab and region ~= 'current' and region ~= 'incoming'
                      or not is_diffview_tab and region ~= 'separator'
                    )

                  -- Only update highlight if state changed
                  if last_conflict_state[event.buf] ~= should_increase_contrast then
                    last_conflict_state[event.buf] = should_increase_contrast

                    if should_increase_contrast then
                      highlight('GitSignsCurrentLineBlame', { fg = palette.subtext0 })
                    else
                      highlight('GitSignsCurrentLineBlame', { fg = palette.surface1 })
                    end
                  end
                end,
              }
            )
          end
        end,
      })

      -- Clean up state tables when buffers are deleted to prevent memory leak
      vim.api.nvim_create_autocmd('BufDelete', {
        group = group,
        callback = function(event)
          if cursor_autocmd_ids[event.buf] then
            pcall(vim.api.nvim_del_autocmd, cursor_autocmd_ids[event.buf])
            cursor_autocmd_ids[event.buf] = nil
            last_conflict_state[event.buf] = nil
          end
        end,
      })

      vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'GitConflictResolved',
        callback = function(event)
          -- Clean up keymaps
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

          -- Clean up cursor tracking
          if event.buf and cursor_autocmd_ids[event.buf] then
            pcall(vim.api.nvim_del_autocmd, cursor_autocmd_ids[event.buf])
            cursor_autocmd_ids[event.buf] = nil
            last_conflict_state[event.buf] = nil
          end

          -- Reset GitSigns highlight to default
          highlight('GitSignsCurrentLineBlame', { fg = palette.surface1 })
        end,
      })

      return {
        default_mappings = false,
        default_commands = false,
        cond = function()
          is_diffview_tab = utils.in_diffview_tab()
          return not is_diffview_tab
        end,
      }
    end,
  },
}
