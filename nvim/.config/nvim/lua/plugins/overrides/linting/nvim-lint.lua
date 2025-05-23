return {
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      table.insert(opts.ensure_installed, "eslint_d")
    end,
  },

  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      Util.define(opts, "linters_by_ft")
      for _, ft in ipairs(Constant.filetype.ESLINT_SUPPORTED) do
        opts.linters_by_ft[ft] = opts.linters_by_ft[ft] or {}
        table.insert(opts.linters_by_ft[ft], "eslint_d")
      end
    end,
  },
}
