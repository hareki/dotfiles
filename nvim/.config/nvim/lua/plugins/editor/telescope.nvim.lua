return {
  'nvim-telescope/telescope.nvim',
  cmd = 'Telescope',
  version = false, -- telescope did only one release, so use HEAD for now
  dependencies = {
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release',
    },
  },
  keys = {
    {
      '<leader><space>',
      function()
        require('telescope.builtin').find_files()
      end,
      desc = 'Files',
    },
    {
      '<leader>fd',
      function()
        require('telescope.builtin').diagnostics({
          bufnr = 0,
        })
      end,
      desc = 'Diagnostics',
    },
    {
      '<leader>fb',
      function()
        require('telescope.builtin').buffers({
          sort_mru = true,
          sort_lastused = true,
          initial_mode = 'normal',
        })
      end,
      desc = 'Buffers',
    },
    {
      '<leader>f/',
      function()
        require('telescope.builtin').live_grep()
      end,
      desc = 'Live Grep',
    },
    {
      '<leader>fh',
      function()
        require('telescope.builtin').highlights()
      end,
      desc = 'Highlight Groups',
    },

    {
      '<leader>fy',
      function()
        local telescope = require('telescope')
        telescope.load_extension('yank_history')

        telescope.extensions.yank_history.yank_history({
          preview_title = require('configs.common').PREVIEW_TITLE,
        })
      end,
      desc = 'Highlight Groups',
    },

    {
      '<leader>fgb',
      function()
        require('telescope.builtin').git_branches()
      end,
      desc = 'Git Branches',
    },

    {
      '<leader>fr',
      function()
        require('telescope.builtin').resume()
      end,
      desc = 'Last Picker',
    },
  },
  init = function()
    local _select = vim.ui.select

    vim.ui.select = function(items, opts, on_choice)
      -- Not necessary, but just to be safe
      -- If for whatever reason the ui-select extension is not loaded, that will cause infinite recursion
      vim.ui.select = _select
      require('lazy').load({ plugins = { 'telescope.nvim' } })

      -- vim.ui.select should already by overwritten telescope-ui-select at this point
      return vim.ui.select(items, opts, on_choice)
    end

    -- Open telescope find_files when Neovim starts on a directory
    vim.api.nvim_create_autocmd('VimEnter', {
      once = true,
      callback = function(data)
        -- Only act if the argument is a directory
        if vim.fn.isdirectory(data.file) == 1 then
          vim.cmd.cd(data.file) -- set cwd to that dir
          require('telescope.builtin').find_files()
        end
      end,
    })
  end,
  opts = function()
    local state = require('telescope.state')
    local actions = require('telescope.actions')
    local action_set = require('telescope.actions.set')
    local action_state = require('telescope.actions.state')
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
    for picker_name, _ in pairs(builtin) do
      default_picker_configs[picker_name] = {
        preview_title = require('configs.common').PREVIEW_TITLE,
      }
    end

    local orig_vertical = layout_strategies.vertical

    -- Heavily modify the "vertical" strategy, the point is to merge prompt and results windows
    -- In general, this layout mimics the "dropdown" theme, but take the "previewer" panel into account of the height layout
    -- https://www.reddit.com/r/neovim/comments/10asvod/telescopenvim_how_to_remove_windows_titles_and/
    layout_strategies.vertical = function(self, max_columns, max_lines, layout_config)
      local size = self.layout_config.vertical.size or 'lg'
      -- 0. Use the default vertical layout as the base
      local layout = orig_vertical(self, max_columns, max_lines, layout_config)
      -- 1. Collapse the blank row between *prompt* and *results*
      layout.results.line = layout.results.line - 1
      layout.results.height = layout.results.height + 1
      local size_utils = require('utils.size')

      -- 2. Seems like telescope.nvim exclude the statusline when centering the layout,
      -- Which is different from our logic in `size_utils.get_float_config('lg')`
      -- So we need to adjust/shift the position if needed
      local target_row = size_utils.popup_config(size, true).row
      -- The top most component is the prompt window, so we use it as the anchor to adjust the position
      local top_line = layout.prompt.line

      -- Minus 1 for the top border and the other one
      -- Minus 1 for the difference of how nvim_open_win and telescope handle the position
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
    local toggle_focus_preview = function(prompt_bufnr)
      local picker = action_state.get_current_picker(prompt_bufnr)
      local prompt_win = picker.prompt_win
      local previewer = picker.previewer
      local previewer_win_id = previewer.state.winid
      local previewer_bufnr = previewer.state.bufnr

      vim.bo[previewer_bufnr].modifiable = false

      local map = function(mode, lhs, rhs)
        vim.keymap.set(mode, lhs, rhs, {
          buffer = previewer_bufnr,
        })
      end

      map('n', '<Tab>', function()
        require('utils.autocmd').noautocmd(function()
          vim.api.nvim_set_current_win(prompt_win)
        end)
      end)

      map('n', 'q', function()
        actions.close(prompt_bufnr)
      end)

      map('n', '<CR>', function()
        actions.select_default(prompt_bufnr)
      end)

      require('utils.autocmd').noautocmd(function()
        vim.api.nvim_set_current_win(previewer_win_id)
      end)
    end

    vim.api.nvim_create_autocmd('User', {
      pattern = 'TelescopePreviewerLoaded',
      callback = function()
        vim.opt_local.number = true
        vim.opt_local.relativenumber = true
        vim.opt_local.numberwidth = 1
        vim.opt_local.cursorline = true
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
          vim.cmd('normal! zz')
        end)
      end
    end

    local scroll_results_up = scroll_results('up')
    local scroll_results_down = scroll_results('down')
    local telescope_to_trouble = function()
      require('trouble.sources.telescope').open()
    end

    local trouble_open = function(source)
      return function(bufnr)
        actions.close(bufnr)
        require('trouble').open(source)
      end
    end

    local layout_config = require('utils.ui').telescope_layout_config

    return {
      extensions = {
        ['ui-select'] = {
          layout_config = {
            vertical = layout_config('sm'),
          },
        },
        undo = {
          use_delta = false, -- Can't switch to preview buffer when delta is enabled
          saved_only = true,
        },
      },
      defaults = {
        prompt_prefix = '   ',
        selection_caret = ' ',
        -- Merge prompt and results windows
        results_title = false,
        -- https://github.com/nvim-telescope/telescope.nvim/blob/5972437de807c3bc101565175da66a1aa4f8707a/lua/telescope/themes.lua#L50
        borderchars = {
          prompt = { '─', '│', ' ', '│', '╭', '╮', '│', '│' },
          results = { '─', '│', '─', '│', '├', '┤', '╯', '╰' },
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
            ['<S-Tab>'] = actions.toggle_selection + actions.move_selection_worse,
            ['<PageUp>'] = scroll_results_up,
            ['<PageDown>'] = scroll_results_down,
            ['<c-t>'] = telescope_to_trouble,
          },
          i = {
            ['<Tab>'] = toggle_focus_preview,
            ['<S-Tab>'] = actions.toggle_selection + actions.move_selection_worse,
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
          -- layout_config = { scroll_speed = 3 }  -- Config scroll speed per picker here
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
    require('telescope').setup(opts)

    for _, ext in ipairs({ 'fzf' }) do
      require('telescope').load_extension(ext)
    end
  end,
}
