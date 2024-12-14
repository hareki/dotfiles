return {
  {
    "lukas-reineke/virt-column.nvim",
    opts = function(_, opts)
      local palette = Util.get_palette()

      Util.highlight("VirtColumn", {
        fg = palette.surface0,
      })

      return vim.tbl_deep_extend("force", opts, {
        char = "│",
        virtcolumn = "80",
        highlight = "VirtColumn",
      })
    end,
  },
}
