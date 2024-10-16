local disabled_plugins = {
  -- NOTE: Built-in, don't use:
  "folke/tokyonight.nvim",
  "indent-blankline.nvim",

  -- NOTE: use Comment.nvim
  "folke/ts-comments.nvim",

  -- NOTE: use LuaSnip for now since there're some advanced vscode snippet style neovim can't parse them right now (eg. us - useState from friendly-snippets)
  -- https://github.com/neovim/neovim/issues/25696
  "garymjr/nvim-snippets",

  -- NOTE: just copy whatever we like to prevent snippets from bombarding the cmp menu
  "rafamadriz/friendly-snippets",

  -- NOTE: looking for alternatives (typos?) since I don't like the none-ls oververheads
  "nvimtools/none-ls.nvim",
  "davidmh/cspell.nvim",

  -- NOTE: let's see if I feel uncomfortable without this plugin... Since I don't use it that much
  "leafo/magick",
  "hareki/image.nvim",

  -- NOTE: currently experiencing using lazygit only
  "NeogitOrg/neogit",
  "sindrets/diffview.nvim",

  -- NOTE: let's see if I feel uncomfortable without this plugin... Since I don't use it that much
  "rachartier/tiny-inline-diagnostic.nvim",
}

-- Generate the table with plugins disabled
return vim.tbl_map(function(plugin)
  return { plugin, enabled = false }
end, disabled_plugins)
