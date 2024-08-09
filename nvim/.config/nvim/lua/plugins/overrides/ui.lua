local colors = require("catppuccin.palettes").get_palette("mocha")

local mantle = colors.mantle
local base = colors.base
local text = colors.text
local blue = colors.blue

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
  },

  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local icons = LazyVim.config.icons

      -- opts.options.section_separators = { left = "", right = "" }
      -- opts.options.component_separators = { left = "|", right = "|" }

      opts.options.section_separators = { left = "", right = "" }
      opts.options.component_separators = { left = "", right = "" }

      -- opts.sections.lualine_y[0].color = { bg = mantle }
      -- opts.sections.lualine_y[1].color = { bg = mantle }

      opts.sections.lualine_y = {
        {
          "diagnostics",
          symbols = {
            error = icons.diagnostics.Error,
            warn = icons.diagnostics.Warn,
            info = icons.diagnostics.Info,
            hint = icons.diagnostics.Hint,
          },
          always_visible = true,
          color = { bg = mantle },
        },
      }

      opts.sections.lualine_z = {
        { "location", separator = "x" },
        { "progress" },

        -- { "progress", separator = "" },
        -- { "location" },
      }
    end,
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
