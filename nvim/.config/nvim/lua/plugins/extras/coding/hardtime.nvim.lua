return {
  {
    "hareki/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    lazy = false,
    opts = {},
    -- https://github.com/m4xshen/hardtime.nvim/issues/31
    keys = {
      { "j", 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"' },
      { "k", 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"' },
      { "<Up>", "<Up>" },
      { "<Down>", "<Down>" },
    },
  },
}
