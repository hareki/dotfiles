return {
  require('utils.ui').catppuccin(function(palette, sub_palette)
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
      NvimTreeLiveFilterPrefix = {
        fg = palette.yellow,
      },
      NvimTreeGitStagedIcon = {
        fg = sub_palette.yellow,
      },
      NvimTreeRootFolder = {
        fg = palette.text,
        style = {},
      },
    }
  end),
  {
    'hareki/nvim-tree-preview.lua',
    dependencies = {
      'nvim-lua/plenary.nvim',
      '3rd/image.nvim',
    },
    opts = function()
      local tree = require('plugins.editor.nvim-tree.utils')
      local state = tree.state

      return {
        -- title_format = ' %s ', -- File name
        title_format = require('configs.picker').preview_title,
        zindex = 50, -- The default value makes vim.ui.input behind the preview window
        image_preview = {
          enable = true,
        },

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
          local size = size_utils.popup_config(tree.state.size)

          -- We need to fill the missing row if the total height is an odd number,
          -- meaning when we can't have equal height for both windows
          local height_offset = size.height % 2 == 0 and 0 or 1

          if state.position == 'float' then
            return {
              width = tree_cfg.width,
              height = tree_cfg.height + height_offset,
            }
          end

          local preview_cols, preview_rows = size_utils.computed_size(side_preview.md)

          return {
            width = preview_cols,
            height = preview_rows,
          }
        end,
      }
    end,
  },
  {
    'nvim-tree/nvim-tree.lua',
    version = '*',
    event = 'VeryLazy',
    dependencies = {
      'echasnovski/mini.icons',
    },
    keys = {
      {
        '<leader>e',
        function()
          local api = require('nvim-tree.api')
          local tree = require('plugins.editor.nvim-tree.utils')
          local state = tree.state

          if api.tree.is_tree_buf() and state.position == 'float' then
            tree.close_all()
            return
          end

          api.tree.reload()
          tree.open()
        end,
        desc = 'Explorer',
        remap = true,
        silent = true,
      },
    },

    opts = function()
      local ui_utils = require('utils.ui')
      local size_configs = require('configs.size')
      local icons = require('configs.icons')
      local tree = require('plugins.editor.nvim-tree.utils')
      local state = tree.state

      state.opts = {
        --Keeps the cursor on the first letter of the filename when moving in the tree.
        hijack_cursor = true,

        -- We will hijack the directories ourselves for the floating view to work correctly
        hijack_directories = {
          enable = false,
          auto_open = false,
        },

        live_filter = {
          prefix = require('configs.picker').prompt_prefix,
          always_show_folders = false,
        },

        update_focused_file = {
          enable = true,
          -- Prevent changing cwd when navigating to files outside of the tree root
          update_root = {
            enable = false,
          },
        },
        filters = {
          enable = true,
          git_ignored = false,
          custom = { '^\\.DS_Store$' },
        },
        git = {
          enable = true,
          show_on_dirs = false,
          show_on_open_dirs = true,
          disable_for_dirs = {},
          timeout = 400,
        },
        diagnostics = {
          enable = true,
          show_on_dirs = false,
          show_on_open_dirs = true,
          debounce_delay = 500,
          severity = {
            min = vim.diagnostic.severity.HINT,
            max = vim.diagnostic.severity.ERROR,
          },
          icons = {
            error = icons.diagnostics.Error,
            warning = icons.diagnostics.Warn,
            info = icons.diagnostics.Info,
            hint = icons.diagnostics.Hint,
          },
        },
        system_open = {
          cmd = 'open',
          args = { '-R' },
        },
        renderer = {
          root_folder_label = tree.format_root_label,
          indent_width = 2,
          special_files = {},
          highlight_diagnostics = 'none',
          icons = {
            show = {
              folder_arrow = false,
            },
            git_placement = 'after',
            diagnostics_placement = 'after',
            glyphs = {
              bookmark = vim.trim(icons.explorer.selected),
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
          number = false,
          relativenumber = false,
          side = 'right',
          -- Width when not in float mode
          width = function()
            local panel_cols = ui_utils.computed_size(size_configs.side_panel.md)
            return panel_cols
          end,

          float = {
            enable = require('plugins.editor.nvim-tree.utils').state.position == 'float',
            quit_on_focus_loss = false,
            open_win_config = function()
              local size = ui_utils.popup_config(tree.state.size)
              local window_w = size.width
              local window_h = math.floor(size.height / 2)
              local col = size.col
              local row = size.row

              return {
                title = ' Explorer ',
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
              desc = 'NvimTree: ' .. desc,
              buffer = tree_bufnr,
              noremap = true,
              silent = true,
              nowait = true,
            })
          end

          map('n', '<C-t>', function()
            tree.switch_position('side')
            tree.open({ switching = true })
          end, 'Switch to Side')

          map('n', '<Tab>', function()
            tree.toggle_focus()
          end, 'Preview')

          map('n', 'q', tree.close_all, 'Close')
          map('n', 'B', tree.toggle_preview, 'Toggle Preview')

          map('n', 'c', api.fs.copy.node, 'Copy')
          map('n', 'x', api.fs.cut, 'Cut')
          map('n', 'p', api.fs.paste, 'Paste')
          map('n', 'n', api.fs.create, 'Create File or Directory')

          map('n', '/', function()
            tree.toggle_preview(false)
            api.live_filter.start()
            state.live_filter_triggered = true
          end, 'Live Filter: Start')
          map('n', '<Esc>', api.live_filter.clear, 'Clear Live Filter')

          map('n', 'd', api.fs.trash, 'Trash')
          map('n', 'D', api.fs.remove, 'Remove')
          map('n', 'y', api.fs.copy.filename, 'Copy Name')
          map('n', 'r', api.fs.rename, 'Rename')
          map('n', 'R', api.node.run.system, 'Reveal in Finder')
          map('n', 'Y', api.fs.copy.relative_path, 'Copy Relative Path')

          map('n', '<Right>', tree.create_node_action('expand'), 'Expand Node')
          map('n', '<S-Right>', api.tree.expand_all, 'Expand All Nodes')
          map('n', '<Left>', tree.create_node_action('collapse'), 'Collapse Node')
          map('n', '<S-Left>', api.tree.collapse_all, 'Collapse All Nodes')
          map('n', '<CR>', tree.create_node_action('toggle'), 'Open File/Toggle Folder')
          map('n', 'g?', function()
            api.tree.toggle_help()
            vim.api.nvim_win_set_config(require('nvim-tree.help').winnr, { border = 'rounded' })
          end, 'Help')

          map('n', '<C-n>', tree.mark_and_next, 'Bookmark and Next')
          map('n', '<C-p>', tree.mark_and_prev, 'Bookmark and Previous')
          map('n', 'M', api.tree.toggle_no_bookmark_filter, 'Toggle Bookmark Filter')
          map('n', 'bd', api.marks.bulk.trash, 'Trash Bookmarked')
          map('n', 'bt', api.marks.bulk.delete, 'Delete Bookmarked')
          map('n', 'bm', api.marks.bulk.move, 'Move Bookmarked')
          map('n', '<A-r>', api.tree.reload, 'Refresh')

          vim.api.nvim_create_autocmd('BufEnter', {
            group = state.preview_watcher,
            callback = function(ev)
              if ev.buf == tree_bufnr then
                tree.toggle_preview(state.preview_on_focus)
                return
              end

              if state.live_filter_triggered then
                state.live_filter_triggered = false
                return
              end
            end,
          })
        end,
      }

      return state.opts
    end,

    config = function(_, opts)
      require('nvim-tree').setup(opts)
    end,
  },
}
