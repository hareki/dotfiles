local cursorline = require('utils.ui.cursorline')
local keymap = require('utils.keymap')
local noautocmd = require('utils.noautocmd')

--- Floats tied to a source window: focus hand-off, linked keys, closing once the source moves on
--- @class utils.popup
local M = {}

--- Focus a window without triggering autocommands, doing what the skipped events would have: the
--- cursorline hand-off and, for a floating markdown preview, its repaint
--- @param win integer
--- @return boolean success
function M.focus_win(win)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end

  local src = vim.api.nvim_get_current_win()
  local src_buf = vim.api.nvim_win_get_buf(src)
  local filetypes = require('config.filetypes.groups')
  local need_repaint = vim.api.nvim_win_get_config(src).relative ~= ''
    and vim.list_contains(filetypes.MARKDOWN, vim.bo[src_buf].filetype)

  noautocmd.run(function()
    vim.api.nvim_set_current_win(win)
  end)

  -- The eventless switch skips UI.cursorline.follow_focus's WinLeave and WinEnter
  cursorline.set_cursorline(false, src)
  cursorline.focus(win)

  if need_repaint then
    -- render-markdown anti-conceals the cursor row only while its buffer is current, and the
    -- eventless switch gave it no reason to redraw, so the row it left behind stays raw
    local render_md = require('render-markdown')
    render_md.render({ buf = src_buf, win = src })
  end

  return true
end

--- @class utils.popup.KeymapLayer
--- @field rhs string | function
--- @field opts vim.keymap.set.Opts

--- Popup overrides per buffer-local key, oldest first; `base` is the buffer's own mapping, if any
--- @type table<string, { base: table?, layers: utils.popup.KeymapLayer[] }>
local override_stacks = {}

--- Map keys on a buffer while a popup lives; overrides of a key stack, so releasing one in any
--- order keeps the newest remaining one active, or restores the buffer's own mapping
--- @param buf integer
--- @param maps { [1]: string | string[], [2]: string, [3]: string | function, [4]: vim.keymap.set.Opts }[] Mode(s), lhs, rhs and opts of each override
--- @return fun() release Undoes every override of this call; later calls are no-ops
local function override_buf_keymaps(buf, maps)
  --- @type { key: string, mode: string, lhs: string, layer: utils.popup.KeymapLayer }[]
  local pushed = {}

  for _, map in ipairs(maps) do
    local modes, lhs, rhs, opts = map[1], map[2], map[3], map[4]
    if type(modes) == 'string' then
      modes = { modes }
    end
    local layer = { rhs = rhs, opts = vim.tbl_extend('force', opts, { buf = buf }) }

    for _, mode in ipairs(modes) do
      local key = string.format('%d %s %s', buf, mode, lhs)
      override_stacks[key] = override_stacks[key]
        or { base = keymap.get_buf_keymap(buf, mode, lhs), layers = {} }
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
          keymap.restore_buf_keymap(buf, entry.mode, stack.base)
        else
          pcall(vim.keymap.del, entry.mode, entry.lhs, { buf = buf })
        end
      end
    end
  end
end

--- Source-side events that close the popup, besides its source window closing or buffer being wiped
--- @class utils.popup.CloseOn
--- @field cursor_moved? boolean The cursor moved in the source window (re-entering it fires CursorMoved too, so the position is compared)
--- @field focus_left? boolean Focus landed in a window or buffer other than the popup's and the source's
--- @field mode_changed? boolean The mode changed in the source buffer

--- @class utils.popup.LinkOpts
--- @field name string Popup name for the keymap descriptions
--- @field modes? string | string[] Modes to map (default 'n')
--- @field keys? boolean Tab toggles focus and q or Esc inside the popup close it (default true); false for an unfocusable popup, which only the source window's Esc closes
--- @field close_on? utils.popup.CloseOn Close the popup from the source's side too
--- @field on_close? fun() Runs once when the link is released, however the popup closed
--- @field focus_popup? fun() Focus the popup instead of the default autocmd-free switch
--- @field esc_passthrough? boolean Have the source window's <Esc> also do what it does without the popup (e.g. the global Clear Highlight)

