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
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "chrisgrieser/cmp_yanky",
    },
    opts = function(_, opts)
      table.insert(opts.sources, {
        name = "cmp_yanky",
        priority = 20,
        max_item_count = 3,
        option = {
          minLength = 3,
        },
      })

      opts.formatting = opts.formatting or {}
      local format_original = opts.formatting.format or function(entry, item)
        return item
      end

      opts.formatting.format = function(entry, item)
        if entry.source.name == "cmp_yanky" then
          -- Assign a custom kind and hl group for cmp_yanky before passsing it to format_original
          item.kind = Constant.CMP_YANKY_KIND
          item.kind_hl_group = "CmpItemKindClass"
        end
        return format_original(entry, item)
      end
    end,
  },
}
