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
      local utils = require('plugins.features.git.git-conflict-nvim.utils')
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
      local utils = require('plugins.features.git.git-conflict-nvim.utils')
      local package = require('utils.package')
      local palette = ui.get_palette()
      local group = vim.api.nvim_create_augroup('git.git_conflict.keymaps', { clear = true })

      -- Debounce window for the cursor-in-conflict scan. The scan walks up to
      -- 1000 lines, which can lag when cursor movement is held down.
      local CURSOR_DEBOUNCE_MS = 100

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

      ---@type table<integer, { autocmd_id: integer, in_conflict: boolean, timer: uv.uv_timer_t? }>
      local buf_state = {}

      local function cleanup_buf(bufnr)
        local state = buf_state[bufnr]
        if not state then
          return
        end
        pcall(vim.api.nvim_del_autocmd, state.autocmd_id)

        if state.timer then
          state.timer:stop()
          if not state.timer:is_closing() then
            state.timer:close()
          end
        end
        buf_state[bufnr] = nil
      end

      ---@param win integer
      ---@param in_conflict boolean
      local function apply_window_winhl(win, in_conflict)
        if not vim.api.nvim_win_is_valid(win) then
          return
        end
        vim.wo[win].winhighlight = in_conflict and conflict_winhl or ''
      end

      local function schedule_cursor_check(bufnr)
        local state = buf_state[bufnr]
        if not state then
          return
        end

        if not state.timer then
          state.timer = vim.uv.new_timer()
        end

        state.timer:stop()
        state.timer:start(
          CURSOR_DEBOUNCE_MS,
          0,
          vim.schedule_wrap(function()
            if not vim.api.nvim_buf_is_valid(bufnr) then
              return
            end
            -- Skip if user moved to a different buffer in the meantime; BufLeave
            -- already cleared winhl, and BufWinEnter will re-apply on return.
            if vim.api.nvim_get_current_buf() ~= bufnr then
              return
            end
            local current = buf_state[bufnr]
            if not current then
              return
            end
            local in_conflict = utils.cursor_in_conflict()
            current.in_conflict = in_conflict
            apply_window_winhl(vim.api.nvim_get_current_win(), in_conflict)
          end)
        )
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
          local target_win = vim.api.nvim_get_current_win()
          vim.defer_fn(function()
            if not vim.api.nvim_win_is_valid(target_win) then
              return
            end
            if vim.api.nvim_win_get_buf(target_win) ~= bufnr then
              return
            end
            local in_conflict = vim.api.nvim_win_call(target_win, function()
              return utils.cursor_in_conflict()
            end)
            apply_window_winhl(target_win, in_conflict)
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
                  if state.timer then
                    state.timer:stop()
                  end
                  apply_window_winhl(vim.api.nvim_get_current_win(), false)
                  return
                end

                -- Cursor movement is debounced because cursor_in_conflict
                -- scans up to 1000 lines and can stutter when held down.
                -- BufWinEnter stays synchronous to avoid a visible gap when
                -- entering a new split (which starts with empty winhighlight).
                if args.event == 'CursorMoved' or args.event == 'CursorMovedI' then
                  schedule_cursor_check(bufnr)
                  return
                end

                local in_conflict = utils.cursor_in_conflict()
                state.in_conflict = in_conflict
                apply_window_winhl(vim.api.nvim_get_current_win(), in_conflict)
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

          if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
            for _, map in ipairs(keymaps) do
              pcall(vim.keymap.del, 'n', map.lhs, { buffer = bufnr })
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
