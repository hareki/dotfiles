return {
  'aznhe21/actions-preview.nvim',
  opts = {
    telescope = {
      preview_title = Constant.telescope.PREVIEW_TITLE,
      layout_config = {
        vertical = Util.telescope.layout_config('sm'),
      },
    },
  },
}
