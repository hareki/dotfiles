return {
  {
    "hareki/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    lazy = false,
    opts = {
      hints = {
        ["ggVG[dcy=<>]"] = {
          message = function(keys)
            return "Use " .. keys:sub(5, 5) .. "ig instead of " .. keys
          end,
          length = 5,
        },
      },
    },
    -- https://github.com/m4xshen/hardtime.nvim/issues/31
    keys = {
      { "j", 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"' },
      { "k", 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"' },
      { "<Up>", "<Up>" },
      { "<Down>", "<Down>" },
    },
  },
}
