local lg_size = Constant.ui.popup_size.lg
return {
  {
    "hareki/mason.nvim",
    opts = {
      ui = {
        border = "rounded",
        width = lg_size.WIDTH,
        height = lg_size.HEIGHT,
        title = " Mason ",
        title_pos = "center",
      },
    },
  },
}
