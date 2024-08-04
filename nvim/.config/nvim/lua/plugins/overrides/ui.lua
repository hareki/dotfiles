local darkest = "#181825"
local dark = "#1e1e2e"
local blue = "#89b4fa"
local gray = "#6c7086"

local function get_selected_highlights(configs)
  local result = {}

  for _, label in ipairs(configs["visible"]) do
    result[label .. "_visible"] = {
      italic = false,
      bold = true,
    }
  end

  for _, label in ipairs(configs["diagnostic_selected"]) do
    result[label .. "_selected"] = {
      italic = false,
    }
    result[label .. "_diagnostic_selected"] = {
      italic = false,
    }
  end

  for _, label in ipairs(configs["selected"]) do
    result[label .. "_selected"] = {
      italic = false,
    }
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
        groups = {
          items = {
            require("bufferline.groups").builtin.pinned:with({ icon = "󰐃 " }),
          },
        },
        offsets = {
          {
            filetype = "neo-tree",
            text = "File Explorer",
            text_align = "center",
            highlight = "BufferLineOffsetText",
          },
        },
        color_icons = true,
        show_buffer_close_icons = false,
      },

      highlights = vim.tbl_extend(
        "force",
        {
          background = {
            bg = darkest,
          },
          fill = {
            bg = darkest,
          },

          indicator_visible = {
            bg = gray,
            fg = gray,
          },
          indicator_selected = {
            bg = blue,
            fg = blue,
          },

          buffer_visible = {
            bg = dark,
            bold = true,
            italic = false,
          },
          buffer_selected = {
            bg = dark,
            fg = blue,
            bold = true,
            italic = false,
          },

          separator = {
            fg = darkest,
            bg = darkest,
          },
        },
        get_selected_highlights({
          diagnostic_selected = { "hint", "info", "warning", "error" },
          visible = { "hint", "info", "warning", "error" },
          selected = { "modified", "duplicate" },
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
