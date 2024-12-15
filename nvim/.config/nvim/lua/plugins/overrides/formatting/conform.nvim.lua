return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    Util.define(opts, "formatters_by_ft")
    for _, ft in ipairs(Constant.filetype.ESLINT_SUPPORTED) do
      opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
      table.insert(opts.formatters_by_ft[ft], "eslint_d")
    end
  end,
}
