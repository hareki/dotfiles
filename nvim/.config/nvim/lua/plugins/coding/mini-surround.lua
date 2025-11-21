local mappings = {
  add = 'sa', -- Add surrounding
  delete = 'sd', -- Delete surrounding
  replace = 'sr',
}
return {
  'echasnovski/mini.surround',
  event = 'VeryLazy',
  keys = {
    { mappings.add, desc = 'Mini Surround: Add', mode = { 'x' } },
    { mappings.delete, desc = 'Mini Surround: Delete', mode = { 'x' } },
    { mappings.replace, desc = 'Mini Surround: Replace', mode = { 'n' } },
  },
  opts = {
    mappings = mappings,
  },
}
