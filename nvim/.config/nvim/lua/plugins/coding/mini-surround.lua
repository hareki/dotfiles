local mappings = {
  add = 'sa', -- Add surrounding
  delete = 'sd', -- Delete surrounding
}
return {
  'echasnovski/mini.surround',
  lazy = true,
  keys = {
    { 's', '<nop>', mode = { 'x' }, desc = 'Mini Surround: Start' },
    { mappings.add, desc = 'Mini Surround: Add', mode = { 'x' } },
    { mappings.delete, desc = 'Mini Surround: Delete', mode = { 'x' } },
  },
  opts = {
    mappings = mappings,
  },
}
