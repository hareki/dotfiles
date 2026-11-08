-- config.builtin-keymaps: Neovim's unused defaults deleted, its global and buffer-local maps
-- retitled in place, and the fold commands described through identity maps

local t = require('tests.lib.helpers')
local builtin_keymaps = require('config.builtin-keymaps')

local GROUP = 'config.builtin-keymaps.retitle-buffer-maps'

-- Run by a `nvim --clean` child: Neovim's own global maps by mode and keytrans() lhs, with
-- `callback` as a boolean and without the raw lhs bytes, so they survive the JSON round trip
local DEFAULTS_SCRIPT = [[
local maps = {}
for _, mode in ipairs({ 'n', 'x', 'o', 'i', 's' }) do
  for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
    maps[mode .. ' ' .. vim.fn.keytrans(map.lhsraw)] = map
    map.callback = map.callback ~= nil
    map.lhs, map.lhsraw, map.lhsrawalt = nil, nil, nil
  end
end
io.stdout:write(vim.json.encode(maps))
os.exit(0)
]]

-- Also run by a `nvim --clean` child: every buffer map with a desc that a Lua ftplugin of
-- Neovim's sets (Vim ftplugins map without descs)
local FTPLUGIN_SCRIPT = [[
local maps = {}
for _, path in ipairs(vim.api.nvim_get_runtime_file('ftplugin/*.lua', true)) do
  local filetype = vim.fn.fnamemodify(path, ':t:r')
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  pcall(function()
    vim.bo[buf].filetype = filetype
  end)
  for _, mode in ipairs({ 'n', 'x', 's', 'o', 'i', 'c', 't' }) do
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
      if map.desc then
        maps[#maps + 1] =
          { filetype = filetype, mode = mode, lhs = vim.fn.keytrans(map.lhsraw), desc = map.desc }
      end
    end
  end
end
io.stdout:write(vim.json.encode(maps))
os.exit(0)
]]

local SECTION_TITLES = {
  ['gO'] = 'Show an Outline of the Current Buffer',
  [']]'] = 'Jump to Next Section',
  ['[['] = 'Jump to Previous Section',
}

--- Run `source` in a fresh `nvim --clean` and decode the JSON it prints
--- @param name string The script's file name, under the boot's private cwd
--- @param source string
--- @return any
local function clean_nvim(name, source)
  local script = vim.fs.joinpath(vim.uv.cwd(), name)
  vim.fn.writefile(vim.split(source, '\n'), script)
  -- Not -l, which sets 'verbose' and so gives each default its script line, unlike this boot
  local luafile = 'luafile ' .. vim.fn.fnameescape(script)
  local cmd = { vim.v.progpath, '--clean', '--headless', '-i', 'NONE', '-c', luafile }
  local result = vim.system(cmd):wait()
  t.eq(result.code, 0, result.stderr)
  return vim.json.decode(result.stdout)
end

--- @type table<string, table>?
local defaults_cache

--- Neovim's own global maps, as a fresh `nvim --clean` defines them
--- @return table<string, table> maps By `<mode> <lhs>`, the lhs as keytrans() spells it
local function neovim_defaults()
  defaults_cache = defaults_cache or clean_nvim('neovim-defaults.lua', DEFAULTS_SCRIPT)
  return defaults_cache
end

--- @param lhs string
--- @return string
local function keytrans(lhs)
  return vim.fn.keytrans(vim.keycode(lhs))
end

--- @param mode string
--- @param lhs string
--- @return table? map
local function global_map(mode, lhs)
  for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
    if vim.fn.keytrans(map.lhsraw) == keytrans(lhs) then
      return map
    end
  end
end

--- @param buf integer
--- @param mode string
--- @param lhs string
--- @return table? map Only a buffer-local one
local function buf_map(buf, mode, lhs)
  for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
    if vim.fn.keytrans(map.lhsraw) == lhs then
      return map
    end
  end
end

--- @param buf integer
--- @param mode string
--- @param lhs string
--- @return string? desc
local function buf_desc(buf, mode, lhs)
  local map = buf_map(buf, mode, lhs)
  return map and map.desc
end

t.test('retitles the global defaults, leaving the rest of each map as Neovim sets it', function()
  local defaults = neovim_defaults()
  for lhs, spec in pairs(builtin_keymaps.DESC_OVERRIDES) do
    for _, mode in ipairs(spec.mode or { 'n' }) do
      local name = string.format('%s %s', mode, keytrans(lhs))
      local expected = vim.deepcopy(t.ok(defaults[name], name .. ' is no Neovim default'))
      local map = t.ok(global_map(mode, lhs), name .. ' is unmapped') --[[@as table]]
      t.eq(map.desc, spec.desc, name)

      local actual = vim.deepcopy(map)
      actual.callback = map.callback ~= nil
      actual.lhs, actual.lhsraw, actual.lhsrawalt = nil, nil, nil
      actual.desc, expected.desc = nil, nil
      t.eq(actual, expected, name)
    end
  end

  -- The retitled ]b still runs Neovim's :bnext
  local first = t.buffer()
  local second = t.buffer()
  vim.api.nvim_set_current_buf(first)
  global_map('n', ']b').callback()
  t.eq(vim.api.nvim_get_current_buf(), second, ']b moves to the next buffer')
  vim.api.nvim_buf_delete(first, { force = true })
  vim.api.nvim_buf_delete(second, { force = true })
end)

