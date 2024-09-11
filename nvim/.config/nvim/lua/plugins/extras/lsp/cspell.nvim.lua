local null_ls = require("null-ls")

local config = {
  find_json = function()
    return vim.fn.expand("~") .. "/.config/cspell.json"
  end,
}
return {
  {
    "nvimtools/none-ls.nvim",
    lazy = true,
    dependencies = {
      {
        "davidmh/cspell.nvim",
        -- This is not really needed since it matches another condition to be lazy-loaded anyway,
        -- but just in case there's change in the future
        lazy = true,
      },
    },
    config = function()
      local cspell = require("cspell")
      null_ls.setup({
        sources = {
          cspell.diagnostics.with({
            -- https://www.reddit.com/r/neovim/comments/zyv7pi/nullls_warning_level_for_sources/
            -- Force the severity to be HINT
            diagnostics_postprocess = function(diagnostic)
              diagnostic.severity = vim.diagnostic.severity.HINT
            end,
            config = config,
          }),
          cspell.code_actions.with({
            config = config,
          }),
        },
      })
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "f3fora/cmp-spell",
    },
    opts = function(_, opts)
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
    end,
  },
}