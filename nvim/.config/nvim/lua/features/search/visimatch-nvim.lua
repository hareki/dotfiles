return {
  'wurli/visimatch.nvim',
  event = 'ModeChanged *:[vV\22]*', -- v, V, <C-v> (\22 is the raw CTRL-V byte)

  opts = function()
    return {
      chars_lower_limit = 2,
      hl_group = 'DocumentHighlight',
    }
  end,
}
