local builtin = require("telescope.builtin")

-- Unify the preview title for all pickers
local picker_config = {}
for picker_name, _ in pairs(builtin) do
  picker_config[picker_name] = {
    preview_title = Constant.PREVIEW_TITLE,
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
    pickers = picker_config,
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
          height = 0.8,
          preview_height = 0.5,
          preview_cutoff = 1, -- Preview should always show (unless previewer = false)
          prompt_position = "top",
          width = 0.6,
        },
      },
    },
  },
}
