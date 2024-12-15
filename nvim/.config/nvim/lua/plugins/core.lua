-- https://www.lazyvim.org/configuration/lazy.nvim
return {
  {
    "hareki/LazyVim",
    version = false,
    opts = function(_, opts)
      return vim.tbl_deep_extend("force", opts, {
        icons = {
          kinds = {
            Folder = "󰉋 ",
            [Constant.yanky.CMP_KIND] = "󰅍 ",
          },
        },
      })
    end,
  },

  {
    "folke/lazy.nvim",
    version = false,
  },
}
