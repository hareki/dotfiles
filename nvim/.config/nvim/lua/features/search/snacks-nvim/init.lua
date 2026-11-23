local layouts = require('features.search.snacks-nvim.layouts')
-- Required, not deferred: the opts below take their source tables at startup
local buffers = require('features.search.snacks-nvim.sources.buffers')
local keymaps = require('features.search.snacks-nvim.sources.keymaps')
local tabs = require('features.search.snacks-nvim.sources.tabs')

--- @module 'features.search.snacks-nvim.actions'
local actions = Defer.on_exported_call('features.search.snacks-nvim.actions')

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
      SnacksPickerTabName = { fg = palette[Conf.icons.colors.TAB] },
      SnacksPickerSelected = { bg = 'none', fg = palette.text },
      SnacksPickerUnselected = { bg = 'none', fg = palette.text },
      SnacksPickerDir = { fg = palette.overlay1 },
      SnacksPickerFile = { fg = palette.text },
      SnacksPickerTime = { fg = palette.text },
      -- The buffers source's mark on a modified buffer
      ModifiedIndicator = { fg = palette.yellow },
    }
  end),

  UI.which_key({
    rules = { pattern = 'keymaps', icon = Conf.icons.editor.KEYMAPS, color = 'peach' },
  }),

  {
    'snacks.nvim',
    keys = {
      { '<leader><leader>', picker.files, desc = 'Find Files' },
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
        },

        win = {
          preview = {
            keys = {
              ['<Tab>'] = { 'toggle_preview_focus', mode = { 'i', 'n' } },
              ['<CR>'] = { 'confirm' },

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
          buffers = buffers.source,

          files = {
            hidden = true,
            exclude = { '.DS_Store' },
            config = actions.remembered_preview,
          },

          highlights = {
            layout = 'preview_right',
          },

          keymaps = keymaps.source,

          tabs = tabs.source,
        },
      },
    },
  },
}
