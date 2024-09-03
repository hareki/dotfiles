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

  -- Use function instead to remove reundant keymaps that I never use from LazyVim
  keys = function()
    return {
      {
        "<leader>p",
        function()
          if LazyVim.pick.picker.name == "telescope" then
            require("telescope").extensions.yank_history.yank_history({})
          else
            vim.cmd([[YankyRingHistory]])
          end
        end,
        mode = { "n", "x" },
        desc = "Open Yank History",
      },
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
    }
  end,
}
