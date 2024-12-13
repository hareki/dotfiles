return {
  {
    "L3MON4D3/LuaSnip",
    opts = function()
      require("luasnip.loaders.from_vscode").lazy_load({ paths = "~/.config/nvim/snippets" })
    end,
  },
}
