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
  -- TODO: the dropbar gets really crowded if the project is deeply nested. Need to find a config to limit the nested level
  -- {
  --   "Bekaboo/dropbar.nvim",
  --   enabled = false,
  -- },
  -- {
  --   "nvim-treesitter/nvim-treesitter-context",
  --   enabled = false
  -- },

  -- NOTE: currently testing yanky.nvim and nvim-neoclip
  -- {
  --   "gbprod/yanky.nvim",
  --   enabled = false
  -- },
  {
    "AckslD/nvim-neoclip.lua",
    enabled = false
  }
}
