local cmp = require("cmp")

return {
  {
    "hrsh7th/nvim-cmp",
    event = {
      "InsertEnter",
      "CmdlineEnter",
    },
    dependencies = {
      "hrsh7th/cmp-cmdline",
      "dmitmel/cmp-cmdline-history",
      "hrsh7th/cmp-calc",
      "f3fora/cmp-spell",
    },
    opts = function(_, opts)
      opts.window = {
        -- documentation = cmp.config.window.bordered(),
        -- completion = cmp.config.window.bordered(),

        completion = {
          border = "rounded",
          -- CursorLine is the currently selected item
          winhighlight = "Normal:CmpNormal,CursorLine:PmenuSel",
        },
        documentation = {
          border = "rounded",
          winhighlight = "Normal:CmpNormal",
          -- winhighlight = "Normal:CmpNormal,FloatBorder:CmpItemKindConstant",
        },
      }

      table.insert(opts.sources, {
        name = "spell",
        option = {
          keep_all_entries = false,
          enable_in_context = function()
            return true
          end,
          preselect_correct_word = true,
          -- not sure if it's working, but whatever
          max_item_count = 5,
        },
      })

      table.insert(opts.sources, {
        name = "calc",
      })
    end,
    init = function()
      local mapping = cmp.mapping.preset.cmdline()
      -- `/` cmdline setup.
      cmp.setup.cmdline("/", {
        mapping = mapping,
        sources = cmp.config.sources({
          { name = "buffer" },
        }),
      })

      -- `:` cmdline setup.
      cmp.setup.cmdline(":", {
        mapping = mapping,
        sources = cmp.config.sources({
          { name = "path" },
          {
            name = "cmdline",
            option = {
              ignore_cmds = { "Man", "!" },
            },
          },
          { name = "cmdline_history", max_item_count = 5, keyword_length = 5 },
        }),
      })
    end,
  },
}
