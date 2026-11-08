--- @class features.completion.blink-cmp.config.completion
local M = {}

M.default = {
  accept = { auto_brackets = { enabled = false } },
  -- https://github.com/saghen/blink.cmp/blob/main/doc/configuration/reference.md#completion-trigger
  trigger = {
    show_on_backspace_after_insert_enter = false,
  },
  list = {
    selection = {
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
    max_height = vim.o.pumheight,
    draw = {
      -- No right padding: the label's gap before an empty label_description already leaves slack
      padding = { 1, 0 },
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
      auto_insert = false,
    },
  },
}

return M
