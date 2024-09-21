-- if true then
--   return {}
-- end

return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    opts.formatters_by_ft = opts.formatters_by_ft or {}
    for _, ft in ipairs(Constant.ESLINT_SUPPORTED) do
      opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
      table.insert(opts.formatters_by_ft[ft], "eslint_d")
    end
  end,
}
