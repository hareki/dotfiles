local tree = require('plugins.editor.nvim-tree.utils')
local state = tree.state

return {
  require('utils.ui').catppuccin(function(palette)
    return {
      NvimTreeSignColumn = {
        link = 'NormalFloat',
      },
      NvimTreeNormal = {
        link = 'Normal',
      },
      NvimTreeCutHL = {
        bg = palette.maroon,
        fg = palette.base,
      },
      NvimTreeCopiedHL = {
        bg = palette.surface2,
        fg = palette.text,
      },
    }
  end),
  {
    'hareki/nvim-tree-preview.lua',
    opts = {
      on_close = function()
        tree.toggle_tree_height('expand')
      end,
      keymaps = {
        ['q'] = tree.close_all,
        ['<Tab>'] = tree.toggle_focus,
        ['<C-t>'] = function()
          tree.switch_position('side')
          tree.open({ switching = true })
        end,
        ['B'] = function()
          local api = require('nvim-tree.api')
          api.tree.focus()
          tree.toggle_preview()
        end,
        ['<CR>'] = function()
          require('nvim-tree.api').node.open.edit()
          if state.position == 'float' then
            tree.close_all()
          end
        end,
      },
      win_position = {
        col = function(_, size)
          if state.position == 'float' then
            return -1
          end

          return -size.width - 3
        end,

        row = function(tree_win, size)
          local tree_cfg = vim.api.nvim_win_get_config(tree_win)

          if state.position == 'float' then
            return tree_cfg.height + 1
          end
          return math.floor((vim.opt.lines:get() - size.height) / 2) - 1
        end,
      },

      calculate_win_size = function(tree_win)
        local tree_cfg = vim.api.nvim_win_get_config(tree_win)
        local size_configs = require('configs.size')

        local side_preview = size_configs.side_preview
        local size_utils = require('utils.ui')
        local size = size_utils.popup_config('lg')

        -- We need to fill the missing row if the total height is an odd number,
        -- meaing when we can't have equal height for both windows
        local height_offset = size.height % 2 == 0 and 0 or 1

        if state.position == 'float' then
          return {
            width = tree_cfg.width,
            height = tree_cfg.height + height_offset,
          }
        end

        local preview_cols, preview_rows = size_utils.computed_size(side_preview)

        return {
          width = preview_cols,
          height = preview_rows,
        }
      end,
    },
  },
  {
    'nvim-tree/nvim-tree.lua',
    version = '*',
    lazy = true,
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    keys = {
      {
        '<leader>e',
        function()
          local api = require('nvim-tree.api')
          if api.tree.is_tree_buf() and state.position == 'float' then
            tree.close_all()
            return
          end

          tree.open()
        end,
        desc = 'Explorer NvimTree',
        remap = true,
        silent = true,
      },
    },

    opts = function()
      local size_utils = require('utils.ui')
      local size_configs = require('configs.size')
      local icons = require('configs.icons')

      state.opts = {
        hijack_cursor = true, --Keeps the cursor on the first letter of the filename when moving in the tree.
        update_focused_file = {
          enable = true,
          update_root = {
            enable = true,
            ignore_list = {},
          },
          exclude = false,
        },
        filters = {
          enable = true,
          git_ignored = false,
        },
        system_open = {
          cmd = 'open',
          args = { '-R' },
        },
        renderer = {
          icons = {
            git_placement = 'right_align',
            glyphs = {
              folder = {
                arrow_closed = icons.explorer.collapsed,
                arrow_open = icons.explorer.expanded,
                default = icons.explorer.folder,
                open = icons.explorer.folder_open,
                empty = icons.explorer.folder_empty,
                empty_open = icons.explorer.folder_empty_open,
                symlink = icons.explorer.folder_symlink,
                symlink_open = icons.explorer.folder_symlink,
              },
              git = {
                unstaged = icons.git.unstaged,
                staged = icons.git.staged,
                unmerged = icons.git.unmerged,
                renamed = icons.git.renamed,
                untracked = icons.git.untracked,
                deleted = icons.git.deleted,
                ignored = icons.git.ignored,
              },
            },
          },
        },

        view = {
          number = true,
          relativenumber = true,
          side = 'right',
          -- Width when not in float mode
          width = function()
            local panel_cols = size_utils.computed_size(size_configs.side_panel)
            return panel_cols
          end,

          float = {
            enable = require('plugins.editor.nvim-tree.utils').state.position == 'float',
            quit_on_focus_loss = false,
            open_win_config = function()
              local size = size_utils.popup_config('lg')
              local window_w = size.width
              local window_h = math.floor(size.height / 2)
              local col = size.col
              local row = size.row

              return {
                title = ' NvimTree ',
                title_pos = 'center',
                border = 'rounded',
                relative = 'editor',
                row = row,
                col = col,
                width = window_w,
                height = window_h - 1, -- Minus 1 for the space between the two window
              }
            end,
          },
        },

        on_attach = function(tree_bufnr)
          local api = require('nvim-tree.api')

          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, {
              desc = 'nvim-tree: ' .. desc,
              buffer = tree_bufnr,
              noremap = true,
              silent = true,
              nowait = true,
            })
          end

          map('n', '<C-t>', function()
            tree.switch_position('side')
            tree.open({ switching = true })
          end, 'Switch to side')

          map('n', '<Tab>', function()
            tree.toggle_focus()
          end, 'Preview')

          map('n', 'q', tree.close_all, 'Close')
          map('n', 'B', tree.toggle_preview, 'Toggle preview')

          map('n', 'c', api.fs.copy.node, 'Copy')
          map('n', 'x', api.fs.cut, 'Cut')
          map('n', 'p', api.fs.paste, 'Paste')

          map('n', '/', function()
            tree.toggle_preview(false)
            api.live_filter.start()
            state.live_filter_triggered = true
          end, 'Live Filter: Start')
          map('n', '<Esc>', api.live_filter.clear, 'Clear live filter')

          map('n', 'r', api.node.run.system, 'Reveal in Finder')

          map('n', 'd', api.fs.remove, 'Delete')
          map('n', 'y', api.fs.copy.filename, 'Copy name')
          map('n', 'Y', api.fs.copy.relative_path, 'Copy relative path')

          map('n', '<Right>', tree.create_node_action('expand'), 'Expand node')
          map('n', '<S-Right>', api.tree.expand_all, 'Expand all nodes')
          map('n', '<Left>', tree.create_node_action('collapse'), 'Collapse node')
          map('n', '<S-Left>', api.tree.collapse_all, 'Collapse all nodes')
          map('n', '<CR>', tree.create_node_action('toggle'), 'Open')
          map('n', 'g?', function()
            api.tree.toggle_help()
            vim.api.nvim_win_set_config(require('nvim-tree.help').winnr, { border = 'rounded' })
          end, 'Help')

          vim.api.nvim_create_autocmd('BufEnter', {
            group = state.preview_watcher,
            callback = function(ev)
              if ev.buf == tree_bufnr then
                vim.schedule(function()
                  tree.toggle_preview(state.preview_on_focus)
                end)
                return
              end

              if state.live_filter_triggered then
                state.live_filter_triggered = false
                return
              end

              if state.position ~= 'float' then
                return
              end

              local current_buf = vim.api.nvim_get_current_buf()
              local preview_buf = tree.preview_buf()

              if current_buf ~= preview_buf and current_buf ~= tree_bufnr then
                tree.close_all()
              end
            end,
          })
        end,

        -- We will hijack the directories ourselves for the floating view to work correctly
        hijack_directories = {
          enable = false,
          auto_open = false,
        },
      }

      return state.opts
    end,

    config = function(_, opts)
      require('nvim-tree').setup(opts)
    end,
  },
}
