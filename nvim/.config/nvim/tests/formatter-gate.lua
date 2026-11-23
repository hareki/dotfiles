-- The prettier gate in features/formatting/conform-nvim/init.lua: conform lists prettier for a file
-- outside an oxfmt project and leaves it out inside one, as the style enforcer's conform step asks
-- it (style-enforcer/conform-nvim.lua). The gate reads nvim-lspconfig's oxfmt root_dir, which calls
-- back before it returns; one that called back later would fail the oxfmt cases here

local t = require('tests.lib.helpers')

--- The formatters conform would run on a file, written at `path` under the boot's cwd
--- @param path string
--- @return string[]
local function formatters_for(path)
  local conform = require('conform')
  local buf = t.file(path, { 'const a = 1' })
  return vim.tbl_map(function(formatter)
    return formatter.name
  end, (conform.list_formatters_to_run(buf)))
end

t.test('prettier formats a file outside an oxfmt project', function()
  t.eq(formatters_for('plain/src/app.ts'), { 'prettier' })
end)

t.test('a .oxfmtrc.json above the file leaves prettier out', function()
  t.write('oxfmt-rc/.oxfmtrc.json', { '{}' })
  t.eq(formatters_for('oxfmt-rc/src/app.ts'), {})
end)

t.test('a package.json naming oxfmt above the file leaves prettier out', function()
  t.write('oxfmt-package/package.json', { '{ "devDependencies": { "oxfmt": "^0.1.0" } }' })
  t.eq(formatters_for('oxfmt-package/src/app.ts'), {})
end)

t.test('a package.json without oxfmt keeps prettier', function()
  t.write('other-package/package.json', { '{ "devDependencies": { "typescript": "^5.0.0" } }' })
  t.eq(formatters_for('other-package/src/app.ts'), { 'prettier' })
end)
