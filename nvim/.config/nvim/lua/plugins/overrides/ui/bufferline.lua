local colors = require("catppuccin.palettes").get_palette("mocha")

local mantle = colors.mantle
local base = colors.base
local text = colors.text
local blue = colors.blue

return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  keys = {
    { "<A-S-h>", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
    { "<A-S-l>", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
    { "<A-S-p>", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
  },
  opts = {
    options = {
      offsets = {
        {
          filetype = "neo-tree",
          text = "File Explorer",
          text_align = "center",
          highlight = "BufferLineOffsetText",
        },
      },

      indicator = {
        style = "underline",
      },
      color_icons = true,
      show_buffer_close_icons = false,
    },

    highlights = vim.tbl_extend(
      "force",
      {
        buffer_visible = {
          bg = base,
          fg = text,
          bold = true,
        },
        separator = {
          fg = mantle,
          bg = mantle,
        },
        background = {
          bg = mantle,
        },
        fill = {
          bg = mantle,
        },

        indicator_visible = {
          fg = base,
          bg = base,
        },
      },
      Util.get_selected_highlights({
        diagnostic_selected = { "hint", "info", "warning", "error" },
        diagnostic = { "modified", "duplicate", "indicator", "buffer" },
      }, blue)
    ),
  },
}
