return {
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      local icons = LazyVim.config.icons.diagnostics
      local hidden_keymaps = {
        "[(",
        "[{",
        "[<",
        "[%",
        "[m",
        "[M",

        "](",
        "]{",
        "]<",
        "]%",
        "]m",
        "]M",
      }
      local disabled_spec = {}
      for _, keymap in ipairs(hidden_keymaps) do
        table.insert(disabled_spec, { keymap, hidden = true })
      end

      local custom_spec = vim.list_extend(disabled_spec, {
        {
          "[s",
          desc = "Misspelled word",
          icon = "",
        },
        {
          "]s",
          desc = "Misspelled word",
          icon = "",
        },
        {
          "[i",
          desc = "Indent scope start",
        },
        {
          "]i",
          desc = "Indent scope bottom",
        },
        { "[e", icon = { icon = icons.Error, hl = "DiagnosticError" } },
        { "]e", icon = { icon = icons.Error, hl = "DiagnosticError" } },

        { "[w", icon = { icon = icons.Warn, hl = "DiagnosticWarn" } },
        { "]w", icon = { icon = icons.Warn, hl = "DiagnosticWarn" } },

        { "[d", icon = { icon = icons.Info, hl = "DiagnosticInfo" } },
        { "]d", icon = { icon = icons.Info, hl = "DiagnosticInfo" } },
      })

      return vim.tbl_deep_extend("force", opts, {
        preset = "classic",
        spec = vim.list_extend(opts.spec or {}, custom_spec),
        win = {
          border = "rounded",
          padding = { 1, 3 }, -- [top/bottom, right/left] the actual horizontal padding will be +3 the value, not sure why
        },

        -- Don't show which-key when first entering visual mode
        defer = function(ctx)
          return vim.list_contains({ "<C-V>", "V", "v" }, ctx.mode)
        end,
      })
    end,
  },
}
