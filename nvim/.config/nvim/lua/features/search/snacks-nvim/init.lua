-- Function-valued, so snacks sizes and centers popups per open, across terminal resizes
local sm = UI.layout.picker_fn('sm')

local layouts = require('features.search.snacks-nvim.layouts')
local keymap_registry = require('config.keymap-registry')
local tab_component = require('chrome.lualine-nvim.components.tab')

local transformers = Defer.on_exported_call('features.search.snacks-nvim.utils.transformers')
local formatters = Defer.on_exported_call('features.search.snacks-nvim.utils.formatters')
local finders = Defer.on_exported_call('features.search.snacks-nvim.utils.finders')
local actions = Defer.on_exported_call('features.search.snacks-nvim.actions')

return {
  UI.catppuccin(function(palette)
    return {
      SnacksPickerPrompt = { fg = palette.blue },
      SnacksPickerCursorLine = { bg = palette.surface0 },
      SnacksPickerPreviewCursorLine = { link = 'CursorLine' },
      SnacksPickerInputCursorLine = { bg = 'none', fg = palette.text },
      SnacksPickerListCursorLine = { link = 'ListCursorLine' },
      SnacksPickerKeymapLhs = { fg = palette.blue },
      SnacksPickerTabName = { fg = palette[tab_component.color] },
      SnacksPickerSelected = { bg = 'none', fg = palette.text },
      SnacksPickerUnselected = { bg = 'none', fg = palette.text },
      SnacksPickerDir = { fg = palette.overlay1 },
      SnacksPickerFile = { fg = palette.text },
      SnacksPickerTime = { fg = palette.text },
    }
  end),

  {
    'snacks.nvim',
    keys = {
      {
        '<leader><leader>',
        function()
          local picker_actions = require('features.search.snacks-nvim.actions')

          Snacks.picker.files({
            layout = {
              --- @diagnostic disable-next-line: assign-type-mismatch Wrong type from snacks
              preview = picker_actions.preview_shown.files,
            },
          })
        end,
        desc = 'Find Files',
      },
      {
        '<leader>f/',
        function()
          Snacks.picker.grep({
            regex = false,
            hidden = true,
          })
        end,
        desc = 'Find Text',
      },
      {
        '<leader>fb',
        function()
          Snacks.picker.buffers()
        end,
        desc = 'Find Buffers',
      },
      {
        '<leader>f<Tab>',
        function()
          Snacks.picker.pick('tabs')
        end,
        desc = 'Find Tabs',
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
        desc = 'Find Help Tags',
      },
    },

    opts = {
      picker = {
        icons = {
          ui = {
            selected = Conf.icons.file_tree.SELECTED,
            unselected = Conf.icons.file_tree.UNSELECTED,
          },
        },
        prompt = Conf.picker.PROMPT_PREFIX,

        actions = {
          list_half_page_down = actions.list_half_page_down,
          list_half_page_up = actions.list_half_page_up,
          toggle_preview_focus = actions.toggle_preview_focus,
          toggle_preview = actions.toggle_preview,
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
              relativenumber = true,
            },
          },
          input = {
            keys = {
              ['<PageDown>'] = { 'list_half_page_down', mode = { 'i', 'n' } },
              ['<PageUp>'] = { 'list_half_page_up', mode = { 'i', 'n' } },
              ['<Tab>'] = { 'toggle_preview_focus', mode = { 'i', 'n' } },

              ['<C-t>'] = { 'snacks_to_trouble', mode = { 'i', 'n' } },

              ['<C-c>'] = { 'cancel', mode = { 'i', 'n' } },
              ['<C-p>'] = { 'select_and_prev', mode = { 'i', 'n' } },
              ['<C-n>'] = { 'select_and_next', mode = { 'i', 'n' } },

              ['B'] = { 'toggle_preview' },
              ['<C-b>'] = { 'toggle_preview', mode = { 'i', 'n' } },
            },
          },
        },

        layout = { preset = 'preview_below' },
        layouts = layouts,

        sources = {
          buffers = {
            format = formatters.buffer_format,
            transform = transformers.buffer_transform,
            matcher = { sort_empty = true }, -- Required for sort to work with empty search
            -- Modified buffers first, then snacks' default order (score, text length, index)
            sort = { fields = { 'modified', 'score:desc', '#text', 'idx' } },
            win = {
              input = {
                keys = {
                  ['x'] = { 'bufdelete', mode = { 'n' } },
                },
              },
            },
          },

          files = {
            hidden = true,
            exclude = { '.DS_Store' },
          },

          highlights = {
            layout = 'preview_right',
          },

          keymaps = {
            transform = transformers.keymap_transform,
            format = function(item)
              return formatters.keymap_format(item, sm.width())
            end,

            layout = {
              preview = false,
              layout = vim.tbl_extend('force', sm, { backdrop = false }),
            },
          },

          tabs = {
            finder = finders.tabs,
            format = formatters.tab_format,
            confirm = actions.tab_switch,
            actions = {
              tab_close = actions.tab_close,
            },
            win = {
              input = {
                keys = {
                  ['<C-x>'] = { 'tab_close', mode = { 'n', 'i' } },
                  ['x'] = 'tab_close', -- close selected tab from input (normal mode)
                },
              },
              list = { keys = { ['dd'] = 'tab_close' } },
            },
          },

          todo_comments = {
            actions = {
              snacks_to_trouble = actions.todo_to_trouble,
            },
          },
        },
      },
    },
  },

  -- Hack to get the fold keymaps to show in Snacks.picker.keymaps; descs come from the
  -- keymap registry, shared with the which-key preset so the two never drift
  {
    'snacks.nvim',
    keys = vim.tbl_map(function(fold)
      return { fold[1], fold[1], desc = fold[2] }
    end, keymap_registry.FOLD_DESCS),
  },
}
