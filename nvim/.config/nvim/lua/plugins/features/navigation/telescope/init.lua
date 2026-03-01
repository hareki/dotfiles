return {
  Catppuccin(function(palette)
    return {
      TelescopeBufferMarker = { fg = palette.peach },
      TelescopePromptPrefix = { fg = palette.blue },
      TelescopeMultiIcon = { fg = palette.blue },
      TelescopeSelectionCaret = { fg = palette.blue },
      TelescopeSelection = {
        fg = 'NONE', -- Disable fg override
        style = {}, -- Disable default bold
      },
    }
  end),
  {
    'nvim-telescope/telescope.nvim',
    version = false, -- telescope did only one release, so use HEAD for now
    cmd = 'Telescope',
    dependencies = {
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        -- https://github.com/nvim-telescope/telescope-fzf-native.nvim/issues/120#issuecomment-2200296884
        build = 'make',
      },
    },
    opts = function()
      local state = require('telescope.state')
      local actions = require('telescope.actions')
      local action_set = require('telescope.actions.set')
      local layout_strategies = require('telescope.pickers.layout_strategies')
      local builtin = require('telescope.builtin')

      local function find_command()
        if 1 == vim.fn.executable('rg') then
          return { 'rg', '--files', '--color', 'never', '-g', '!.git' }
        elseif 1 == vim.fn.executable('fd') then
          return { 'fd', '--type', 'f', '--color', 'never', '-E', '.git' }
        elseif 1 == vim.fn.executable('fdfind') then
          return { 'fdfind', '--type', 'f', '--color', 'never', '-E', '.git' }
        elseif 1 == vim.fn.executable('find') and vim.fn.has('win32') == 0 then
          return { 'find', '.', '-type', 'f' }
        elseif 1 == vim.fn.executable('where') then
          return { 'where', '/r', '.', '*' }
        end
      end

      -- Unify the preview title for all pickers
      local default_picker_configs = {}
      local picker_config = require('config.picker')
      for picker_name, _ in pairs(builtin) do
        default_picker_configs[picker_name] = {
          preview_title = picker_config.telescope_preview_title,
        }
      end

      local default_vertical = layout_strategies.vertical

      -- Heavily modify the "vertical" strategy, the point is to merge prompt and results windows
      -- In general, this layout mimics the "dropdown" theme, but take the "previewer" panel into account of the height layout
      -- https://www.reddit.com/r/neovim/comments/10asvod/telescopenvim_how_to_remove_windows_titles_and/
      layout_strategies.vertical = function(self, max_columns, max_lines, layout_config)
        local size = self.layout_config.vertical.size or 'lg'
        -- 0. Use the default vertical layout as the base
        local layout = default_vertical(self, max_columns, max_lines, layout_config)
        -- 1. Collapse the blank row between *prompt* and *results*
        layout.results.line = layout.results.line - 1
        layout.results.height = layout.results.height + 1
        local ui_utils = require('utils.ui')

        -- 2. Seems like telescope.nvim exclude the statusline when centering the layout,
        -- Which is different from our logic in `size_utils.get_float_config('lg')`
        -- So we need to adjust/shift the position if needed
        local target_row = ui_utils.popup_config(size, true).row
        -- The top most component is the prompt window, so we use it as the anchor to adjust the position
        local top_line = layout.prompt.line

        -- Minus 1 for the top border and the other one
        -- Minus 1 for the difference of how nvim_open_win and telescope handle the position:
        -- nvim_open_win puts the window BELOW the specified row, while telescope doesn't
        top_line = top_line - 2

        local shift = target_row - top_line
        if shift ~= 0 then
          for _, win in ipairs({ layout.prompt, layout.results, layout.preview }) do
            if win then
              win.line = win.line + shift
            end
          end
        end

        return layout
      end

      -- https://github.com/nvim-telescope/telescope.nvim/issues/2778#issuecomment-2202572413
      local function toggle_focus_preview(prompt_bufnr)
        local actions_state = require('telescope.actions.state')
        local telescope_state = require('telescope.state')
        local cursorline = require('services.cursorline')

        local picker = actions_state.get_current_picker(prompt_bufnr)
        local prompt_win = picker.prompt_win
        local status = telescope_state.get_status(prompt_bufnr)
        local previewer_winid = status and status.preview_win or nil
        local previewer_bufnr = previewer_winid and vim.api.nvim_win_get_buf(previewer_winid) or nil

        if not (previewer_winid and vim.api.nvim_win_is_valid(previewer_winid)) then
          local common = require('utils.common')
          common.focus_win(prompt_win)
          return
        end

        local set_cursorline = cursorline.set_cursorline
        local default_modifiable = previewer_bufnr and vim.bo[previewer_bufnr].modifiable or false

        vim.bo[previewer_bufnr].modifiable = false

        local function restore_buf_state()
          vim.bo[previewer_bufnr].modifiable = default_modifiable
        end

        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, {
            buffer = previewer_bufnr,
            desc = desc,
          })
        end

        map('n', '<Tab>', function()
          restore_buf_state()
          set_cursorline(false, previewer_winid)
          local common = require('utils.common')
          common.focus_win(prompt_win)
        end, 'Focus Prompt Window')

        map('n', 'q', function()
          restore_buf_state()
          actions.close(prompt_bufnr)
        end, 'Close Telescope')

        map('n', '<CR>', function()
          restore_buf_state()
          actions.select_default(prompt_bufnr)
        end)

        local common = require('utils.common')
        if common.focus_win(previewer_winid) then
          vim.schedule(function()
            set_cursorline(true, previewer_winid)
          end)
        end
      end

      vim.api.nvim_create_autocmd('User', {
        pattern = 'TelescopePreviewerLoaded',
        group = vim.api.nvim_create_augroup('telescope_previewer_loaded', { clear = true }),

        -- Make it look more like the actual window we use to edit files
        callback = function(ev)
          local buftype = vim.bo[ev.buf].buftype
          if buftype == 'terminal' then
            return
          end

          vim.opt_local.number = true
          vim.opt_local.relativenumber = true
          vim.opt_local.numberwidth = 1
          vim.opt_local.cursorline = true
          vim.opt_local.cursorlineopt = 'number'
        end,
      })

      --- @param direction 'up' | 'down'
      local function scroll_results(direction)
        --- @param prompt_bufnr integer
        return function(prompt_bufnr)
          local status = state.get_status(prompt_bufnr)
          local winid = status.layout.results.winid
          local default_speed = vim.api.nvim_win_get_height(winid) / 2
          local speed = status.picker.layout_config.scroll_speed or default_speed

          action_set.shift_selection(
            prompt_bufnr,
            math.floor(speed) * (direction == 'up' and -1 or 1)
          )

          vim.api.nvim_win_call(winid, function()
            vim.cmd.normal({ args = { 'zz' }, bang = true })
          end)
        end
      end

      local scroll_results_up = scroll_results('up')
      local scroll_results_down = scroll_results('down')
      local function telescope_to_trouble()
        local trouble_sources = require('trouble.sources.telescope')
        trouble_sources.open()
      end

      local function trouble_open(source)
        return function(bufnr)
          actions.close(bufnr)
          local trouble = require('trouble')
          trouble.open(source)
        end
      end

      local ui = require('utils.ui')
      local layout_config = ui.telescope_layout
      local telescope_config = require('telescope.config')
      local default_get_status_text = telescope_config.values.get_status_text

      return {
        extensions = {
          undo = {
            use_delta = true,
            saved_only = true,
          },
        },
        defaults = {
          prompt_prefix = picker_config.prompt_prefix,
          -- selection_caret = ' ',
          selection_caret = ' ',
          entry_prefix = ' ', -- keep list text aligned
          multi_icon = vim.trim(Icons.explorer.selected) .. ' ',
          get_status_text = function(self, opts)
            -- Prevent flashing the loading asterisk indicator
            opts = opts or {}
            opts.completed = true

            local text = default_get_status_text(self, opts)
            if text == '' then
              return ''
            end

            -- Remove spaces around /
            return text:gsub('%s*/%s*', '/') .. ' '
          end,
          -- Merge prompt and results windows
          results_title = false,
          -- https://github.com/nvim-telescope/telescope.nvim/blob/5972437de807c3bc101565175da66a1aa4f8707a/lua/telescope/themes.lua#L50
          borderchars = {
            prompt = { '─', '│', ' ', '│', '╭', '╮', '│', '│' },
            -- Connected edges:
            -- results = { '─', '│', '─', '│', '├', '┤', '╯', '╰' },
            -- Disconnected edges, similar to snacks picker
            results = { '─', '│', '─', '│', '│', '│', '╯', '╰' },
            preview = { '─', '│', '─', '│', '╭', '╮', '╯', '╰' },
          },

          -- Make results appear from top to bottom
          -- https://github.com/nvim-telescope/telescope.nvim/issues/1933
          sorting_strategy = 'ascending',

          layout_strategy = 'vertical',
          layout_config = {
            vertical = vim.tbl_extend('error', {
              mirror = true,
              preview_height = 0.45,
              preview_cutoff = 1, -- Preview should always show (unless previewer = false)
              prompt_position = 'top',
            }, layout_config('lg')),
          },

          -- Open files in the first window that is an actual file.
          -- Use the current window if no other window is available.
          get_selection_window = function()
            local wins = vim.api.nvim_list_wins()
            table.insert(wins, 1, vim.api.nvim_get_current_win())
            for _, win in ipairs(wins) do
              local buf = vim.api.nvim_win_get_buf(win)
              if vim.bo[buf].buftype == '' then
                return win
              end
            end
            return 0
          end,

          mappings = {
            n = {
              ['q'] = actions.close,
              ['<Tab>'] = toggle_focus_preview,
              ['<C-n>'] = actions.toggle_selection + actions.move_selection_worse,
              ['<C-p>'] = actions.toggle_selection + actions.move_selection_better,
              ['<PageUp>'] = scroll_results_up,
              ['<PageDown>'] = scroll_results_down,
              ['<c-t>'] = telescope_to_trouble,
            },
            i = {
              ['<Tab>'] = toggle_focus_preview,
              ['<C-n>'] = actions.toggle_selection + actions.move_selection_worse,
              ['<C-p>'] = actions.toggle_selection + actions.move_selection_better,
              ['<PageUp>'] = scroll_results_up,
              ['<PageDown>'] = scroll_results_down,
              ['<c-t>'] = telescope_to_trouble,
            },
          },
        },

        pickers = vim.tbl_deep_extend('force', default_picker_configs, {
          lsp_definitions = {
            mappings = {
              n = {
                ['<c-t>'] = trouble_open('lsp_definitions'),
              },
              i = {
                ['<c-t>'] = trouble_open('lsp_definitions'),
              },
            },
          },
          lsp_references = {
            mappings = {
              n = {
                ['<c-t>'] = trouble_open('lsp_references'),
              },
              i = {
                ['<c-t>'] = trouble_open('lsp_references'),
              },
            },
          },

          find_files = {
            find_command = find_command,
            hidden = true,
            -- layout_config = { scroll_speed = 3 }  -- Configure scroll speed per picker
          },

          diagnostics = {
            mappings = {
              n = {
                ['<c-t>'] = trouble_open('diagnostics'),
              },
              i = {
                ['<c-t>'] = trouble_open('diagnostics'),
              },
            },
          },
          -- highlights = {
          --     previewer = false,
          -- },
          buffers = {
            select_current = true,
            --https://github.com/nvim-telescope/telescope.nvim/issues/1145#issuecomment-903161099
            mappings = {
              n = {
                ['x'] = actions.delete_buffer,
              },
            },
          },
        }),
      }
    end,
    config = function(_, opts)
      local telescope = require('telescope')

      telescope.setup(opts)
      for _, ext in ipairs({ 'fzf' }) do
        telescope.load_extension(ext)
      end

      vim.api.nvim_set_hl(0, 'TelescopeMultiSelection', {})
    end,
  },
}
