return {
  'kevinhwang91/nvim-ufo',
  event = 'LazyFile',
  dependencies = { 'kevinhwang91/promise-async' },
  opts = {
    -- https://github.com/kevinhwang91/nvim-ufo/blob/1ebb9ea3507f3a40ce8b0489fb259ab32b1b5877/README.md?plain=1#L97
    provider_selector = function()
      return { 'treesitter', 'indent' }
    end,
  },
}
