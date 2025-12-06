vim.api.nvim_create_user_command('HlAtCursor', function()
  require('utils.hl-at-cursor')()
end, { desc = 'Show Highlight Groups Under Cursor' })

if require('plugins.ui.lualine.utils').have_status_line() then
  vim.api.nvim_create_user_command('TabRename', function(opts)
    vim.t.tab_name = opts.args
    require('lualine').refresh({ place = { 'statusline' } })
  end, { nargs = 1 })
end

-- Debug command to check blink.cmp state and reset if needed
vim.api.nvim_create_user_command('BlinkDebug', function(opts)
  local ok, cmp = pcall(require, 'blink.cmp')
  if not ok then
    Notifier.warn('blink.cmp not loaded')
    return
  end

  local action = opts.args

  local function safe(label, fn)
    local ok_call, result = pcall(fn)
    if ok_call then
      return string.format('%-24s %s', label .. ':', tostring(result))
    end
    return string.format('%-24s err: %s', label .. ':', result)
  end

  local function map_info(lhs)
    local map = vim.fn.maparg(lhs, 'i', false, true)
    if not map or map.lhs == nil or map.lhs == '' then
      return lhs .. ': <none>'
    end

    local rhs = map.rhs or ''
    if map.callback then
      rhs = '<Lua callback>'
    end

    if rhs == '' then
      rhs = '<no rhs>'
    end

    local desc = map.desc and (' (' .. map.desc .. ')') or ''
    return string.format('%s: %s%s', lhs, rhs, desc)
  end

  if action == 'reset' then
    -- Force hide and resubscribe to events
    pcall(function()
      cmp.hide()
      cmp.resubscribe()
    end)
    Notifier.info('blink.cmp reset attempted')
  elseif action == 'fix' then
    -- More aggressive fix: reload keymaps and resubscribe
    local fixed = {}

    -- 1. Hide any visible completion
    pcall(function()
      cmp.hide()
      table.insert(fixed, 'Hidden completion')
    end)

    -- 2. Stop any active snippets
    if vim.snippet.active() then
      pcall(vim.snippet.stop)
      table.insert(fixed, 'Stopped snippet')
    end

    -- 3. Resubscribe to text change events
    pcall(function()
      cmp.resubscribe()
      table.insert(fixed, 'Resubscribed to events')
    end)

    -- 4. Re-trigger keymap application by simulating InsertEnter
    vim.schedule(function()
      -- Briefly leave and re-enter insert mode to trigger keymap re-application
      local mode = vim.api.nvim_get_mode().mode
      if mode == 'i' or mode == 'ic' or mode == 'ix' then
        vim.api.nvim_exec_autocmds('InsertEnter', { modeline = false })
        table.insert(fixed, 'Re-triggered InsertEnter')
      end

      Notifier.info('blink.cmp fix applied:\n• ' .. table.concat(fixed, '\n• '), {
        title = 'BlinkDebug Fix',
        timeout = 5000,
      })
    end)
    return
  elseif action == 'reload' then
    -- Reload the copilot source specifically
    pcall(function()
      cmp.reload('copilot')
    end)
    Notifier.info('blink.cmp copilot source reloaded')
  elseif action == 'dump' then
    local mode = vim.api.nvim_get_mode()

    local info = {
      'blink.cmp Deep Dump:',
      '─────────────────────',
      ('mode: %s (blocking=%s)'):format(mode.mode, tostring(mode.blocking)),
      ('buf ft/bt: %s / %s'):format(vim.bo.filetype, vim.bo.buftype),
      ('modifiable: %s paste: %s iminsert: %s'):format(
        tostring(vim.bo.modifiable),
        tostring(vim.o.paste),
        tostring(vim.bo.iminsert)
      ),
      safe('cmp.is_active', function()
        return cmp.is_active()
      end),
      safe('cmp.is_visible', function()
        return cmp.is_visible()
      end),
      safe('cmp.is_menu_visible', function()
        return cmp.is_menu_visible()
      end),
      safe('cmp.is_ghost_text_visible', function()
        return cmp.is_ghost_text_visible()
      end),
      safe('cmp.snippet_active', function()
        return cmp.snippet_active()
      end),
      safe('cmp.context.mode', function()
        return cmp.get_context and cmp.get_context().mode
      end),
      'Keymaps (insert mode):',
      '  ' .. map_info('<A-Space>'),
      '  ' .. map_info('<CR>'),
      '  ' .. map_info('<Tab>'),
      '  ' .. map_info('<Esc>'),
    }

    local ap_info = {}
    local ap_ok, ap_state = pcall(require, 'nvim-autopairs.state')
    if ap_ok then
      table.insert(ap_info, 'nvim-autopairs:')
      table.insert(ap_info, '  disabled: ' .. tostring(ap_state.disabled))
      table.insert(ap_info, '  ts_node: ' .. tostring(ap_state.ts_node and ap_state.ts_node:type()))
      table.insert(ap_info, '  before_char: ' .. tostring(ap_state.before_char))
      table.insert(ap_info, '  last_event: ' .. tostring(ap_state.last_event))
    else
      table.insert(ap_info, 'nvim-autopairs.state unavailable')
    end
    vim.list_extend(info, ap_info)

    local autocmds = {}
    local ok_autocmd, ac = pcall(vim.api.nvim_get_autocmds, {
      event = { 'InsertEnter', 'InsertLeave', 'ModeChanged' },
      group = 'blink.cmp',
    })
    if ok_autocmd then
      autocmds = ac
    end

    table.insert(info, 'blink.cmp autocmds (#' .. tostring(#autocmds) .. '):')
    for _, a in ipairs(autocmds) do
      table.insert(info, string.format('  %s %s', a.event, a.pattern or '*'))
    end

    Notifier.info(table.concat(info, '\n'), { title = 'BlinkDebug Dump', timeout = 15000 })
  else
    -- Show debug info
    local info = {
      'blink.cmp Debug Info:',
      '─────────────────────',
      'cmp.is_active: ' .. tostring(cmp.is_active()),
      'cmp.is_visible: ' .. tostring(cmp.is_visible()),
      'cmp.is_menu_visible: ' .. tostring(cmp.is_menu_visible()),
      'cmp.is_ghost_text_visible: ' .. tostring(cmp.is_ghost_text_visible()),
      'cmp.snippet_active: ' .. tostring(cmp.snippet_active()),
      'mode: ' .. vim.api.nvim_get_mode().mode,
      '',
      'Commands: :BlinkDebug reset | :BlinkDebug reload',
    }
    Notifier.info(table.concat(info, '\n'), { title = 'BlinkDebug', timeout = 10000 })
  end
end, {
  nargs = '?',
  complete = function()
    return { 'fix', 'reset', 'reload', 'dump' }
  end,
  desc = 'Debug blink.cmp state (fix/reset/reload/dump/info)',
})
