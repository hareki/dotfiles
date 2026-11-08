-- tests/ab.sh's payload: what this config defines once every plugin has loaded, as sorted
-- tab-separated rows that a diff compares across two boots

local helpers = require('tests.lib.helpers')
local lazy_config = require('lazy.core.config')
local lazy_plugin = require('lazy.core.plugin')

-- Loading it starts a WebSocket server and writes the ~/.claude/ide lock file Claude Code reads
local NOT_LOADED = { ['claudecode.nvim'] = true }
-- Filetypes whose ftplugins and FileType handlers add buffer-local maps (help is opened for real)
local FILETYPES = { 'markdown', 'checkhealth', 'lua', 'typescript', 'gitcommit', 'json', 'yaml' }
local MODES = { 'n', 'x', 's', 'o', 'i', 'c', 't', 'l' }
local MAP_FLAGS = { 'noremap', 'expr', 'silent', 'nowait', 'script', 'replace_keycodes' }

--- @type string[]
local rows = {}

local function row(...)
  local parts = {}
  for i = 1, select('#', ...) do
    local text = tostring((select(i, ...)))
    parts[i] = text:gsub('\\', '\\\\'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t')
  end
  rows[#rows + 1] = table.concat(parts, '\t')
end

--- @param a any
--- @param b any
local function key_order(a, b)
  local ta, tb = type(a), type(b)
  if ta ~= tb then
    return ta < tb
  end
  if ta == 'number' or ta == 'string' then
    return a < b
  end
  return tostring(a) < tostring(b)
end

--- One row per leaf, at its path (`icons.rules[3].pattern`)
--- @param section string
--- @param name string
--- @param value any
--- @param path? string
--- @param seen? table<table, true> Tables on the current path, for cycles
local function flatten(section, name, value, path, seen)
  path = path or ''
  seen = seen or {}

  if type(value) == 'table' then
    if seen[value] then
      return row(section, name, path, '<cycle>')
    end
    local keys = vim.tbl_keys(value)
    if #keys == 0 then
      return row(section, name, path, '{}')
    end
    seen[value] = true
    table.sort(keys, key_order)
    for _, key in ipairs(keys) do
      local sub = type(key) == 'number' and string.format('%s[%d]', path, key)
        or (path == '' and tostring(key) or path .. '.' .. tostring(key))
      flatten(section, name, value[key], sub, seen)
    end
    seen[value] = nil
    return
  end

  local text
  if type(value) == 'string' then
    text = vim.inspect(value)
  elseif type(value) == 'function' then
    text = '<function>'
  elseif value == vim.NIL then
    text = 'vim.NIL'
  elseif type(value) == 'userdata' then
    text = '<userdata>'
  else
    text = tostring(value)
  end
  row(section, name, path, text)
end

--- @param section string
--- @param mode string
--- @param map table A dict from nvim_get_keymap
local function map_row(section, mode, map)
  local flags = {}
  for _, flag in ipairs(MAP_FLAGS) do
    if map[flag] == 1 or map[flag] == true then
      flags[#flags + 1] = flag
    end
  end
  row(
    section,
    mode,
    vim.fn.keytrans(map.lhsraw or map.lhs),
    map.desc or '',
    map.callback and '<callback>' or (map.rhs or ''),
    table.concat(flags, ',')
  )
end

--- @param label string
--- @param buf integer
local function buffer_maps(label, buf)
  for _, mode in ipairs(MODES) do
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
      map_row('bufmap:' .. label, mode, map)
    end
  end
end

-- Startup path, before VeryLazy and the loads below
for _, module in ipairs(helpers.startup_modules) do
  row('startup-module', module)
end

local names = {}
for name, plugin in pairs(lazy_config.plugins) do
  if plugin._.installed and not NOT_LOADED[name] then
    names[#names + 1] = name
  end
end
table.sort(names)
local lazy = require('lazy')
lazy.load({ plugins = names })
helpers.settle(500)

-- Global state, read before the buffers below change the current window
-- Path lists sorted: lazy.nvim's load order decides theirs
local PATH_LISTS = { runtimepath = true, packpath = true }
for name in pairs(vim.api.nvim_get_all_options_info()) do
  local ok, value = pcall(vim.api.nvim_get_option_value, name, { scope = 'global' })
  if ok and PATH_LISTS[name] then
    local entries = vim.split(value, ',', { plain = true })
    table.sort(entries)
    value = table.concat(entries, ',')
  end
  row('option', name, ok and vim.inspect(value) or '<error>')
end
for _, name in ipairs(vim.fn.getcompletion('g:', 'var')) do
  flatten('g', name, vim.g[name:sub(3)])
end
for _, mode in ipairs(MODES) do
  for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
    map_row('map', mode, map)
  end
end

for _, filetype in ipairs(FILETYPES) do
  local buf = helpers.buffer(filetype)
  helpers.settle(50)
  buffer_maps(filetype, buf)
end
vim.cmd.help('help')
helpers.settle(50)
buffer_maps('help', vim.api.nvim_get_current_buf())

for name, attrs in pairs(vim.api.nvim_get_hl(0, {})) do
  flatten('hl', name, attrs)
end

for _, autocmd in ipairs(vim.api.nvim_get_autocmds({})) do
  row(
    'autocmd',
    autocmd.group_name or '',
    autocmd.event,
    autocmd.pattern or '',
    autocmd.once and 'once' or '',
    autocmd.desc or '',
    autocmd.command ~= '' and autocmd.command or (autocmd.callback and '<callback>' or '')
  )
end

for name, command in pairs(vim.api.nvim_get_commands({ builtin = false })) do
  row(
    'command',
    name,
    command.nargs,
    command.range or '',
    command.bang and 'bang' or '',
    command.complete or '',
    command.definition or ''
  )
end

for name in pairs(vim.api.nvim_get_namespaces()) do
  row('namespace', name)
end

for name, plugin in pairs(lazy_config.plugins) do
  row('plugin', name, 'lazy', tostring(plugin.lazy), plugin._.loaded and 'loaded' or 'not loaded')
  for _, field in ipairs({ 'event', 'ft', 'cmd', 'dependencies', 'priority', 'enabled', 'cond' }) do
    if plugin[field] ~= nil then
      flatten('plugin', name, plugin[field], field)
    end
  end
  flatten('plugin', name, lazy_plugin.values(plugin, 'keys', true), 'keys')
  if plugin._.loaded then
    flatten('plugin-opts', name, lazy_plugin.values(plugin, 'opts', false))
  end
end
for name in pairs(lazy_config.spec.disabled) do
  row('plugin-disabled', name)
end

for name in pairs(vim.lsp._enabled_configs) do
  local ok, config = pcall(function()
    return vim.lsp.config[name]
  end)
  flatten('lsp', name, ok and config or '<error>')
end

flatten('diagnostic', 'config', vim.diagnostic.config())

local ok_wk, wk_config = pcall(require, 'which-key.config')
if ok_wk then
  for _, mapping in ipairs(wk_config.mappings) do
    -- idx numbers the specs in registration order
    local fields = vim.tbl_extend('force', {}, mapping, { idx = vim.NIL })
    flatten('which-key', string.format('%s %s', mapping.mode or '', mapping.lhs or ''), fields)
  end

  -- The icon which-key gives each normal-mode map, from its desc
  local wk_icons = require('which-key.icons')
  for _, map in ipairs(vim.api.nvim_get_keymap('n')) do
    if map.desc then
      local icon, hl = wk_icons.get({ keys = map.lhs, desc = map.desc })
      row(
        'which-key-icon',
        vim.fn.keytrans(map.lhsraw or map.lhs or ''),
        map.desc,
        icon or '',
        hl or ''
      )
    end
  end
end

-- Boot-to-boot noise, dropped or normalized: private dir paths, tostring() addresses, lualine's
-- group numbers (creation order), noice's route order (from pairs()) and LSP command-line pids

--- Plain-text substitutions, longest path first, each in its given, normalized and resolved form
--- @type { [1]: string, [2]: string }[]
local substitutions = {}
local cache_home = assert(vim.env.XDG_CACHE_HOME)
for _, pair in ipairs({
  { assert(vim.env.NVIM_TEST_CONFIG), '<config>' },
  { cache_home, '<cache>' },
  { assert(vim.env.XDG_STATE_HOME), '<state>' },
  { assert(vim.uv.cwd()), '<cwd>' },
  { vim.fs.dirname(vim.fs.dirname(cache_home)), '<tmp>' },
}) do
  local path, placeholder = pair[1], pair[2]
  local forms = { path, vim.fs.normalize(path), vim.uv.fs_realpath(path) }
  for _, form in ipairs(vim.list.unique(forms)) do
    substitutions[#substitutions + 1] = { vim.pesc(form), placeholder }
  end
end
local pid = tostring(vim.fn.getpid())

for i, text in ipairs(rows) do
  for _, sub in ipairs(substitutions) do
    text = text:gsub(sub[1], sub[2])
  end
  text = text:gsub('(%a+): 0x%x+', '<%1>')
  text = text:gsub('lualine_[%w_]+', function(group)
    return (group:gsub('_%d+', '_N'))
  end)
  text = text:gsub('^(plugin%-opts\tnoice%.nvim\troutes)%[%d+%]', '%1[*]')
  if vim.startswith(text, 'lsp\t') then
    text = text:gsub('%f[%d]' .. pid .. '%f[%D]', '<pid>')
  end
  rows[i] = text
end

table.sort(rows)
-- Not inline: assert returns its message too, which writefile would read as flags
local out_path = assert(vim.env.NVIM_TEST_OUT, 'NVIM_TEST_OUT is unset')
vim.fn.writefile(rows, out_path)
