return {
  "mfussenegger/nvim-lint",
  opts = function(_, opts)
    opts.linters_by_ft = opts.linters_by_ft or {}
    for _, ft in ipairs(Constant.ESLINT_SUPPORTED) do
      opts.linters_by_ft[ft] = opts.linters_by_ft[ft] or {}
      table.insert(opts.linters_by_ft[ft], "eslint_d")
    end
  end,
}
