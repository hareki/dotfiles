return {
  {
    "folke/which-key.nvim",
    opts = {
      defer = function(ctx)
        return vim.list_contains({ "<C-V>", "V", "v" }, ctx.mode)
      end,
    },
  },
}
