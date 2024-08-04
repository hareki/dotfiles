local bg_color = "#181825"
local bg_selected = "#1E1E2E"
local fg_selected = "#CDD6F4"
local blue = "#89B4FA"

local function get_selected_highlights(configs)
  local result = {}

  -- First nested table: labels that should generate diagnostic variants
  for _, label in ipairs(configs[1]) do
    -- Base configuration
    result[label .. "_selected"] = {
      italic = false,
      sp = blue,
    }
    -- Diagnostic variant
    result[label .. "_diagnostic_selected"] = {
      italic = false,
      sp = blue,
    }
  end

  -- Second nested table: labels that should not generate diagnostic variants
  for _, label in ipairs(configs[2]) do
    -- Base configuration
    result[label .. "_selected"] = {
      italic = false,
      sp = blue,
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
        indicator = {
          style = "underline",
        },
        offsets = {
          {
            filetype = "neo-tree",
            -- text = "File Explorer",
            text = "",
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
          buffer_visible = {
            bg = bg_selected,
            fg = fg_selected,
          },
          separator = {
            fg = bg_color,
            bg = bg_color,
          },
          indicator_visible = {
            fg = bg_color,
            bg = bg_color,
          },
          indicator_selected = {
            fg = bg_color,
            bg = bg_color,
            sp = bg_color,
          },
          background = {
            bg = bg_color,
          },
          fill = {
            bg = bg_color,
          },
        },
        get_selected_highlights({
          { "hint", "info", "warning", "error" },
          -- { "modified", "duplicate", "indicator", "buffer" },
          { "modified", "duplicate", "buffer" },
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