--- Link a popup to the current window: <Esc> (and q inside it) closes it from either side, <Tab>
--- swaps focus, `close_on` closes it as the source moves on, and the source's overrides go with it
--- @param popup_win integer
--- @param opts utils.popup.LinkOpts
--- @return fun() close Closes the popup and releases the link; later calls are no-ops
function M.link(popup_win, opts)
  local source_win = vim.api.nvim_get_current_win()
  local modes = opts.modes or 'n'
  local source_buf = vim.api.nvim_win_get_buf(source_win)
  local popup_buf = vim.api.nvim_win_get_buf(popup_win)
  local close_desc = 'Close ' .. opts.name
  local group = vim.api.nvim_create_augroup('utils.popup.link-' .. popup_win, { clear = true })

  local release_source_maps
  local released = false

  local function release()
    if released then
      return
    end
    released = true

    -- Deleted before any close, so the popup's WinClosed can't come back here
    pcall(vim.api.nvim_del_augroup_by_id, group)
    release_source_maps()
    if opts.on_close then
      opts.on_close()
    end
  end

  local function close()
    release()
    pcall(vim.api.nvim_win_close, popup_win, true)
  end

  local source_maps = {
    {
      modes,
      '<Esc>',
      function()
        close()
        if opts.esc_passthrough then
          -- Released by close(), so the replayed key reaches what the override covered
          vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'm', false)
        end
      end,
      { desc = close_desc, nowait = true },
    },
  }

  if opts.keys ~= false then
    local map_popup = keymap.buf_mapper(popup_buf, { nowait = true })
    map_popup(modes, { 'q', '<Esc>' }, close, close_desc)
    map_popup(modes, '<Tab>', function()
      M.focus_win(source_win)
    end, 'Focus Source Window')

    source_maps[#source_maps + 1] = {
      modes,
      '<Tab>',
      opts.focus_popup or function()
        M.focus_win(popup_win)
      end,
      { desc = string.format('Focus %s Window', opts.name), nowait = true },
    }
  end

  release_source_maps = override_buf_keymaps(source_buf, source_maps)

  vim.api.nvim_create_autocmd('WinClosed', {
    group = group,
    pattern = tostring(popup_win),
    callback = release,
  })
  -- A popup closed inside a non-nested autocmd (eagle's CmdlineEnter) fires no WinClosed
  vim.api.nvim_create_autocmd('SafeState', {
    group = group,
    callback = function()
      if not vim.api.nvim_win_is_valid(popup_win) then
        release()
      end
    end,
  })

  local close_on = opts.close_on
  if not close_on then
    return close
  end

  -- Nested, so a close from inside these fires the popup buffer's BufWipeout (render-markdown's cleanup)
  vim.api.nvim_create_autocmd('WinClosed', {
    group = group,
    pattern = tostring(source_win),
    nested = true,
    callback = close,
  })
  vim.api.nvim_create_autocmd('BufWipeout', {
    group = group,
    buffer = source_buf,
    nested = true,
    callback = close,
  })

  if close_on.cursor_moved then
    local origin_pos = vim.api.nvim_win_get_cursor(source_win)

    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      group = group,
      buffer = source_buf,
      nested = true,
      callback = function()
        if vim.api.nvim_get_current_win() ~= source_win then
          return
        end
        if vim.deep_equal(vim.api.nvim_win_get_cursor(source_win), origin_pos) then
          return
        end
        close()
      end,
    })
  end

  if close_on.focus_left then
    vim.api.nvim_create_autocmd('WinEnter', {
      group = group,
      nested = true,
      callback = function()
        local current = vim.api.nvim_get_current_win()
        if current ~= popup_win and current ~= source_win then
          close()
        end
      end,
    })
    vim.api.nvim_create_autocmd('BufEnter', {
      group = group,
      nested = true,
      callback = function(args)
        if args.buf ~= popup_buf and args.buf ~= source_buf then
          close()
        end
      end,
    })
  end

  if close_on.mode_changed then
    vim.api.nvim_create_autocmd('ModeChanged', {
      group = group,
      buffer = source_buf,
      nested = true,
      callback = close,
    })
  end

  return close
end

return M
