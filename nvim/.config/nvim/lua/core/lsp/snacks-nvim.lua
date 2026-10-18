return {
  'snacks.nvim',
  opts = {
    words = {
      enabled = true,
      -- Hide references while search matches are highlighted, so the two
      -- don't mix; UI.color.nohlsearch() brings them back
      filter = function(buf)
        return not UI.color.search_highlighted()
          and vim.g.snacks_words ~= false
          and vim.b[buf].snacks_words ~= false
      end,
    },
  },
}
