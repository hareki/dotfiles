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
    -- "hrsh7th/cmp-calc",
    -- "chrisgrieser/cmp_yanky",
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

    -- table.insert(opts.sources, {
    --   name = "calc",
    -- })

    -- table.insert(opts.sources, {
    --   name = "cmp_yanky",
    --   priority = 20,
    --   max_item_count = 3,
    --   option = {
    --     minLength = 3,
    --   },
    -- })

    opts.formatting = opts.formatting or {}
    local format_original = opts.formatting.format or function(entry, item)
      return item
    end

    opts.formatting.format = function(entry, item)
      if entry.source.name == "cmp_yanky" then
        -- Assign a custom kind and hl group for cmp_yanky before passing it to format_original
        item.kind = Constant.yanky.CMP_KIND
        item.kind_hl_group = "CmpItemKindClass"
      end
      return format_original(entry, item)
    end
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

    -- Force a UI redraw to fix the invisible text issues when autocompleting
    -- https://github.com/folke/noice.nvim/issues/942#issuecomment-2316297562
    local feedkeys = vim.api.nvim_feedkeys
    local termcodes = vim.api.nvim_replace_termcodes
    local function feed_space_backspace()
      feedkeys(termcodes(" <BS>", true, false, true), "n", true)
    end

    cmp.event:on("confirm_done", function()
      vim.schedule(feed_space_backspace)
    end)
  end,
}