t.test('deletes the unused defaults', function()
  local defaults = neovim_defaults()
  for _, lhs in ipairs(builtin_keymaps.UNUSED_DEFAULTS) do
    local name = 'n ' .. keytrans(lhs)
    t.ok(defaults[name], name .. ' is no Neovim default')
    t.eq(global_map('n', lhs), nil, name)
  end
end)

t.test('retitles the help, markdown and checkhealth ftplugin maps', function()
  for _, filetype in ipairs({ 'markdown', 'checkhealth' }) do
    local buf = t.buffer(filetype)
    for lhs, desc in pairs(SECTION_TITLES) do
      t.eq(buf_desc(buf, 'n', lhs), desc, string.format('%s %s', filetype, lhs))
    end
    vim.api.nvim_buf_delete(buf, { force = true })
  end

  vim.cmd.help('help')
  local help = vim.api.nvim_get_current_buf()
  for lhs, desc in pairs(SECTION_TITLES) do
    t.eq(buf_desc(help, 'n', lhs), desc, 'help ' .. lhs)
  end
  vim.cmd.helpclose()

  -- The retitled maps keep the ftplugin's callback and flags, in their own buffer
  local buf = t.buffer('markdown', { '# One', 'text', '# Two' })
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  buf_map(buf, 'n', ']]').callback()
  t.eq(vim.api.nvim_win_get_cursor(0)[1], 3, ']] jumps to the next heading')
  t.eq(buf_map(buf, 'n', 'gO').silent, 1, 'gO stays silent')
  t.eq(global_map('n', ']]'), nil, 'no global ]] appeared')
  vim.api.nvim_buf_delete(buf, { force = true })
end)

