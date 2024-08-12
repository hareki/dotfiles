-- if false then
--   return {
--     "mfussenegger/nvim-lint",
--     opts = {
--       linters_by_ft = {
--         ["*"] = { "cspell" },
--       },
--     },
--   }
-- end

return {
  "nvimtools/none-ls.nvim",
  dependencies = {
    "davidmh/cspell.nvim",
  },
  config = function()
    local cspell = require("cspell")
    require("null-ls").setup({
      sources = {
        cspell.diagnostics.with({
          -- https://www.reddit.com/r/neovim/comments/zyv7pi/nullls_warning_level_for_sources/
          -- Force the severity to be HINT
          diagnostics_postprocess = function(diagnostic)
            diagnostic.severity = vim.diagnostic.severity.HINT
          end,
        }),
        cspell.code_actions,
      },
    })
  end,
}
