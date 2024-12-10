return {
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      opts.win = {
        border = "rounded",
        padding = { 1, 3 }, -- extra window padding [top/bottom, right/left]
      }
      opts.defer = function(ctx)
        return vim.list_contains({ "<C-V>", "V", "v" }, ctx.mode)
      end

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

      local icons = LazyVim.config.icons.diagnostics

      opts.spec = vim.list_extend(disabled_spec, {
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
    end,
  },
}
