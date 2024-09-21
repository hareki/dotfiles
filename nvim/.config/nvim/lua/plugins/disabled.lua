return {
  -- NOTE: don't use
  {
    "folke/tokyonight.nvim",
    enabled = false,
  },
  -- NOTE: don't use
  {
    "indent-blankline.nvim",
    enabled = false,
  },
  -- NOTE: use Comment.nvim
  {
    "folke/ts-comments.nvim",
    enabled = false,
  },
  -- NOTE: use LuaSnip for now since there're some advanced vscode snippet style neovim can't parse them right now (eg. us - useState from friendly-snippets)
  -- https://github.com/neovim/neovim/issues/25696
  {
    "garymjr/nvim-snippets",
    enabled = false,
  },
  -- NOTE: just copy whatever we like to prevent snippets from bombarding the cmp menu
  {
    "rafamadriz/friendly-snippets",
    enabled = false,
  },
}
