return {
  UI.catppuccin(function(palette)
    return {
      SnacksPickerPrompt = { fg = palette.blue },
      SnacksPickerCursorLine = { bg = palette.surface0 },
      SnacksPickerPreviewCursorLine = { link = 'CursorLine' },
      SnacksPickerInputCursorLine = { bg = 'none', fg = palette.text },
      SnacksPickerListCursorLine = { link = 'ListCursorLine' },
      SnacksPickerKeymapLhs = { fg = palette.blue },
      SnacksPickerSelected = { bg = 'none', fg = palette.text },
      SnacksPickerUnselected = { bg = 'none', fg = palette.text },
      SnacksPickerDir = { fg = palette.overlay1 },
      SnacksPickerFile = { fg = palette.text },
      SnacksPickerTime = { fg = palette.text },
    }
  end),

  {
    'hareki/snacks.nvim',
    lazy = false,
    -- This plugin has many responsibilities, should load it early to setup stuff correctly
    priority = Conf.priority.CORE,
    keys = {
      {
        'gi',
        function()
          local image_utils = require('core.snacks-nvim.utils.image')
          image_utils.hover_image()
        end,
        desc = 'Hover Image',
      },
      {
        '<leader><leader>',
        function()
          local state = require('core.snacks-nvim.utils.state')

          Snacks.picker.files({
            layout = {
              --- @diagnostic disable-next-line: assign-type-mismatch Wrong type from snacks
              preview = state.get('files', 'preview'),
            },
          })
        end,
        desc = 'Find Files',
      },
      {
        '<leader>fd',
        function()
          Snacks.picker.diagnostics_buffer()
        end,
        desc = 'Find Diagnostics Buffer',
      },
      {
        '<leader>fD',
        function()
          Snacks.picker.diagnostics()
        end,
        desc = 'Find Diagnostics',
      },
      {
        '<leader>f/',
        function()
          Snacks.picker.grep({
            title = 'Grep',
            regex = false,
            hidden = true,
          })
        end,
        desc = 'Find Text',
      },
      {
        '<leader>fb',
        function()
          Snacks.picker.buffers({
            title = 'Buffers',
          })
        end,
        desc = 'Find Buffers',
      },
      {
        '<leader>fR',
        function()
          Snacks.picker.registers()
        end,
        desc = "Find Registers' Contents",
      },
      {
        '<leader>fk',
        function()
          Snacks.picker.keymaps()
        end,
        mode = { 'n', 'x' },
        desc = 'Find Keymaps',
      },
      {
        '<leader>fu',
        function()
          Snacks.picker.undo()
        end,
        desc = 'Open Undo History',
      },

      {
        '<leader>fh',
        function()
          Snacks.picker.highlights()
        end,
        desc = 'Find Highlight Groups',
      },
      {
        '<leader>fH',
        function()
          Snacks.picker.help()
        end,
        desc = 'Find Helps',
      },
      {
        '<leader>fgb',
        function()
          Snacks.picker.git_branches()
        end,
        desc = 'Find Git Branches',
      },
      {
        '<leader>.',
        function()
          Snacks.scratch()
        end,
        desc = 'Toggle Scratch Buffer',
      },
      {
        '<leader>f.',
        function()
          Snacks.scratch.select()
        end,
        desc = 'Select Scratch Buffer',
      },
      {
        '<A-t>',
        function()
          Snacks.terminal.toggle(nil, { win = { position = 'float' } })
        end,
        mode = { 'n', 'x', 't', 'i' },
        desc = 'Toggle Floating Terminal',
      },

      {
        '<A-g>',
        function()
          local lazygit = require('core.snacks-nvim.utils.lazygit')
          lazygit.toggle()
        end,
        mode = { 'n', 'x', 't', 'i' },
        desc = 'Toggle Lazygit',
      },

      -- Hack to get keymaps to show int Snacks.picker.keymaps
      { 'za', 'za', desc = 'Toggle Fold Under Cursor' },
      { 'zA', 'zA', desc = 'Toggle All Folds Under Cursor' },
      { 'zC', 'zC', desc = 'Close All Folds Under Cursor' },
      { 'zD', 'zD', desc = 'Delete All Folds Under Cursor' },
      { 'zE', 'zE', desc = 'Delete All Folds in File' },
      { 'zM', 'zM', desc = 'Close All Folds' },
      { 'zO', 'zO', desc = 'Open All Folds Under Cursor' },
      { 'zR', 'zR', desc = 'Open All Folds' },
      { 'zi', 'zi', desc = 'Toggle Folding' },
      { 'zm', 'zm', desc = 'Fold More' },
      { 'zo', 'zo', desc = 'Open Fold Under Cursor' },
      { 'zr', 'zr', desc = 'Fold Less' },
    },

    init = function()
      local lazygit = require('core.snacks-nvim.utils.lazygit')
      lazygit.setup()
    end,

    opts = function()
      local popup_config = UI.layout.popup
      local config = {
        input = popup_config('input'),
        full = popup_config('full'),
        sm = popup_config('sm', true),
        lg_border = popup_config('lg', true),
        lg = popup_config('lg'),
      }
      local select_width = config.sm.width

      local layouts = require('core.snacks-nvim.pickers.layouts')
      local layout_opts = {
        width = config.lg_border.width,
        height = config.lg_border.height,
        preview_title = Conf.picker.PREVIEW_TITLE,
      }

      -- Wrapping this with Defer.on_exported_call will result in `nvim_create_augroup must not be called in a fast event context` error
      local transformers = require('core.snacks-nvim.utils.transformers')

      local formatters = Defer.on_exported_call('core.snacks-nvim.utils.formatters')
      local sorters = Defer.on_exported_call('core.snacks-nvim.utils.sorters')
      local actions = Defer.on_exported_call('core.snacks-nvim.actions')
      local defer_scroll_half_page = function(direction)
        local scroll_half_page
        return function(...)
          if not scroll_half_page then
            scroll_half_page = actions.scroll_half_page(direction)
          end
          return scroll_half_page(...)
        end
      end

      return {
        words = { enabled = true },
        bigfile = { enabled = true },
        input = { enabled = true, start_in_insert = true },
        lazygit = { enabled = true, configure = false },
        scratch = { enabled = true },
        rename = { enabled = true },
        image = {
          enabled = true,
          convert = {
            notify = true,
          },
          -- Inline images are inserted as virtual lines, and virtual lines are tricky to scroll, so better keep it short
          doc = {
            inline = true,
            max_width = config.full.width,
            max_height = 15,
            excluded_filetypes = Conf.filetypes.merge(Conf.filetypes.JS_ALL, Conf.filetypes.CSS),
          },
        },

        picker = {
          icons = {
            ui = {
              selected = Conf.icons.file_tree.SELECTED,
              unselected = Conf.icons.file_tree.UNSELECTED,
            },
          },
          ui_select = true,
          prompt = Conf.picker.PROMPT_PREFIX,

          actions = {
            list_half_page_down = defer_scroll_half_page('down'),
            list_half_page_up = defer_scroll_half_page('up'),
            toggle_preview_focus = actions.toggle_preview_focus,
            toggle_preview = actions.toggle_preview,
            select = actions.select,
            snacks_to_trouble = actions.snacks_to_trouble,
          },

          win = {
            preview = {
              keys = {
                ['<Tab>'] = { 'toggle_preview_focus', mode = { 'i', 'n' } },
                ['<CR>'] = { 'confirm' },
                ['<C-t>'] = { 'snacks_to_trouble', mode = { 'i', 'n' } },

                ['B'] = { 'toggle_preview' },
                ['<C-b>'] = { 'toggle_preview', mode = { 'i', 'n' } },
              },
              wo = {
                number = true,
                relativenumber = true,
              },
            },
            input = {
              keys = {
                ['<PageDown>'] = { 'list_half_page_down', mode = { 'i', 'n' } },
                ['<PageUp>'] = { 'list_half_page_up', mode = { 'i', 'n' } },
                ['<Tab>'] = { 'toggle_preview_focus', mode = { 'i', 'n' } },

                ['<C-t>'] = { 'snacks_to_trouble', mode = { 'i', 'n' } },
                ['<C-Down>'] = { 'history_forward', mode = { 'i', 'n' } },
                ['<C-Up>'] = { 'history_back', mode = { 'i', 'n' } },

                ['<C-c>'] = { 'cancel', mode = { 'i', 'n' } },
                ['<C-p>'] = { 'select_and_prev', mode = { 'i', 'n' } },
                ['<C-n>'] = { 'select_and_next', mode = { 'i', 'n' } },

                ['B'] = { 'toggle_preview' },
                ['<C-b>'] = { 'toggle_preview', mode = { 'i', 'n' } },
              },
            },
          },

          layout = layouts.preview_below(layout_opts), -- Default layout
          layouts = {
            preview_right = layouts.preview_right(layout_opts),
          },

          sources = {
            select = {
              layout = {
                layout = {
                  width = select_width,
                  max_width = select_width,
                },
              },
            },

            buffers = {
              format = formatters.buffer_format,
              matcher = { sort_empty = true }, -- Required for sort to work with empty search
              sort = sorters.buffer_sort,
              win = {
                input = {
                  keys = {
                    ['x'] = { 'bufdelete', mode = { 'n' } }, -- close selected buffer from input (normal mode)
                  },
                },
              },
            },

            files = {
              transform = transformers.files_transform,
              hidden = true,
            },

            highlights = {
              layout = 'preview_right',
            },

            scratch = {
              win = {
                input = {
                  keys = {
                    ['x'] = { 'scratch_delete', mode = { 'n' } },
                  },
                },
              },
            },

            keymaps = {
              transform = transformers.keymap_transform,
              format = function(item, picker)
                return formatters.keymap_format(item, picker, config.sm.width)
              end,

              layout = {
                preview = false,
                preset = 'default',
                layout = {
                  backdrop = false,
                  height = config.sm.height,
                  width = config.sm.width,
                  max_height = config.sm.height,
                  max_width = config.sm.width,
                  col = config.sm.col,
                  row = config.sm.row,
                },
              },
            },
          },
        },

        styles = {
          float = {
            -- Slightly higher than satellite.nvim scrollbar (51)
            zindex = 52,
          },
          input = {
            height = config.input.height,
            width = config.input.width,
            col = config.input.col,
            row = config.input.row,
          },
          scratch = {
            height = config.lg.height,
            width = config.lg.width,
            col = config.lg.col,
            row = config.lg.row,
          },
          terminal = {
            title = ' Terminal ',
            title_pos = 'center',
            border = 'rounded',
            height = config.lg.height,
            width = config.lg.width,
            col = config.lg.col,
            row = config.lg.row,
          },
          lazygit = {
            backdrop = false,
            border = 'rounded',
            title = ' Git Client ',
            title_pos = 'center',
            height = config.full.height,
            width = config.full.width,
            col = config.full.col,
            row = config.full.row,
          },
        },
      }
    end,
  },
}
