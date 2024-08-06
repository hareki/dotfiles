local darkest = "#181825"
local dark = "#1E1E2E"
local white = "#CDD6F4"
local blue = "#89B4FA"

local function get_selected_highlights(configs)
  local result = {}

  local visible_highlights = {
    bold = true,
  }

  local diagnostic_selected_highlights = {
    italic = false,
    sp = blue,
  }

  local selected_highlights = {
    italic = false,
    sp = blue,
  }

  for _, label in ipairs(configs["diagnostic_selected"]) do
    result[label .. "_visible"] = visible_highlights
    result[label .. "_selected"] = selected_highlights
    result[label .. "_diagnostic_selected"] = diagnostic_selected_highlights
  end

  for _, label in ipairs(configs["diagnostic"]) do
    result[label .. "_visible"] = visible_highlights
    result[label .. "_selected"] = selected_highlights
  end

  return result
end

return {
  {
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
            bg = dark,
            fg = white,
            bold = true,
          },
          separator = {
            fg = darkest,
            bg = darkest,
          },
          background = {
            bg = darkest,
          },
          fill = {
            bg = darkest,
          },

          indicator_visible = {
            fg = dark,
            bg = dark,
          },
        },
        get_selected_highlights({
          diagnostic_selected = { "hint", "info", "warning", "error" },
          diagnostic = { "modified", "duplicate", "indicator", "buffer" },
        })
      ),
    },
  },

  {
    "folke/noice.nvim",
    opts = {
      presets = {
        bottom_search = false,
        command_palette = false,
      },
      views = {
        cmdline_popup = {
          position = {
            row = 11,
            col = "50%",
          },
          size = {
            width = 60,
            height = "auto",
          },
        },
      },
    },
  },

  {
    "nvimdev/dashboard-nvim",
    opts = function(_, opts)
      local logo = [[
   ██╗  ██╗  █████╗  ██████╗  ███████╗ ██╗  ██╗ ██╗
   ██║  ██║ ██╔══██╗ ██╔══██╗ ██╔════╝ ██║ ██╔╝ ██║
   ███████║ ███████║ ██████╔╝ █████╗   █████╔╝  ██║
   ██╔══██║ ██╔══██║ ██╔══██╗ ██╔══╝   ██╔═██╗  ██║
   ██║  ██║ ██║  ██║ ██║  ██║ ███████╗ ██║  ██╗ ██║
   ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚══════╝ ╚═╝  ╚═╝ ╚═╝
    ]]
      logo = string.rep("\n", 6) .. logo .. "\n"
      opts.theme = "hyper"
      opts.config = {
        header = vim.split(logo, "\n"),
        center = {},
        shortcut = {
          { desc = "󰊳 Update", group = "@property", action = "Lazy update", key = "u" },
          {
            icon = ":u6709: ",
            icon_hl = "@variable",
            desc = "Files",
            group = "Label",
            action = "Telescope find_files",
            key = "f",
          },
          {
            desc = " Apps",
            group = "DiagnosticHint",
            action = "Telescope app",
            key = "a",
          },
          {
            desc = " dotfiles",
            group = "Number",
            action = "Telescope dotfiles",
            key = "d",
          },
        },
      }
    end,
  },
}
