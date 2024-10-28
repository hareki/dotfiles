return {
  "Bekaboo/dropbar.nvim",
  lazy = false,
  -- optional, but required for fuzzy finder support
  dependencies = {
    "nvim-telescope/telescope-fzf-native.nvim",
  },
  keys = {
    { "<leader>d", "<cmd>lua require('dropbar.api').pick()<cr>", desc = "Dropbar pick" },
  },
  opts = {
    -- icons = {
    --   kinds = {
    --     symbols = {
    --       Folder = "",
    --     },
    --   },
    -- },

    -- https://github.com/Bekaboo/dropbar.nvim?tab=readme-ov-file#bar
    -- intercept and limit the lsp items to avoid too deeply nested items
    bar = {
      truncate = false,
      hover = false,
      sources = function(buf, _)
        local sources = require("dropbar.sources")

        if vim.bo[buf].ft == "markdown" then
          return {
            sources.path,
            sources.markdown,
          }
        end
        if vim.bo[buf].buftype == "terminal" then
          return {
            sources.terminal,
          }
        end

        -- Completely disable LSP items for now, since I don't use it

        -- local lsp_item_limit = 3
        -- local utils = require("dropbar.utils")
        return {
          sources.path,
        }

        -- local lsp_sources = utils.source.fallback({
        --   sources.lsp,
        --   sources.treesitter,
        -- })
        -- local orig_get_symbols = lsp_sources.get_symbols
        --
        -- lsp_sources.get_symbols = function(...)
        --   local symbols = orig_get_symbols(...)
        --   return { unpack(symbols, 1, math.min(#symbols, lsp_item_limit)) }
        -- end
        --
        -- return {
        --   sources.path,
        --   lsp_sources,
        -- }
      end,
    },

    sources = {
      path = {
        relative_to = function()
          return Util.get_initial_path()
        end,
      },
    },
  },
}
