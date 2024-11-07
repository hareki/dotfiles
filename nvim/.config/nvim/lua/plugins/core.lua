return {
  -- Always use the latest version
  -- https://www.lazyvim.org/configuration/lazy.nvim
  {
    "hareki/LazyVim",
    version = false,
    opts = function(_, opts)
      opts.colorscheme = "catppuccin-mocha"
      Util.ensure_nested(opts, "icons.kinds")[Constant.yanky.CMP_KIND] = "󰅍 "
      -- Util.ensure_nested_table(opts, "defaults").keymaps = false
    end,
  },
  -- { "folke/lazy.nvim", version = false },
}
