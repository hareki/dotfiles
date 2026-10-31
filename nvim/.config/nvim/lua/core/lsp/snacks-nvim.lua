return {
  'snacks.nvim',
  opts = {
    words = {
      enabled = true,
      -- Hide references while search matches show; UI.color.nohlsearch() brings them back
      filter = function()
        return not UI.color.search_highlighted()
      end,
    },
  },
}
