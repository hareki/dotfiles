local null_ls = require("null-ls")

local config = {
  find_json = function()
    return vim.fn.expand("~") .. '/.config/cspell.json'
  end,
}
return {
  "nvimtools/none-ls.nvim",
  dependencies = {
    "davidmh/cspell.nvim",
  },
  config = function()
    local cspell = require("cspell")
    null_ls.setup({
      sources = {
        cspell.diagnostics.with({
          -- https://www.reddit.com/r/neovim/comments/zyv7pi/nullls_warning_level_for_sources/
          -- Force the severity to be HINT
          diagnostics_postprocess = function(diagnostic)
            diagnostic.severity = vim.diagnostic.severity.INFO
          end,
          config = config
        }),
        cspell.code_actions.with({
          config = config
        }),
      },
    })
  end,

  keys = {
    {
      "<leader>uS",
      function()
        local cspell_query = { name = "cspell" }
        local cspell_active = not null_ls.get_source(cspell_query)[1]._disabled

        local next_cspell_active = not cspell_active
        local notify = next_cspell_active and LazyVim.info or LazyVim.warn
        notify(Util.toggle_notify.run("cspell", next_cspell_active), { title = "cspell" })

        null_ls.toggle(cspell_query)
      end,
      desc = "Toggle cspell",
    },
  },
}
