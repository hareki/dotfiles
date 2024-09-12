-- NOTE: just a clone of https://www.lazyvim.org/extras/lang/tailwind#nvim-lspconfig
-- plus the classRegex
return {
  "neovim/nvim-lspconfig",
  opts = {
    setup = {
      tailwindcss = function(_, opts)
        local tw = require("lspconfig.server_configurations.tailwindcss")
        opts.filetypes = opts.filetypes or {}

        -- Add default filetypes
        vim.list_extend(opts.filetypes, tw.default_config.filetypes)

        -- Remove excluded filetypes
        --- @param ft string
        opts.filetypes = vim.tbl_filter(function(ft)
          return not vim.tbl_contains(opts.filetypes_exclude or {}, ft)
        end, opts.filetypes)

        -- Additional settings for Phoenix projects
        opts.settings = {
          tailwindCSS = {
            includeLanguages = {
              elixir = "html-eex",
              eelixir = "html-eex",
              heex = "html-eex",
            },

            experimental = {
              classRegex = {
                "`tw([^`]*)", -- `tw ...`
                "'tw([^']*)", -- 'tw ...'
                '"tw([^"]*)', -- "tw ..."
              },
            },
          },
        }

        -- Add additional filetypes
        vim.list_extend(opts.filetypes, opts.filetypes_include or {})
      end,
    },
  },
}
