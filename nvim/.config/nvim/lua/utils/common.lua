--- @class utils.common
local M = {}

--- @param fn fun()
function M.noautocmd(fn)
  local ei = vim.o.eventignore
  vim.o.eventignore = 'all'
  local ok, err = pcall(fn)
  vim.o.eventignore = ei
  if not ok then
    error(err, 0)
  end
end

local function repaint_render_markdown(win_id)
  local render_md = require('render-markdown')
  if not vim.api.nvim_win_is_valid(win_id) then
    return
  end

  M.noautocmd(function()
    vim.api.nvim_win_call(win_id, function()
      -- buf_enable scopes to the float's buffer; enable() would flip the
      -- plugin's global state and force-render every attached buffer
      render_md.buf_enable()
    end)
  end)
end

local function is_markdown_buf(win_id)
  local buf = vim.api.nvim_win_get_buf(win_id)
  return vim.list_contains(Conf.filetypes.MARKDOWN, vim.bo[buf].filetype)
end

--- Focus a window without triggering autocommands
--- If current window is a floating markdown preview, repaint it after focus change.
--- @param win integer | nil Window handle to focus (0/nil returns false)
--- @return boolean success
function M.focus_win(win)
  if not win or win == 0 or not vim.api.nvim_win_is_valid(win) then
    return false
  end

  local src = vim.api.nvim_get_current_win()
  local need_repaint = Snacks.util.is_float(src) and is_markdown_buf(src)

  M.noautocmd(function()
    vim.api.nvim_set_current_win(win)
  end)

  if need_repaint then
    repaint_render_markdown(src)
  end

  return true
end

--- Buffer-local `vim.keymap.set` sharing one opts table, with an optional desc prefix
--- @param buf integer
--- @param opts? vim.keymap.set.Opts | { prefix?: string }
--- @return fun(mode: string | string[], lhs: string | string[], rhs: string | function, desc: string) map
function M.buf_mapper(buf, opts)
  local base = vim.tbl_extend('force', opts or {}, { buffer = buf })
  local prefix = base.prefix or ''
  base.prefix = nil

  return function(mode, lhs, rhs, desc)
    if type(lhs) == 'string' then
      lhs = { lhs }
    end
    local keymap_opts = vim.tbl_extend('force', base, { desc = prefix .. desc })
    for _, key in ipairs(lhs) do
      vim.keymap.set(mode, key, rhs, keymap_opts)
    end
  end
end

--- Snapshot a buffer's own mapping, in the maparg() form restore_buf_keymap reinstates
--- @param buf integer
--- @param mode string
--- @param lhs string
--- @return table | nil map nil when the buffer is invalid or has no buffer-local mapping for lhs
function M.get_buf_keymap(buf, mode, lhs)
  if not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end

  return vim.api.nvim_buf_call(buf, function()
    local map = vim.fn.maparg(lhs, mode, false, true)
    return map.buffer == 1 and map or nil
  end)
end

--- Reinstate a mapping captured by get_buf_keymap; mapset() keeps its Lua
--- callback, desc and flags intact
--- @param buf integer
--- @param mode string
--- @param map table
--- @return nil
local function restore_buf_keymap(buf, mode, map)
  vim.api.nvim_buf_call(buf, function()
    vim.fn.mapset(mode, false, map)
  end)
end

--- @class utils.common.KeymapLayer
--- @field rhs string | function
--- @field opts vim.keymap.set.Opts

--- Popup overrides per buffer-local key, oldest first; `base` is the buffer's own
--- mapping from before the first override (nil when the key was unmapped)
--- @type table<string, { base: table?, layers: utils.common.KeymapLayer[] }>
local override_stacks = {}

