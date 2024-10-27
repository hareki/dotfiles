local builtin = require("telescope.builtin")

-- Unify the preview title for all pickers
local picker_config = {}
for picker_name, _ in pairs(builtin) do
  picker_config[picker_name] = {
    preview_title = Constant.telescope.PREVIEW_TITLE,
  }
end

-- NOTE:
-- Define a custom layout based on "vertical", the point is to merge prompt and results windows
-- In general, this layout mimics the "dropdown" theme, but take the "previewer" panel into account of the height layout
-- https://www.reddit.com/r/neovim/comments/10asvod/telescopenvim_how_to_remove_windows_titles_and/
require("telescope.pickers.layout_strategies").vertical_merged = function(picker, max_columns, max_lines, layout_config)
  local layout = require("telescope.pickers.layout_strategies").vertical(picker, max_columns, max_lines, layout_config)
  layout.results.line = layout.results.line - 1
  layout.results.height = layout.results.height + 1
  return layout
end

return {
  "nvim-telescope/telescope.nvim",
  opts = {
    pickers = vim.tbl_extend("force", picker_config, {
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
          height = 0.9,
          preview_height = 0.6,
          preview_cutoff = 1, -- Preview should always show (unless previewer = false)
          prompt_position = "top",
          width = 0.6,
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
  },
  keys = function(_, keys)
    local mappings = {
      { "<leader>sB", "<cmd>Telescope git_branches<cr>", desc = "Git Branches" },
    }

    for _, key in ipairs({ "L", "H" }) do
      table.insert(mappings, {
        key,
        "<cmd>Telescope buffers initial_mode=normal<cr>",
        desc = "Telescope Buffers",
      })
    end

    return vim.list_extend(keys, mappings)
  end,
}
