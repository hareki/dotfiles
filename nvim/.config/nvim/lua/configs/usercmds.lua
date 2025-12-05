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

  if action == 'reset' then
    -- Force hide and resubscribe to events
    pcall(function()
      cmp.hide()
      cmp.resubscribe()
    end)
    Notifier.info('blink.cmp reset attempted')
  elseif action == 'reload' then
    -- Reload the copilot source specifically
    pcall(function()
      cmp.reload('copilot')
    end)
    Notifier.info('blink.cmp copilot source reloaded')
  else
    -- Show debug info
    local info = {
      'blink.cmp Debug Info:',
      '─────────────────────',
      'is_active: ' .. tostring(cmp.is_active()),
      'is_visible: ' .. tostring(cmp.is_visible()),
      'is_menu_visible: ' .. tostring(cmp.is_menu_visible()),
      'is_ghost_text_visible: ' .. tostring(cmp.is_ghost_text_visible()),
      'snippet_active: ' .. tostring(cmp.snippet_active()),
      'mode: ' .. vim.api.nvim_get_mode().mode,
      '',
      'Commands: :BlinkDebug reset | :BlinkDebug reload',
    }
    Notifier.info(table.concat(info, '\n'), { title = 'BlinkDebug', timeout = 10000 })
  end
end, {
  nargs = '?',
  complete = function()
    return { 'reset', 'reload' }
  end,
  desc = 'Debug blink.cmp state (reset/reload/info)',
})
