return {
  Catppuccin(function(palette, _, extension)
    return {
      GitConflictCurrentLabel = { bg = extension.green1, fg = palette.text },
      GitConflictCurrent = { bg = extension.green0 },

      GitConflictAncestorLabel = { bg = palette.surface2, fg = palette.text },
      GitConflictAncestor = { bg = palette.surface1 },

      GitConflictIncomingLabel = { bg = extension.blue2, fg = palette.text },
      GitConflictIncoming = { bg = extension.blue0 },
    }
  end),

  {
    'hareki/git-conflict.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = function()
      local utils = require('plugins.features.git.git-conflict.utils')
      return {
        default_mappings = false,
        default_commands = false,
        cond = function()
          return not utils.in_diffview_tab()
        end,
      }
    end,
    config = function(_, opts)
      local plugin = require('git-conflict')
      plugin.setup(opts)

      local ui = require('utils.ui')
      local color = require('config.palette_ext')
      local utils = require('plugins.features.git.git-conflict.utils')
      local package = require('utils.package')
      local palette = ui.get_palette()
      local saved_hls = ui.save_hls({ 'DocumentHighlight', 'GitSignsCurrentLineBlame' })
      local highlight = ui.highlight
      local group = vim.api.nvim_create_augroup('GitConflictKeymaps', { clear = true })

      local keymaps = {
        { lhs = '<leader>co', rhs = '<Plug>(git-conflict-ours)', desc = 'Choose Ours' },
        { lhs = '<leader>ct', rhs = '<Plug>(git-conflict-theirs)', desc = 'Choose Theirs' },
        { lhs = '<leader>cb', rhs = '<Plug>(git-conflict-both)', desc = 'Choose Both' },
        { lhs = '<leader>cn', rhs = '<Plug>(git-conflict-none)', desc = 'Choose None' },
        { lhs = '[x', rhs = '<Plug>(git-conflict-prev-conflict)', desc = 'Previous Conflict' },
        { lhs = ']x', rhs = '<Plug>(git-conflict-next-conflict)', desc = 'Next Conflict' },
      }

      ---@type table<integer, { autocmd_id: integer, last_state: { in_conflict: boolean, should_increase_contrast: boolean }, in_diffview: boolean }>
      local buf_state = {}

      local function cleanup_buf(bufnr)
        local state = buf_state[bufnr]
        if not state then
          return
        end
        pcall(vim.api.nvim_del_autocmd, state.autocmd_id)
        buf_state[bufnr] = nil
      end

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

          vim.b[event.buf].git_conflict = true

          if buf_state[event.buf] then
            return
          end

          if package.is_loaded('nvim-colorizer.lua') then
            local colorizer = require('colorizer')
            colorizer.detach_from_buffer(event.buf)
          end
          vim.diagnostic.enable(false, { bufnr = event.buf })

          local in_diffview = utils.in_diffview_tab()
          local autocmd_id = vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            group = group,
            buffer = event.buf,
            callback = function()
              local state = buf_state[event.buf]
              if not state then
                return
              end

              local in_conflict, region = utils.cursor_in_conflict()

              local should_increase_contrast = in_conflict
                and (
                  state.in_diffview and region ~= 'current' and region ~= 'incoming'
                  or not state.in_diffview and region ~= 'separator'
                )

              -- Only update highlight if state changed
              if state.last_state.in_conflict ~= in_conflict then
                state.last_state.in_conflict = in_conflict

                if in_conflict then
                  ui.highlight('DocumentHighlight', { bg = color.surface15 })
                else
                  ui.highlight('DocumentHighlight', saved_hls.DocumentHighlight)
                end
              end

              if state.last_state.should_increase_contrast ~= should_increase_contrast then
                state.last_state.should_increase_contrast = should_increase_contrast

                if should_increase_contrast then
                  highlight('GitSignsCurrentLineBlame', { fg = palette.subtext0 })
                else
                  highlight('GitSignsCurrentLineBlame', saved_hls.GitSignsCurrentLineBlame)
                end
              end
            end,
          })

          buf_state[event.buf] = {
            autocmd_id = autocmd_id,
            last_state = { in_conflict = false, should_increase_contrast = false },
            in_diffview = in_diffview,
          }
        end,
      })

      -- Clean up state when buffers are deleted to prevent memory leak
      vim.api.nvim_create_autocmd('BufDelete', {
        group = group,
        callback = function(event)
          cleanup_buf(event.buf)
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

          if event.buf then
            cleanup_buf(event.buf)
          end

          if event.buf and vim.api.nvim_buf_is_valid(event.buf) then
            vim.b[event.buf].git_conflict = nil
            if package.is_loaded('nvim-colorizer.lua') then
              local colorizer = require('colorizer')
              colorizer.attach_to_buffer(event.buf)
            end
            vim.diagnostic.enable(true, { bufnr = event.buf })
          end

          ui.highlights(saved_hls)
        end,
      })
    end,
  },
}
