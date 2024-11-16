return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      Snacks.config.style("terminal", {
        position = "float",
        title = " Terminal ",
        title_pos = "center",
        border = "rounded",
        backdrop = 100,
        width = 0.8,
        height = 0.8,
      })

      Snacks.config.style("notification.history", {
        title = " Notification History ",
      })

      Snacks.config.style("blame_line", {
        height = 0.4,
      })

      opts.notifier = {
        margin = { top = 1, right = 1, bottom = 0 },
      }
    end,
  },
}
