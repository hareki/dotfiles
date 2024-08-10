return {
  {
    "https://gitlab.com/HiPhish/rainbow-delimiters.nvim",
  },
  {
    "Bekaboo/dropbar.nvim",
    lazy = false,
    -- optional, but required for fuzzy finder support
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
    },
    keys = {
      { "<leader>d", "<cmd>lua require('dropbar.api').pick()<cr>", desc = "Dropbar pick" },
    },
    opts = {
      sources = {
        path = {
          relative_to = function()
            return Util.get_initial_path()
          end,
        },
      },
    },
  },
}
