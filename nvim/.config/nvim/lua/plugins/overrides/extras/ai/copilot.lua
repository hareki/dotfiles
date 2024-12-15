return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "AndreM222/copilot-lualine", "zbirenbaum/copilot.lua" },
    opts = function(_, opts)
      -- remove the component from extras: https://www.lazyvim.org/extras/ai/copilot#lualinenvim-optional
      table.remove(opts.sections.lualine_x, 2)

      -- use copilot-lualine instead
      table.insert(opts.sections.lualine_x, 2, { "copilot" })
    end,
  },
}
