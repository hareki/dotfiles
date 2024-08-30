local cmp = require("cmp")

return {
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
    "brenoprata10/nvim-highlight-colors",

    --NOTE: This is from https://www.lazyvim.org/extras/coding/copilot, I just want a little bit more control over it (disable the default lualine copilot)
    {
      "zbirenbaum/copilot-cmp",
      dependencies = "copilot.lua",
      opts = {},
      config = function(_, opts)
        local copilot_cmp = require("copilot_cmp")
        copilot_cmp.setup(opts)
        -- attach cmp source whenever copilot attaches
        -- fixes lazy-loading issues with the copilot cmp source
        LazyVim.lsp.on_attach(function(client)
          copilot_cmp._on_insert_enter({})
        end, "copilot")
      end,
    },
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

    table.insert(opts.sources, 1, {
      name = "copilot",
      group_index = 1,
      priority = 100,
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
}
