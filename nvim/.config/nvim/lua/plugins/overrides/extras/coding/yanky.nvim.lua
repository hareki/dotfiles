return {
  {
    "gbprod/yanky.nvim",
    dependencies = {
      { "kkharji/sqlite.lua" },
    },
    opts = function(_, opts)
      Util.hls({
        YankyPut = { link = "YankRegisterHighlight" },
        -- We use aucmds to dynamically switch hl colors instead
        -- YankyYanked = { link = "YankRegisterHighlight" },
      })

      return vim.tbl_deep_extend("force", opts, {
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
      })
    end,

    keys = {
      { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank text" },
      { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put text after cursor" },
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
        "<A-p>",
        "<Plug>(YankyPreviousEntry)",
        desc = "Select previous entry through yank history",
      },
      {
        "<A-n>",
        "<Plug>(YankyNextEntry)",
        desc = "Select next entry through yank history",
      },
    },
  },
}
