return {
  'nvim-tree/nvim-tree.lua',
  version = '*',
  lazy = false,
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    'hareki/nvim-tree-preview.lua',
  },
  keys = {
    { '<leader>e', ':NvimTreeToggle<cr>', desc = 'Explorer NvimTree', remap = true, silent = true },
  },
  opts = function()
    local palette = Util.get_palette()
    local float_enabled = true
    local height_ratio = Constant.ui.popup_size.lg.HEIGHT
    local width_ratio = Constant.ui.popup_size.lg.WIDTH

    Util.highlights({
      NvimTreeSignColumn = {
        link = 'NormalFloat',
      },
      NvimTreeCutHL = {
        bg = palette.maroon,
        fg = palette.base,
      },
      NvimTreeCopiedHL = {
        bg = palette.surface2,
        fg = palette.text,
      },
    })

    return {
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
              arrow_closed = '',
              arrow_open = '',
              default = '',
              open = '',
              empty = '',
              empty_open = '',
              symlink = '',
              symlink_open = '',
            },
            git = {
              unstaged = '󰄱',
              staged = '',
              unmerged = '',
              renamed = '󰁕',
              untracked = '',
              deleted = '',
              ignored = '',
            },
          },
        },
      },
      on_attach = function(bufnr)
        local preview = require('nvim-tree-preview')
        local preview_manager = require('nvim-tree-preview.manager')
        local api = require('nvim-tree.api')

        local function opts(desc, external_bufnr)
          return {
            desc = 'nvim-tree: ' .. desc,
            buffer = external_bufnr or bufnr,
            noremap = true,
            silent = true,
            nowait = true,
          }
        end

        local function close()
          preview.close()
          api.tree.close()
        end
        local function toggle_preview()
          local tree_win = api.tree.winid()
          if not tree_win or not vim.api.nvim_win_is_valid(tree_win) then
            return
          end

          local is_preview_open = preview.is_open()

          -- Just toggle the preview on/off if float nvim-tree is not enabled
          if not float_enabled then
            if is_preview_open then
              preview.unwatch()
            else
              preview.watch()
            end

            return
          end

          local size = Util.ui.get_popup_size('lg')
          local window_h = math.floor(size.height / 2)
          local half_height = window_h - 1 -- Minus 1 for the space between the two windows

          -- Have to add one extra row if the total height is an odd number to fill out the entire popup size
          local offset = Util.ui.get_popup_size('lg').height % 2 == 0 and 0 or 1
          local full_height = window_h * 2 + offset

          local cfg = vim.api.nvim_win_get_config(tree_win)

          if is_preview_open then
            cfg.height = full_height
            vim.api.nvim_win_set_config(tree_win, cfg)
            preview.unwatch()
          else
            cfg.height = half_height
            vim.api.nvim_win_set_config(tree_win, cfg)
            preview.watch()
          end
        end

        ---@param folder_action 'expand' | 'collapse' | 'toggle'
        local function node_action(folder_action)
          return function()
            local ok, node = pcall(api.tree.get_node_under_cursor)
            if not ok or not node then
              return
            end

            local is_file_node = node.nodes == nil

            if is_file_node then
              api.node.open.edit()
              close()
              return
            end

            if
              folder_action == 'toggle'
              or folder_action == 'expand' and not node.open
              or folder_action == 'collapse' and node.open
            then
              api.node.open.edit()
            end
          end
        end

        -- Toggle focus between nvim-tree and preview window
        vim.keymap.set('n', '<Tab>', function()
          local ok, node = pcall(api.tree.get_node_under_cursor)
          if not ok or not node then
            return
          end
          local is_file_node = node.nodes == nil

          if preview.is_open() and is_file_node then
            preview.node(node, { toggle_focus = true })
          end
        end, opts('Preview'))

        vim.schedule(function()
          preview.watch()
          vim.keymap.set('n', 'q', close, opts('Close'))
          vim.keymap.set('n', 'B', toggle_preview, opts('Toggle Preview'))

          if float_enabled then
            local perview_buf = preview_manager.instance.preview_buf

            vim.keymap.set('n', 'B', toggle_preview, opts('Toggle Preview', perview_buf))
            vim.keymap.set('n', 'q', close, opts('Close', perview_buf))
          end
        end)
        vim.keymap.set('n', 'c', api.fs.copy.node, opts('Copy'))
        vim.keymap.set('n', 'x', api.fs.cut, opts('Cut'))
        vim.keymap.set('n', 'p', api.fs.paste, opts('Paste'))

        vim.keymap.set('n', '/', api.live_filter.start, opts('Live Filter: Start'))
        vim.keymap.set('n', 'r', api.node.run.system, opts('Reveal in Finder'))

        vim.keymap.set('n', 'd', api.fs.remove, opts('Delete'))
        vim.keymap.set('n', 'y', api.fs.copy.filename, opts('Copy Name'))
        vim.keymap.set('n', 'Y', api.fs.copy.relative_path, opts('Copy Relative Path'))

        vim.keymap.set('n', '<Right>', node_action('expand'), opts('Expand node'))
        vim.keymap.set('n', '<S-Right>', api.tree.expand_all, opts('Expand all nodes'))
        vim.keymap.set('n', '<Left>', node_action('collapse'), opts('Collapse node'))
        vim.keymap.set('n', '<S-Left>', api.tree.collapse_all, opts('Collapse all nodes'))
        vim.keymap.set('n', '<CR>', node_action('toggle'), opts('Open'))
      end,

      view = {
        number = true,
        relativenumber = true,
        width = float_enabled and function()
          return math.floor(vim.opt.columns:get() * width_ratio)
        end or nil,

        float = {
          enable = float_enabled,
          quit_on_focus_loss = false,
          open_win_config = function()
            local size = Util.ui.get_popup_size('lg')
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
    }
  end,
}
