local ui_name = 'File Tree'

--- @module 'nvim-tree.api'
local api = Defer.on_index('nvim-tree.api')

return {
  UI.catppuccin(function(palette)
    local sub_palette = UI.catppuccin.get_palette('latte')
    local picker_bg = UI.color.blend_hex(palette.base, palette.blue)

    return {
      NvimTreeSignColumn = { link = 'NormalFloat' },
      NvimTreeCursorLineNr = { link = 'CursorLine' },
      NvimTreeNormal = { link = 'Normal' },
      NvimTreeCutHL = { bg = palette.maroon, fg = palette.base },
      NvimTreeCopiedHL = { bg = palette.surface2, fg = palette.text },
      NvimTreeLiveFilterPrefix = { fg = palette.yellow },
      NvimTreeGitStagedIcon = { fg = sub_palette.yellow },
      NvimTreeRootFolder = { fg = palette.overlay2 },
      NvimTreeGitMergeIcon = { fg = palette.yellow },
      NvimTreeWindowPicker = {
        bg = picker_bg,
        bold = true,
        fg = palette.blue,
      },
    }
  end, 'nvim-tree.lua'),

  UI.which_key({
    rules = { plugin = 'nvim-tree.lua', icon = Conf.icons.tools.TREE, color = 'blue' },
  }),

  {
    'hareki/nvim-tree-preview.lua',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },

    opts = function()
      local tree = require('features.navigation.nvim-tree-lua.utils')
      local state = tree.state

      return {
        title_format = Conf.picker.PREVIEW_TITLE,
        zindex = 50, -- The default value makes vim.ui.input behind the preview window
        image_preview = { enable = true },
        on_close = function()
          tree.toggle_tree_height('expand')
        end,

        keymaps = {
          ['q'] = tree.close_all,
          ['<Tab>'] = tree.toggle_focus,
          ['<C-t>'] = tree.switch_to_side,
          ['B'] = function()
            api.tree.focus()
            tree.toggle_preview()
          end,
          ['<CR>'] = tree.create_node_action('toggle'),
        },

        win_position = {
          col = function()
            if state.position == 'float' then
              return -1
            end

            return UI.layout.side_preview().col
          end,

          row = function(tree_win)
            if state.position == 'float' then
              local tree_cfg = vim.api.nvim_win_get_config(tree_win)
              return tree_cfg.height + 1
            end

            return UI.layout.side_preview().row
          end,
        },

        calculate_win_size = function()
          if state.position == 'float' then
            local geometry, preview_height = tree.float_geometry('collapse')
            return {
              width = geometry.width,
              height = preview_height,
            }
          end

          local preview = UI.layout.side_preview()

          return {
            width = preview.width,
            height = preview.height,
          }
        end,
      }
    end,
  },
  {
    'hareki/nvim-tree.lua',
    -- Load before LSP starts, or diagnostics published earlier never show in the tree
    event = 'VeryLazy',
    keys = {
      {
        '<leader>e',
        function()
          local tree = require('features.navigation.nvim-tree-lua.utils')
          local state = tree.state

          if api.tree.is_tree_buf() and state.position == 'float' then
            tree.close_all()
            return
          end

          -- No reload: filesystem watchers keep it fresh, a sync reload stalls large repos
          tree.open()
        end,
        desc = ui_name,
      },
    },

    opts = function()
      local tree = require('features.navigation.nvim-tree-lua.utils')
      local state = tree.state

      state.opts = {
        hijack_cursor = true, -- Keep cursor on the first letter of filename
        actions = {
          open_file = {
            window_picker = {
              enable = false, -- Skips the prompt of where to put the file where there're multiple windows
            },
          },
        },

        -- Hijack directories ourselves for the floating view to work correctly
        hijack_directories = {
          enable = false,
        },
        live_filter = {
          prefix = Conf.picker.PROMPT_PREFIX,
          always_show_folders = false,
        },
        update_focused_file = {
          enable = true,
        },
        filters = {
          git_ignored = false,
          custom = { '^\\.DS_Store$' },
        },
        git = {
          show_on_dirs = false,
        },
        diagnostics = {
          enable = true,
          icons = {
            error = Conf.icons.diagnostics.ERROR,
            warning = Conf.icons.diagnostics.WARN,
            info = Conf.icons.diagnostics.INFO,
            hint = Conf.icons.diagnostics.HINT,
          },
        },
        renderer = {
          root_folder_label = tree.format_root_label,
          special_files = {},
          icons = {
            show = {
              folder_arrow = false,
            },
            git_placement = 'after',
            diagnostics_placement = 'after',
            glyphs = {
              bookmark = vim.trim(Conf.icons.file_tree.SELECTED),
              folder = {
                default = Conf.icons.file_tree.FOLDER,
                open = Conf.icons.file_tree.FOLDER_OPEN,
                empty = Conf.icons.file_tree.FOLDER_EMPTY,
                empty_open = Conf.icons.file_tree.FOLDER_EMPTY_OPEN,
                symlink = Conf.icons.file_tree.FOLDER_SYMLINK,
                symlink_open = Conf.icons.file_tree.FOLDER_SYMLINK,
              },
              git = {
                unstaged = Conf.icons.git.UNSTAGED,
                staged = Conf.icons.git.STAGED,
                unmerged = Conf.icons.git.UNMERGED,
                renamed = Conf.icons.git.RENAMED,
                untracked = Conf.icons.git.UNTRACKED,
                deleted = Conf.icons.git.DELETED,
                ignored = Conf.icons.git.IGNORED,
              },
            },
          },
        },

        view = {
          signcolumn = 'no',
          statuscolumn = ' ',
          side = 'right',
          -- Width when not in float mode
          width = function()
            return (UI.layout.side_size('side_panel', 'md'))
          end,

          float = {
            enable = state.position == 'float',
            -- Replaced by tree.close_on_focus_loss, which spares floats
            quit_on_focus_loss = false,
            open_win_config = function()
              return vim.tbl_extend('force', tree.float_geometry('collapse'), {
                title = string.format(' %s ', ui_name),
                title_pos = 'center',
                border = 'rounded',
                relative = 'editor',
              })
            end,
          },
        },
        help = { border = 'rounded' },

        on_attach = function(tree_bufnr)
          local common = require('utils.common')
          local map = common.buf_mapper(tree_bufnr, { prefix = 'File Tree: ', nowait = true })

          map('n', '<C-t>', tree.switch_to_side, 'Switch to Side')

          map('n', '<Tab>', tree.toggle_focus, 'Toggle Preview Focus')

          map('n', 'q', tree.close_all, 'Close')
          map('n', 'B', tree.toggle_preview, 'Toggle Preview')

          map('n', 'c', api.fs.copy.node, 'Copy')
          map('n', 'x', api.fs.cut, 'Cut')
          map('n', 'p', api.fs.paste, 'Paste')
          map('n', 'N', api.fs.create, 'Create File or Directory')

          map('n', 'f', function()
            tree.toggle_preview(false)
            api.filter.live.start()
          end, 'Live Filter: Start')
          map('n', '<Esc>', function()
            api.filter.live.clear()
            UI.color.nohlsearch()
          end, 'Clear Live Filter and Search Highlights')

          map('n', 'd', api.fs.trash, 'Trash')
          map('n', 'D', api.fs.remove, 'Remove')
          map('n', 'y', api.fs.copy.filename, 'Copy Name')
          map('n', 'r', api.fs.rename, 'Rename')

          map('n', 'R', function()
            local ok, node = pcall(api.tree.get_node_under_cursor)
            if not ok or not node then
              return
            end

            vim.system({ 'open', '-R', node.absolute_path })
          end, 'Reveal in Finder')

          map('n', 'Y', api.fs.copy.absolute_path, 'Copy Absolute Path')

          map('n', '<Right>', tree.create_node_action('expand'), 'Expand Node')
          map('n', '<S-Right>', api.tree.expand_all, 'Expand All Nodes')
          map('n', '<Left>', tree.create_node_action('collapse'), 'Collapse Node')
          map('n', '<S-Left>', api.tree.collapse_all, 'Collapse All Nodes')
          map('n', { '<CR>', 'e' }, tree.create_node_action('toggle'), 'Open File/Toggle Folder')
          map('n', 'g?', api.tree.toggle_help, 'Toggle Help')

          map('n', '<C-n>', tree.mark_and_next, 'Bookmark and Next')
          map('n', '<C-p>', tree.mark_and_prev, 'Bookmark and Previous')
          map('n', 'M', api.filter.no_bookmark.toggle, 'Toggle Bookmark Filter')
          map('n', 'bd', api.marks.bulk.trash, 'Trash Bookmarked')
          map('n', 'bt', api.marks.bulk.delete, 'Delete Bookmarked')
          map('n', 'bm', api.marks.bulk.move, 'Move Bookmarked')
          map('n', '<A-r>', api.tree.reload, 'Refresh')
        end,
      }

      return state.opts
    end,

    config = function(_, opts)
      local tree = require('features.navigation.nvim-tree-lua.utils')
      local state = tree.state

      vim.api.nvim_create_autocmd('VimResized', {
        group = vim.api.nvim_create_augroup(
          'features.navigation.nvim-tree.resize',
          { clear = true }
        ),
        callback = function()
          tree.resize()
        end,
      })

      -- Deferred like the Snacks pickers' check, so nvim-tree's own hops through a split
      -- (removing a file shown in one) are back in the tree by the time it runs
      vim.api.nvim_create_autocmd('WinEnter', {
        group = vim.api.nvim_create_augroup(
          'features.navigation.nvim-tree.focus-loss',
          { clear = true }
        ),
        callback = function()
          vim.schedule(tree.close_on_focus_loss)
        end,
      })

      -- Subscribed here, not on User NvimTreeSetup: switch_position() re-runs setup(), re-firing
      -- that event while old subscriptions persist, so every switch would stack another handler
      local events = api.events
      events.subscribe(events.Event.NodeRenamed, function(data)
        Snacks.rename.on_rename_file(data.old_name, data.new_name)
      end)

      -- TreeAttachedPost fires per open (the buffer is bufhidden=wipe), matching the watcher's
      -- lifetime; tree.open() misses direct api.tree.open() calls, and on_attach runs for help too
      events.subscribe(events.Event.TreeAttachedPost, function(tree_bufnr)
        --- @cast tree_bufnr integer
        state.preview_watcher =
          vim.api.nvim_create_augroup('features.navigation.nvim-tree.preview', { clear = true })

        vim.api.nvim_create_autocmd('BufEnter', {
          group = state.preview_watcher,
          buffer = tree_bufnr,
          callback = function()
            tree.toggle_preview(state.preview_on_focus)
          end,
        })
      end)

      local nvim_tree = require('nvim-tree')
      nvim_tree.setup(opts)
    end,
  },
}
