return {
  {
    "gbprod/yanky.nvim",
    dependencies = {
      { "kkharji/sqlite.lua" },
    },
    opts = {
      ring = { storage = "sqlite" },
      highlight = {
        -- Use our own aucmd to highlight on yank instead, to differentiate between clipboard and register yank
        on_yank = false,

        on_put = true,
        timer = Constant.yanky.PUT_HL_TIMER,
      },
      system_clipboard = {
        sync_with_ring = false,
        clipboard_register = nil,
      },
    },

    keys = {
      { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank Text" },
      { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put Text After Cursor" },
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
  },
}
