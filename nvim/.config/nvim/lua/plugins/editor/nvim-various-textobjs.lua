return {
  'chrisgrieser/nvim-various-textobjs',
  event = 'LazyFile',
  opts = {
    keymaps = {
      useDefaults = false,
    },
  },
  keys = {
    -- For dot-repeat to work, you have to call the motions as Ex-commands
    { 'aw', '<cmd>lua require("various-textobjs").subword("outer")<CR>', mode = { 'o', 'x' } },
    { 'iw', '<cmd>lua require("various-textobjs").subword("inner")<CR>', mode = { 'o', 'x' } },
  },
}
