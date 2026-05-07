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
      local group = vim.api.nvim_create_augroup('GitConflictKeymaps', { clear = true })

      -- Window-local 'winhighlight' redirect: only the listed groups are
      -- remapped in the conflict window, leaving every other highlight
      -- (NvimTreeWindowPicker, statusline, etc.) to resolve normally.
      -- We intentionally do NOT use nvim_win_set_hl_ns: with a window
      -- namespace set, winhighlight redirects in OTHER plugins (e.g.
      -- nvim-tree's picker remapping StatusLine -> NvimTreeWindowPicker)
      -- fail to fall back to global definitions and render with defaults.
      vim.api.nvim_set_hl(0, 'GitConflictDocumentHighlight', { bg = color.surface15 })
      vim.api.nvim_set_hl(0, 'GitConflictBlame', { fg = palette.subtext0 })
      local conflict_winhl = table.concat({
        'DocumentHighlight:GitConflictDocumentHighlight',
        'GitSignsCurrentLineBlame:GitConflictBlame',
      }, ',')

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

      local function apply_window_winhl(in_conflict)
        local win = vim.api.nvim_get_current_win()
        vim.wo[win].winhighlight = in_conflict and conflict_winhl or ''
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
            apply_window_winhl(utils.cursor_in_conflict())
          end, 100)

          local autocmd_id = vim.api.nvim_create_autocmd(
            { 'CursorMoved', 'CursorMovedI', 'BufWinEnter', 'BufLeave' },
            {
              group = group,
              buffer = bufnr,
              callback = function(args)
                local state = buf_state[bufnr]
                if not state then
                  return
                end

                -- 'winhighlight' is window-local and persists across buffer
                -- swaps in the same window (e.g. opening a file via nvim-tree
                -- / snacks picker), so clear it when the conflict buffer
                -- leaves the window. BufWinEnter / CursorMoved re-apply on
                -- return.
                if args.event == 'BufLeave' then
                  apply_window_winhl(false)
                  return
                end

                -- Always re-apply: BufWinEnter on a new split starts with
                -- empty winhighlight, so the cached state.in_conflict guard
                -- would skip the apply.
                local in_conflict = utils.cursor_in_conflict()
                state.in_conflict = in_conflict
                apply_window_winhl(in_conflict)
              end,
            }
          )

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

            for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
              vim.wo[win].winhighlight = ''
            end
          end
        end,
      })
    end,
  },
}
