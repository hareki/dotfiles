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

      opts.options.section_separators = { left = "", right = "" }
      opts.options.component_separators = { left = "|", right = "|" }

      -- For some reason the so-called support for `neo-tree` is a blank statusline? => remove it for now
      local extensions = opts.extensions
      for i = #extensions, 1, -1 do
        if extensions[i] == "neo-tree" then
          table.remove(extensions, i)
        end
      end

      -- ===== WINBAR ====
      -- opts.options.disabled_filetypes = {
      --   -- winbar = { "neo-tree" },
      --   statusline = { "neo-tree" },
      -- }
      -- local winbar = Util.ensure_nested_table.run(opts, "winbar")
      -- local inactive_winbar = Util.ensure_nested_table.run(opts, "inactive_winbar")
      -- local breadcrumb_component = {}
      --
      -- -- Add back the default component since we're overriding the entire section:
      -- -- https://www.lazyvim.org/plugins/ui#lualinenvim
      -- if vim.g.trouble_lualine and LazyVim.has("trouble.nvim") then
      --   local trouble = require("trouble")
      --   local symbols = trouble.statusline({
      --     mode = "symbols",
      --     groups = {},
      --     title = false,
      --     filter = { range = true },
      --     format = "{kind_icon}{symbol.name:Normal}",
      --     hl_group = "lualine_c_normal",
      --   })
      --   table.insert(breadcrumb_component, {
      --     symbols and symbols.get,
      --     cond = function()
      --       return vim.b.trouble_lualine ~= false and symbols.has()
      --     end,
      --     padding = { left = 1, right = 1 },
      --     color = { bg = "#ff0000", fg = text },
      --   })
      -- end
      --
      -- table.insert(breadcrumb_component, {
      --   "filetype",
      --   icon_only = true,
      --   separator = "",
      --   padding = { left = 1, right = 0 },
      --   color = { bg = mantle, fg = text },
      -- })
      --
      -- table.insert(breadcrumb_component, {
      --   LazyVim.lualine.pretty_path({
      --     relative = "cwd",
      --     length = 0,
      --     filename_hl = "none",
      --   }),
      --   padding = { left = 0, right = 1 },
      --   color = { bg = mantle, fg = text },
      -- })
      --
      -- winbar.lualine_z = breadcrumb_component
      -- inactive_winbar.lualine_z = breadcrumb_component

      -- ===== SECTION B ====
      local function format_branch_name(branch_name)
        -- Length variables for easier maintenance
        local max_task_name_length = 20
        local start_length = 15
        local end_length = 5

        -- Check if the branch name follows the ClickUp format
        local is_clickup_format = branch_name:match("^CU%-%w+_.+_.+$")
        if not is_clickup_format then
          return branch_name
        end

        -- Extract the prefix, task name, and assigner name
        local prefix, task_name, assigner_name = branch_name:match("^(CU%-%w+)_([^_]+)_(.+)$")

        -- Handle the task name formatting
        local formatted_task_name
        if #task_name > max_task_name_length then
          formatted_task_name = task_name:sub(1, start_length) .. "..." .. task_name:sub(-end_length)
        else
          formatted_task_name = task_name
        end

        -- Combine everything to get the final formatted branch name
        local formatted_branch_name = prefix .. "_" .. formatted_task_name .. "_" .. assigner_name

        return formatted_branch_name
      end

      opts.sections.lualine_b = {
        {
          "branch",
          fmt = format_branch_name,
        },
        {
          "diff",
          symbols = {
            added = icons.git.added,
            modified = icons.git.modified,
            removed = icons.git.removed,
          },
          source = function()
            local gitsigns = vim.b.gitsigns_status_dict
            if gitsigns then
              return {
                added = gitsigns.added,
                modified = gitsigns.changed,
                removed = gitsigns.removed,
              }
            end
          end,
        },
      }

      -- ===== SECTION C ====
      opts.sections.lualine_c = {}
      -- opts.sections.lualine_c = {
      --   { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
      --   { LazyVim.lualine.pretty_path(), padding = { left = 0, right = 1 } },
      -- }

      -- -- Add back the default component since we're overriding the entire section:
      -- -- https://www.lazyvim.org/plugins/ui#lualinenvim
      -- if vim.g.trouble_lualine and LazyVim.has("trouble.nvim") then
      --   local trouble = require("trouble")
      --   local symbols = trouble.statusline({
      --     mode = "symbols",
      --     groups = {},
      --     title = false,
      --     filter = { range = true },
      --     format = "{kind_icon}{symbol.name:Normal}",
      --     hl_group = "lualine_c_normal",
      --   })
      --   table.insert(opts.sections.lualine_c, {
      --     symbols and symbols.get,
      --     cond = function()
      --       return vim.b.trouble_lualine ~= false and symbols.has()
      --     end,
      --   })
      -- end

      -- ===== SECTION X ====
      Util.remove_lualine_component("diff", opts.sections.lualine_x)

      -- ===== SECTION Y ====
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
        },
      }

      -- ===== SECTION Z ====
      opts.sections.lualine_z = {
        { "location", padding = { left = 1, right = 1 } },
        { "progress", padding = { left = 1, right = 1 } },
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
