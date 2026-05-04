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
      local group = vim.api.nvim_create_augroup('GitConflictKeymaps', { clear = true })

      local keymaps = {
        { lhs = '<leader>co', rhs = '<Plug>(git-conflict-ours)', desc = 'Choose Ours' },
        { lhs = '<leader>ct', rhs = '<Plug>(git-conflict-theirs)', desc = 'Choose Theirs' },
        { lhs = '<leader>cb', rhs = '<Plug>(git-conflict-both)', desc = 'Choose Both' },
        { lhs = '<leader>cn', rhs = '<Plug>(git-conflict-none)', desc = 'Choose None' },
        { lhs = '[x', rhs = '<Plug>(git-conflict-prev-conflict)', desc = 'Previous Conflict' },
        { lhs = ']x', rhs = '<Plug>(git-conflict-next-conflict)', desc = 'Next Conflict' },
      }

      ---@type table<integer, { autocmd_id: integer, in_conflict: boolean }>
      local buf_state = {}

      local function cleanup_buf(bufnr)
        local state = buf_state[bufnr]
        if not state then
          return
        end
        pcall(vim.api.nvim_del_autocmd, state.autocmd_id)
        buf_state[bufnr] = nil
      end

      local function set_conflict_highlights(in_conflict)
        if in_conflict then
          ui.highlight('DocumentHighlight', { bg = color.surface15 })
          ui.highlight('GitSignsCurrentLineBlame', { fg = palette.subtext0 })
          return
        end

        ui.highlight('DocumentHighlight', saved_hls.DocumentHighlight)
        ui.highlight('GitSignsCurrentLineBlame', saved_hls.GitSignsCurrentLineBlame)
      end

      vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'GitConflictDetected',
        callback = function(event)
          local bufnr = event.data.buf

          for _, map in ipairs(keymaps) do
            vim.keymap.set('n', map.lhs, map.rhs, {
              desc = 'Git Conflict: ' .. map.desc,
              buffer = bufnr,
            })
          end

          vim.b[bufnr].git_conflict = true

          if buf_state[bufnr] then
            return
          end

          if package.is_loaded('nvim-colorizer.lua') then
            local colorizer = require('colorizer')
            colorizer.detach_from_buffer(bufnr)
          end
          vim.diagnostic.enable(false, { bufnr = bufnr })

          -- Wait a bit for the position to be stable and then initialize the highlights
          vim.defer_fn(function()
            local init_in_conflict = utils.cursor_in_conflict()
            set_conflict_highlights(init_in_conflict)
          end, 100)

          local autocmd_id = vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            group = group,
            buffer = bufnr,
            callback = function()
              local state = buf_state[bufnr]
              if not state then
                return
              end

              local in_conflict = utils.cursor_in_conflict()
              if state.in_conflict ~= in_conflict then
                state.in_conflict = in_conflict
                set_conflict_highlights(in_conflict)
              end
            end,
          })

          buf_state[bufnr] = {
            autocmd_id = autocmd_id,
            in_conflict = false,
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
          local bufnr = event.data.buf

          for _, map in ipairs(keymaps) do
            if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
              local ok = pcall(vim.keymap.del, 'n', map.lhs, { buffer = bufnr })
              if not ok then
                pcall(vim.keymap.del, 'n', map.lhs)
              end
            else
              pcall(vim.keymap.del, 'n', map.lhs)
            end
          end

          if bufnr then
            cleanup_buf(bufnr)
          end

          if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
            vim.b[bufnr].git_conflict = nil
            if package.is_loaded('nvim-colorizer.lua') then
              local colorizer = require('colorizer')
              colorizer.attach_to_buffer(bufnr)
            end
            vim.diagnostic.enable(true, { bufnr = bufnr })
          end

          ui.highlights(saved_hls)
        end,
      })
    end,
  },
}
