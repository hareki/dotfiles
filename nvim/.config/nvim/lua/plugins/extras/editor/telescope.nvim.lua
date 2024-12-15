return {
  {
    "nvim-telescope/telescope.nvim",
    opts = function(_, opts)
      local layout_strategies = require("telescope.pickers.layout_strategies")
      local builtin = require("telescope.builtin")
      local lg_size = Constant.ui.popup_size.lg

      -- Unify the preview title for all pickers
      local default_picker_configs = {}
      for picker_name, _ in pairs(builtin) do
        default_picker_configs[picker_name] = {
          preview_title = Constant.telescope.PREVIEW_TITLE,
        }
      end

      -- Define a custom layout based on "vertical", the point is to merge prompt and results windows
      -- In general, this layout mimics the "dropdown" theme, but take the "previewer" panel into account of the height layout
      -- https://www.reddit.com/r/neovim/comments/10asvod/telescopenvim_how_to_remove_windows_titles_and/
      layout_strategies.vertical_merged = function(picker, max_columns, max_lines, layout_config)
        local layout = layout_strategies.vertical(picker, max_columns, max_lines, layout_config)
        layout.results.line = layout.results.line - 1
        layout.results.height = layout.results.height + 1
        return layout
      end

      return vim.tbl_deep_extend("force", opts, {
        pickers = vim.tbl_deep_extend("force", default_picker_configs, {
          buffers = {
            select_current = true,
            preview_title = Constant.telescope.PREVIEW_TITLE,
            --https://github.com/nvim-telescope/telescope.nvim/issues/1145#issuecomment-903161099
            mappings = {
              n = {
                ["x"] = require("telescope.actions").delete_buffer,
              },
            },
          },
        }),

        defaults = {
          prompt_prefix = "   ",
          results_title = false,
          -- Merge prompt and results windows
          -- https://github.com/nvim-telescope/telescope.nvim/blob/5972437de807c3bc101565175da66a1aa4f8707a/lua/telescope/themes.lua#L50
          borderchars = {
            prompt = { "─", "│", " ", "│", "╭", "╮", "│", "│" },
            results = { "─", "│", "─", "│", "├", "┤", "╯", "╰" },
            preview = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
          },
          layout_strategy = "vertical_merged",

          -- Make results appear from top to bottom
          -- https://github.com/nvim-telescope/telescope.nvim/issues/1933
          sorting_strategy = "ascending",

          layout_config = {
            vertical = {
              mirror = true,

              -- Unify height and width to match other large popups by compensating for different size calculation methods
              height = lg_size.HEIGHT + 0.1,
              width = lg_size.WIDTH + 0.015,

              preview_height = 0.6,
              preview_cutoff = 1, -- Preview should always show (unless previewer = false)
              prompt_position = "top",
            },
          },
          mappings = {
            i = {
              ["<c-q>"] = function(...)
                require("telescope.actions").send_to_qflist(...)
                require("trouble").open("quickfix")
              end,
            },
          },
        },
      })
    end,

    keys = function(_, keys)
      local mappings = {
        { "<leader>sB", "<cmd>Telescope git_branches<cr>", desc = "Git branches" },
      }

      for _, key in ipairs({ "L", "H" }) do
        table.insert(mappings, {
          key,
          "<cmd>Telescope buffers initial_mode=normal<cr>",
          desc = "Telescope buffers",
        })
      end

      return vim.list_extend(keys, mappings)
    end,
  },
}
