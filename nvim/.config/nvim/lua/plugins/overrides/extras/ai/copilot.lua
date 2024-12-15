return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "AndreM222/copilot-lualine", "zbirenbaum/copilot.lua" },
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, 2, { "copilot" })
    end,
  },
}
