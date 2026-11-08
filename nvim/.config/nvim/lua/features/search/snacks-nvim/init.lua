-- Function-valued, so snacks sizes and centers popups per open, across terminal resizes
local sm = UI.layout.picker_fn('sm')

local layouts = require('features.search.snacks-nvim.layouts')
-- Required, not deferred: the opts below take its source table, and the highlight callback its
-- palette key, at startup
local tabs = require('features.search.snacks-nvim.sources.tabs')

--- @module 'features.search.snacks-nvim.actions'
local actions = Defer.on_exported_call('features.search.snacks-nvim.actions')

--- @module 'features.search.snacks-nvim.sources.buffers'
local buffers = Defer.on_exported_call('features.search.snacks-nvim.sources.buffers')

--- @module 'features.search.snacks-nvim.sources.keymaps'
local keymaps = Defer.on_exported_call('features.search.snacks-nvim.sources.keymaps')

--- @module 'snacks.picker'
local picker = Defer.on_exported_call('snacks.picker')

return {
  UI.catppuccin(function(palette)
    return {
      SnacksPickerPrompt = { fg = palette.blue },
      SnacksPickerPreviewCursorLine = { link = 'CursorLine' },
      SnacksPickerInputCursorLine = { bg = 'none', fg = palette.text },
      SnacksPickerListCursorLine = { link = 'ListCursorLine' },
      SnacksPickerKeymapLhs = { fg = palette.blue },
      SnacksPickerTabName = { fg = palette[tabs.LABEL_COLOR] },
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
          Snacks.picker.files({ layout = actions.preview_layout('files') })
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
      { '<leader>fb', picker.buffers, desc = 'Find Buffers' },
      { '<leader>f<Tab>', picker.tabs, desc = 'Find Tabs' },
      { '<leader>fk', picker.keymaps, mode = { 'n', 'x' }, desc = 'Find Keymaps' },
      { '<leader>fh', picker.highlights, desc = 'Find Highlight Groups' },
      { '<leader>fH', picker.help, desc = 'Find Help Tags' },
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
            format = buffers.format,
            transform = buffers.transform,
            matcher = { sort_empty = true }, -- Required for sort to work with empty search
            -- Modified buffers first, then snacks' default order (score, text length, index)
            sort = { fields = { 'modified', 'score:desc', '#text', 'idx' } },
            win = {
              input = {
                keys = {
                  ['x'] = { 'bufdelete' },
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
            transform = keymaps.transform,
            format = function(item)
              return keymaps.format(item, sm.width())
            end,

            layout = {
              hidden = { 'preview' },
              layout = vim.tbl_extend('force', sm, { backdrop = false }),
            },
          },

          tabs = tabs.source,

          todo_comments = {
            show_pattern = false,
            actions = {
              snacks_to_trouble = actions.todo_to_trouble,
            },
          },
        },
      },
    },
  },
}
