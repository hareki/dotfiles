return {
  {
    "folke/which-key.nvim",
    opts = {
      win = {
        border = "rounded",
        padding = { 1, 4 }, -- extra window padding [top/bottom, right/left]
      },
      defer = function(ctx)
        return vim.list_contains({ "<C-V>", "V", "v" }, ctx.mode)
      end,
    },
  },
}
