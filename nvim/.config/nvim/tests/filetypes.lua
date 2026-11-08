-- config.filetypes and config.filetypes.languages as an edited file meets them: the rules name
-- its filetype, and the language aliases, which nvim-treesitter registers once it loads, pick its
-- parser

local t = require('tests.lib.helpers')

t.test('an mdx file gets the mdx filetype and the markdown parser', function()
  local buf = t.file('docs/intro.mdx', { '# Getting started', '', 'Install it with `pnpm add`' })
  t.eq(vim.bo[buf].filetype, 'mdx', 'filetype')

  t.wait_for(function()
    return vim.b[buf].ts_highlight == true
  end, 'treesitter to start on the buffer')
  local parser = assert(vim.treesitter.get_parser(buf), 'no parser for the buffer')
  t.eq(parser:lang(), 'markdown', 'parser language')
  vim.cmd.bwipeout({ bang = true })
end)
