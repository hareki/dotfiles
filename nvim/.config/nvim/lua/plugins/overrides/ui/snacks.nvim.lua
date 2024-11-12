return {
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        win = {
          position = "float",
          border = "rounded",
          backdrop = 100,
          size = { width = 0.7, height = 0.7 },
          title = " Terminal ",
          title_pos = "center",
        },
      },
      notifier = {
        width = { min = 40, max = 40 },
        margin = { top = 1, right = 1, bottom = 0 },
      },
    },
  },
}
