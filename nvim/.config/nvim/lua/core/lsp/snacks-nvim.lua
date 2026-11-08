return {
  'snacks.nvim',
  opts = {
    words = {
      enabled = true,
      -- Hide references while search matches show; UI.search.clear() brings them back
      filter = function()
        return not UI.search.is_active()
      end,
    },
  },
}
