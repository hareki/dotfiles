---@class blink-cmp.config.completion
local M = {}

M.default = {
  accept = { auto_brackets = { enabled = false } },
  ghost_text = { enabled = false },
  trigger = {
    prefetch_on_insert = false,
    show_on_backspace = true,
    show_on_backspace_after_insert_enter = true,
    show_on_insert = true,
    show_on_keyword = true,
    show_in_snippet = true,
  },
  list = {
    selection = {
      preselect = true,
      -- Super-tab config: https://github.com/Saghen/blink.cmp/blob/242fd1f31dd619ccb7fa7b5895e046ad675b411b/doc/configuration/keymap.md#super-tab
      -- preselect = function()
      --   return not require('blink.cmp').snippet_active({ direction = 1 })
      -- end,
      auto_insert = false,
    },
  },
  documentation = {
    auto_show = true,
    auto_show_delay_ms = 200,
    window = { border = 'rounded' },
  },
  menu = {
    border = 'rounded',
    scrollbar = false,
    max_height = 15,
    draw = {
      padding = { 1, 0 }, -- For some reason it already has 1 padding on the right
      columns = {
        { 'kind_icon' },
        { 'label', 'label_description', gap = 1 },
      },
      components = {
        label = {
          width = { fill = false, max = 20 },
        },
        label_description = {
          width = { max = 20 },
        },
      },
    },
  },
}

M.cmdline = {
  menu = { auto_show = false },
  ghost_text = { enabled = false },
  list = {
    selection = {
      preselect = true,
      auto_insert = false,
    },
  },
}

return M
