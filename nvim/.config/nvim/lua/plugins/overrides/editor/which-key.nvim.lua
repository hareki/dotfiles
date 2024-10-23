return {
  {
    "folke/which-key.nvim",
    -- enabled = false,
    opts = {
      -- ... other configurations ...

      -- triggers = {
      --   -- Only trigger which-key in normal, visual, and select modes
      --   { "<auto>", mode = "nxs" },
      -- },

      ---@param ctx { mode: string, operator: string }
      -- defer = function(ctx)
      --   -- LazyVim.notify(vim.inspect(ctx))
      --   return vim.list_contains({ "<C-V>", "V", "v" }, ctx.mode)
      --   -- return false
      --   -- Defer which-key when changing modes or when an operator is pending
      --   -- Prevents the popup from showing immediately during these times
      --   -- return ctx.mode ~= "n" or ctx.operator ~= nil
      -- end,
    },
  },
}
