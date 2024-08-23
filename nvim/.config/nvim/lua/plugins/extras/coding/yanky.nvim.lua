-- NOTE: disabled
return {
  "gbprod/yanky.nvim",
  dependencies = {
    { "kkharji/sqlite.lua" }
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
    { "<leader>p", function() require("telescope").extensions.yank_history.yank_history({}) end, desc = "Open Yank History" },
    { "y",         "<Plug>(YankyYank)",                                                          mode = { "n", "x" },                                desc = "Yank text" },
    { "p",         '<Plug>(YankyPutAfter)',                                                      mode = { "n", "x" },                                desc = "Put yanked text after cursor without overwriting register" },
    { "<c-p>",     "<Plug>(YankyPreviousEntry)",                                                 desc = "Select previous entry through yank history" },
    { "<c-n>",     "<Plug>(YankyNextEntry)",                                                     desc = "Select next entry through yank history" },
  },
}