t.test("has a title for each map with a desc that Neovim's ftplugins set", function()
  local maps = clean_nvim('ftplugin-maps.lua', FTPLUGIN_SCRIPT)
  t.ok(#maps > 0, 'no ftplugin sets a map with a desc')
  for _, map in ipairs(maps) do
    local name = string.format('%s %s %s %q', map.filetype, map.mode, map.lhs, map.desc)
    local spec = t.ok(builtin_keymaps.BUFFER_DESC_OVERRIDES[map.desc], name .. ' has no title')
    t.eq(spec.lhs, map.lhs, name)
    t.ok(vim.list_contains(spec.mode or { 'n' }, map.mode), name .. ' is retitled in other modes')
  end
end)

t.test('retitles the nvim-pack and terminal maps in each of their modes', function()
  local pack = t.buffer('nvim-pack')
  for _, mode in ipairs({ 'n', 'x' }) do
    t.eq(buf_desc(pack, mode, ']]'), 'Next Plugin', mode .. ' ]]')
    t.eq(buf_desc(pack, mode, '[['), 'Previous Plugin', mode .. ' [[')
  end
  vim.api.nvim_buf_delete(pack, { force = true })

  local term = t.buffer()
  local job = vim.fn.jobstart({ 'cat' }, { term = true })
  for _, mode in ipairs({ 'n', 'x', 'o' }) do
    t.eq(buf_desc(term, mode, ']]'), 'Jump [count] Shell Prompts Forward', mode .. ' ]]')
    t.eq(buf_desc(term, mode, '[['), 'Jump [count] Shell Prompts Backward', mode .. ' [[')
  end
  vim.fn.jobstop(job)
  vim.api.nvim_buf_delete(term, { force = true })
end)

t.test("leaves another buffer-local map on Neovim's key its own title", function()
  -- Like a plugin's FileType handler, created before the module's (setup() re-creates that one)
  local group = vim.api.nvim_create_augroup('tests.builtin-keymaps.reference-jump', {})
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = 'markdown',
    callback = function(event)
      vim.keymap.set('n', ']]', '<Nop>', { buf = event.buf, desc = 'Next Reference' })
    end,
  })
  builtin_keymaps.setup()

  local buf = t.buffer('markdown')
  t.eq(buf_desc(buf, 'n', ']]'), 'Next Reference', 'on FileType')
  t.eq(buf_desc(buf, 'n', '[['), 'Jump to Previous Section', 'the ftplugin map beside it')

  -- The sweep over existing buffers matches on the desc too
  builtin_keymaps.setup()
  t.eq(buf_desc(buf, 'n', ']]'), 'Next Reference', 'after a sweep')

  vim.api.nvim_del_augroup_by_id(group)
  vim.api.nvim_buf_delete(buf, { force = true })
end)

t.test('retitles the buffers whose maps came before it was applied', function()
  -- Before VeryLazy, as for a file passed on the command line
  vim.api.nvim_del_augroup_by_name(GROUP)
  local hidden = t.buffer('markdown')
  local current = t.buffer('checkhealth')
  t.eq(buf_desc(hidden, 'n', ']]'), 'Jump to next section', "Neovim's own title until then")

  builtin_keymaps.setup()
  t.eq(buf_desc(hidden, 'n', ']]'), 'Jump to Next Section', 'a hidden buffer')
  t.eq(buf_desc(current, 'n', ']]'), 'Jump to Next Section', 'the current buffer')

  local events = vim.tbl_map(function(autocmd)
    return autocmd.event
  end, vim.api.nvim_get_autocmds({ group = GROUP }))
  table.sort(events)
  t.eq(events, { 'FileType', 'TermOpen' }, 'one handler per event after a second setup()')

  vim.api.nvim_buf_delete(hidden, { force = true })
  vim.api.nvim_buf_delete(current, { force = true })
end)

t.test('describes the fold commands through identity maps', function()
  for _, fold in ipairs(builtin_keymaps.FOLD_DESCS) do
    local map = t.ok(global_map('n', fold[1]), fold[1] .. ' is unmapped') --[[@as table]]
    t.eq({ map.rhs, map.noremap, map.desc }, { fold[1], 1, fold[2] }, fold[1])
  end

  -- The which-key preset's z group carries the same descs
  local wk_config = require('which-key.config')
  for _, fold in ipairs(builtin_keymaps.FOLD_DESCS) do
    local described = vim.iter(wk_config.mappings):any(function(mapping)
      return mapping.mode == 'n' and mapping.lhs == fold[1] and mapping.desc == fold[2]
    end)
    t.ok(described, 'which-key ' .. fold[1])
  end
end)
