local filetypes = Conf.Filetypes.with_tags

return {
  'tronikelis/ts-autotag.nvim',
  ft = filetypes,
  opts = function()
    return {
      auto_rename = {
        enabled = true,
      },
      filetypes = filetypes,
    }
  end,
}
