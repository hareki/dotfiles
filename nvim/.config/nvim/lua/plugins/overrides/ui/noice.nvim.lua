return {
  "folke/noice.nvim",
  opts = {
    presets = {
      bottom_search = false,
      command_palette = false,
    },
    views = {
      cmdline_popup = {
        position = {
          row = 11,
          col = "50%",
        },
        size = {
          width = 60,
          height = "auto",
        },
      },
    },
    routes = {
      {
        -- Ignore null-ls messages since it's just cspell
        filter = {
          event = "lsp",
          kind = "progress",
          cond = function(message)
            local client = vim.tbl_get(message.opts, "progress", "client")
            return client == "null-ls"
          end,
        },
        opts = { skip = true },
      },

      {
        filter = {
          event = "msg_show",
          any = {
            { find = "%d+L, %d+B" },
            { find = "; after #%d+" },
            { find = "; before #%d+" },
          },
        },
        opts = { skip = true }
      },
    },
  },
}
