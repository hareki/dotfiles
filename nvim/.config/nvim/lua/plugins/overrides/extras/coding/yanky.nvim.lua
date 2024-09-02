return {
  "gbprod/yanky.nvim",
  dependencies = {
    { "kkharji/sqlite.lua" },
  },
  opts = {
    ring = { storage = "sqlite" },
    highlight = {
      on_yank = false,
      on_put = true,
      timer = Constant.YANK_PUT_HL_TIMER,
    },
    system_clipboard = {
      sync_with_ring = false,
      clipboard_register = nil,
    },
  },
  keys = {
    {
      "p",
      '"_d<Plug>(YankyPutBefore)',
      mode = { "x" },
      desc = "Put yanked text after cursor without overwriting register",
    },

    {
      "P",
      '"0<Plug>(YankyPutBefore)',
      mode = { "n" },
      desc = "Put yanked text after cursor without overwriting register",
    },
    {
      "P",
      '"_d"0<Plug>(YankyPutBefore)',
      mode = { "x" },
      desc = "Put yanked text after cursor without overwriting register",
    },

    {
      "<c-p>",
      "<Plug>(YankyPreviousEntry)",
      desc = "Select previous entry through yank history",
    },
    {
      "<c-n>",
      "<Plug>(YankyNextEntry)",
      desc = "Select next entry through yank history",
    },
  },
}
