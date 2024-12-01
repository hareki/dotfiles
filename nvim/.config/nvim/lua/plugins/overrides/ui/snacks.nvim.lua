return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      local lg_size = Constant.ui.popup_size.lg
      local xl_size = Constant.ui.popup_size.xl

      Snacks.config.style("terminal", {
        position = "float",
        title = " Terminal ",
        title_pos = "center",
        border = "rounded",
        backdrop = 100,
        width = lg_size.WIDTH,
        height = lg_size.HEIGHT,
      })

      Snacks.config.style("notification.history", {
        title = " Notification History ",
        backdrop = 100,
        width = lg_size.WIDTH,
        height = lg_size.HEIGHT,
      })

      Snacks.config.style("blame_line", {
        height = 0.4,
      })

      Snacks.config.style("lazygit", {
        title = " Lazygit ",
        width = xl_size.WIDTH,
        height = xl_size.HEIGHT,
      })

      opts.notifier = {
        margin = { top = 1, right = 1, bottom = 0 },
      }
      opts.dashboard.enabled = false
    end,
  },
}
