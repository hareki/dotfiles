local mappings = {
  add = 'sa', -- Add surrounding
  delete = 'sd', -- Delete surrounding
}
return {
  'echasnovski/mini.surround',
  lazy = true,
  keys = {
    { 's', '<nop>', mode = { 'x' } },
    { mappings.add, desc = 'Add Surrounding', mode = { 'x' } },
    { mappings.delete, desc = 'Delete Surrounding', mode = { 'x' } },
  },
  opts = {
    mappings = mappings,
  },
}