--- Map keys on a buffer while a popup lives; overrides of a key stack, so releasing one in any
--- order keeps the newest remaining one active, or restores the buffer's own mapping
--- @param buf integer
--- @param maps { [1]: string | string[], [2]: string, [3]: string | function, [4]?: vim.keymap.set.Opts }[] Mode(s), lhs, rhs and opts of each override
--- @return fun() release Undoes every override of this call; later calls are no-ops
function M.override_buf_keymaps(buf, maps)
  --- @type { key: string, mode: string, lhs: string, layer: utils.common.KeymapLayer }[]
  local pushed = {}

  for _, map in ipairs(maps) do
    local modes, lhs, rhs, opts = map[1], map[2], map[3], map[4]
    if type(modes) == 'string' then
      modes = { modes }
    end
    local layer = { rhs = rhs, opts = vim.tbl_extend('force', opts or {}, { buffer = buf }) }

    for _, mode in ipairs(modes) do
      local key = string.format('%d %s %s', buf, mode, lhs)
      override_stacks[key] = override_stacks[key]
        or { base = M.get_buf_keymap(buf, mode, lhs), layers = {} }
      table.insert(override_stacks[key].layers, layer)
      vim.keymap.set(mode, lhs, rhs, layer.opts)
      pushed[#pushed + 1] = { key = key, mode = mode, lhs = lhs, layer = layer }
    end
  end

  local released = false
  return function()
    if released then
      return
    end
    released = true

    for _, entry in ipairs(pushed) do
      local stack = override_stacks[entry.key]
      local was_active = stack.layers[#stack.layers] == entry.layer
      for index, layer in ipairs(stack.layers) do
        if layer == entry.layer then
          table.remove(stack.layers, index)
          break
        end
      end

      local top = stack.layers[#stack.layers]
      if not top then
        override_stacks[entry.key] = nil
      end

      -- A newer override still covering this one keeps its mapping active
      if was_active and vim.api.nvim_buf_is_valid(buf) then
        if top then
          vim.keymap.set(entry.mode, entry.lhs, top.rhs, top.opts)
        elseif stack.base then
          restore_buf_keymap(buf, entry.mode, stack.base)
        else
          pcall(vim.keymap.del, entry.mode, entry.lhs, { buffer = buf })
        end
      end
    end
  end
end

--- @class utils.common.LinkPopupOpts
--- @field name string Popup name for the keymap descriptions
--- @field modes? string | string[] Modes to map (default 'n')
--- @field focus_popup? fun() Focus the popup instead of the default autocmd-free switch
--- @field before_focus? fun(target: 'popup' | 'source') Runs before either focus switch, e.g. so the plugin ignores the CursorMoved it causes
--- @field esc_passthrough? boolean Have the source window's <Esc> also do what it does without the popup (e.g. the global Clear Highlight)

--- Link a popup to the current window: <Tab> toggles focus between them, <Esc> closes the popup
--- from either side (q too, inside it), and the source buffer's overrides go once it closes
--- @param popup_win integer
--- @param opts utils.common.LinkPopupOpts
--- @return nil
function M.link_popup(popup_win, opts)
  local source_win = vim.api.nvim_get_current_win()
  -- Already linked when it opened: gitsigns focuses an open popup rather than opening another
  if popup_win == source_win then
    return
  end

  local modes = opts.modes or 'n'
  local popup_buf = vim.api.nvim_win_get_buf(popup_win)
  local close_desc = 'Close ' .. opts.name

  local function close()
    pcall(vim.api.nvim_win_close, popup_win, true)
  end

  --- @param target 'popup' | 'source'
  local function focus(target)
    if opts.before_focus then
      opts.before_focus(target)
    end

    if target == 'source' then
      M.focus_win(source_win)
    elseif opts.focus_popup then
      opts.focus_popup()
    else
      M.focus_win(popup_win)
    end
  end

  --- @param lhs string
  --- @param rhs function
  --- @param desc string
  local function map_popup(lhs, rhs, desc)
    vim.keymap.set(modes, lhs, rhs, { buffer = popup_buf, nowait = true, desc = desc })
  end

  map_popup('q', close, close_desc)
  map_popup('<Esc>', close, close_desc)
  map_popup('<Tab>', function()
    focus('source')
  end, 'Focus Source Window')

  local group = vim.api.nvim_create_augroup('utils.common.link-popup-' .. popup_win, {
    clear = true,
  })
  local release_source_maps

  local function release()
    pcall(vim.api.nvim_del_augroup_by_id, group)
    release_source_maps()
  end

  release_source_maps = M.override_buf_keymaps(vim.api.nvim_win_get_buf(source_win), {
    {
      modes,
      '<Esc>',
      function()
        close()
        if opts.esc_passthrough then
          -- Released first, so the replayed key reaches what the override covered
          release()
          vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'm', false)
        end
      end,
      { desc = close_desc, nowait = true },
    },
    {
      modes,
      '<Tab>',
      function()
        focus('popup')
      end,
      { desc = string.format('Focus %s Window', opts.name), nowait = true },
    },
  })

  vim.api.nvim_create_autocmd('WinClosed', {
    group = group,
    pattern = tostring(popup_win),
    callback = release,
  })
  -- A popup closed inside a non-nested autocmd (eagle closes on CmdlineEnter) fires no
  -- WinClosed, so also check whenever Nvim is about to wait for input
  vim.api.nvim_create_autocmd('SafeState', {
    group = group,
    callback = function()
      if not vim.api.nvim_win_is_valid(popup_win) then
        release()
      end
    end,
  })
end

return M
