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
    local bufnr = vim.api.nvim_get_current_buf()
    local winnr = vim.api.nvim_get_current_win()

    -- Pre-collect critical state for health check
    local health_issues = {}
    local ok_trigger, trigger = pcall(require, 'blink.cmp.completion.trigger')

    -- Check 1: buffer_events exists
    if ok_trigger and trigger then
      if not trigger.buffer_events then
        table.insert(health_issues, 'buffer_events is nil')
      elseif trigger.buffer_events.textchangedi_id == -1 then
        table.insert(health_issues, 'textchangedi_id is -1 (not registered)')
      else
        -- Check if the autocmd still exists
        local textchangedi_id = trigger.buffer_events.textchangedi_id
        local autocmd_exists = false
        local ok_acs, all_text_changed =
          pcall(vim.api.nvim_get_autocmds, { event = 'TextChangedI' })
        if ok_acs then
          for _, ac in ipairs(all_text_changed) do
            if ac.id == textchangedi_id then
              autocmd_exists = true
              break
            end
          end
        end
        if not autocmd_exists then
          table.insert(
            health_issues,
            ('TextChangedI autocmd id=%d missing'):format(textchangedi_id)
          )
        end
      end

      -- Check 2: Event emitters exist
      if not trigger.show_emitter then
        table.insert(health_issues, 'show_emitter is nil')
      end
      if not trigger.hide_emitter then
        table.insert(health_issues, 'hide_emitter is nil')
      end
    else
      table.insert(health_issues, 'trigger module not loaded')
    end

    -- Check 3: Ungrouped autocmd count (should be ~25-30)
    local ungrouped_autocmd_count = 0
    local critical_events =
      { 'InsertCharPre', 'TextChangedI', 'CursorMovedI', 'InsertEnter', 'InsertLeave' }
    for _, event in ipairs(critical_events) do
      local ok_ac, acs = pcall(vim.api.nvim_get_autocmds, { event = event })
      if ok_ac then
        for _, ac in ipairs(acs) do
          if ac.group == nil and ac.callback ~= nil then
            ungrouped_autocmd_count = ungrouped_autocmd_count + 1
          end
        end
      end
    end
    if ungrouped_autocmd_count < 5 then
      table.insert(
        health_issues,
        ('Only %d ungrouped autocmds (expected ~15+)'):format(ungrouped_autocmd_count)
      )
    end

    -- Check 4: Config enabled
    local ok_config, config = pcall(require, 'blink.cmp.config')
    if ok_config and config then
      local config_enabled = false
      pcall(function()
        config_enabled = config.enabled()
      end)
      if not config_enabled then
        table.insert(health_issues, 'config.enabled() returns false')
      end
    end

    local info = {
      'blink.cmp Deep Dump:',
      '═════════════════════════════════════════════════════════',
    }

    -- Health Check Summary at the TOP
    table.insert(info, '')
    if #health_issues == 0 then
      table.insert(info, '▸ Health Check: ✓ ALL PASSED')
    else
      table.insert(info, '▸ Health Check: ⚠️  ISSUES DETECTED!')
      for _, issue in ipairs(health_issues) do
        table.insert(info, ('  ❌ %s'):format(issue))
      end
    end

    table.insert(info, '')
    table.insert(info, '▸ Environment:')
    table.insert(info, ('  mode: %s (blocking=%s)'):format(mode.mode, tostring(mode.blocking)))
    table.insert(info, ('  buf: %d ft=%s bt=%s'):format(bufnr, vim.bo.filetype, vim.bo.buftype))
    table.insert(info, ('  win: %d type=%s'):format(winnr, vim.fn.win_gettype(winnr)))
    table.insert(
      info,
      ('  modifiable: %s readonly: %s'):format(
        tostring(vim.bo.modifiable),
        tostring(vim.bo.readonly)
      )
    )
    table.insert(
      info,
      ('  paste: %s iminsert: %s'):format(tostring(vim.o.paste), tostring(vim.bo.iminsert))
    )
    table.insert(info, ('  changedtick: %d'):format(vim.api.nvim_buf_get_changedtick(bufnr)))
    table.insert(
      info,
      (function()
        local cursor = vim.api.nvim_win_get_cursor(winnr)
        return ('  cursor: [%d, %d]'):format(cursor[1], cursor[2])
      end)()
    )

    -- blink.cmp public API state
    table.insert(info, '')
    table.insert(info, '▸ blink.cmp Public API:')
    table.insert(
      info,
      safe('  is_active', function()
        return cmp.is_active()
      end)
    )
    table.insert(
      info,
      safe('  is_visible', function()
        return cmp.is_visible()
      end)
    )
    table.insert(
      info,
      safe('  is_menu_visible', function()
        return cmp.is_menu_visible()
      end)
    )
    table.insert(
      info,
      safe('  is_ghost_text_visible', function()
        return cmp.is_ghost_text_visible()
      end)
    )
    table.insert(
      info,
      safe('  is_signature_visible', function()
        return cmp.is_signature_visible()
      end)
    )
    table.insert(
      info,
      safe('  is_documentation_visible', function()
        return cmp.is_documentation_visible()
      end)
    )
    table.insert(
      info,
      safe('  snippet_active', function()
        return cmp.snippet_active()
      end)
    )
    table.insert(
      info,
      safe('  snippet_active(fwd)', function()
        return cmp.snippet_active({ direction = 1 })
      end)
    )
    table.insert(
      info,
      safe('  snippet_active(bwd)', function()
        return cmp.snippet_active({ direction = -1 })
      end)
    )

    -- Context details
    table.insert(info, '')
    table.insert(info, '▸ Completion Context:')
    local ctx = nil
    pcall(function()
      ctx = cmp.get_context()
    end)
    if ctx then
      table.insert(info, ('  id: %s'):format(tostring(ctx.id)))
      table.insert(info, ('  mode: %s'):format(tostring(ctx.mode)))
      table.insert(info, ('  bufnr: %s'):format(tostring(ctx.bufnr)))
      table.insert(
        info,
        ('  cursor: [%s, %s]'):format(tostring(ctx.cursor[1]), tostring(ctx.cursor[2]))
      )
      table.insert(info, ('  line: "%s"'):format(ctx.line and ctx.line:sub(1, 80) or 'nil'))
      if ctx.bounds then
        table.insert(
          info,
          ('  bounds: line=%d start=%d len=%d'):format(
            ctx.bounds.line_number or -1,
            ctx.bounds.start_col or -1,
            ctx.bounds.length or -1
          )
        )
      end
      if ctx.trigger then
        table.insert(info, ('  trigger.kind: %s'):format(tostring(ctx.trigger.kind)))
        table.insert(
          info,
          ('  trigger.initial_kind: %s'):format(tostring(ctx.trigger.initial_kind))
        )
        table.insert(info, ('  trigger.character: %s'):format(tostring(ctx.trigger.character)))
      end
      table.insert(
        info,
        ('  providers: %s'):format(ctx.providers and table.concat(ctx.providers, ', ') or 'nil')
      )
      table.insert(info, ('  timestamp: %s'):format(tostring(ctx.timestamp)))
    else
      table.insert(info, '  <no active context>')
    end

    -- Completion list state
    table.insert(info, '')
    table.insert(info, '▸ Completion List:')
    local ok_list, list = pcall(require, 'blink.cmp.completion.list')
    if ok_list and list then
      table.insert(info, ('  items count: %d'):format(list.items and #list.items or 0))
      table.insert(info, ('  selected_item_idx: %s'):format(tostring(list.selected_item_idx)))
      table.insert(info, ('  preview_undo: %s'):format(tostring(list.preview_undo ~= nil)))
      local selected = list.get_selected_item and list.get_selected_item()
      if selected then
        table.insert(
          info,
          ('  selected_item.label: %s'):format(
            selected.label and selected.label:sub(1, 30) or 'nil'
          )
        )
        table.insert(info, ('  selected_item.kind: %s'):format(tostring(selected.kind)))
      end
    else
      table.insert(info, '  <list module unavailable>')
    end

    -- Menu window state
    table.insert(info, '')
    table.insert(info, '▸ Menu Window:')
    local ok_menu, menu = pcall(require, 'blink.cmp.completion.windows.menu')
    if ok_menu and menu then
      local win = menu.win
      if win then
        table.insert(info, ('  win:is_open(): %s'):format(tostring(win:is_open())))
        table.insert(info, ('  win.id: %s'):format(tostring(win.id)))
        -- auto_show can be a function, boolean, or table
        local auto_show_val = menu.auto_show
        local auto_show_str
        if type(auto_show_val) == 'function' then
          local ok_as, as_result = pcall(auto_show_val)
          auto_show_str = ok_as and ('fn()→%s'):format(tostring(as_result)) or 'fn()→err'
        elseif type(auto_show_val) == 'table' then
          auto_show_str = vim.inspect(auto_show_val, { newline = ' ', indent = '' }):sub(1, 80)
        else
          auto_show_str = tostring(auto_show_val)
        end
        table.insert(info, ('  auto_show: %s'):format(auto_show_str))
      else
        table.insert(info, '  win: nil')
      end
    else
      table.insert(info, '  <menu module unavailable>')
    end

    -- Trigger internal state
    table.insert(info, '')
    table.insert(info, '▸ Trigger State:')
    local ok_trigger, trigger = pcall(require, 'blink.cmp.completion.trigger')
    if ok_trigger and trigger then
      table.insert(info, ('  context: %s'):format(tostring(trigger.context ~= nil)))
      table.insert(info, ('  current_context_id: %s'):format(tostring(trigger.current_context_id)))

      -- buffer_events
      if trigger.buffer_events then
        local be = trigger.buffer_events
        table.insert(info, '  buffer_events:')
        table.insert(info, ('    textchangedi_id: %s'):format(tostring(be.textchangedi_id)))
        table.insert(
          info,
          ('    ignore_next_text_changed: %s'):format(tostring(be.ignore_next_text_changed))
        )
        table.insert(
          info,
          ('    ignore_next_cursor_moved: %s'):format(tostring(be.ignore_next_cursor_moved))
        )
        table.insert(info, ('    last_char: "%s"'):format(tostring(be.last_char)))
        table.insert(
          info,
          ('    has_context(): %s'):format(tostring(be.has_context and be.has_context()))
        )
        table.insert(info, ('    show_in_snippet: %s'):format(tostring(be.show_in_snippet)))
      else
        table.insert(info, '  buffer_events: nil ⚠️  BROKEN!')
      end

      -- cmdline_events
      if trigger.cmdline_events then
        local ce = trigger.cmdline_events
        table.insert(info, '  cmdline_events:')
        table.insert(
          info,
          ('    ignore_next_text_changed: %s'):format(tostring(ce.ignore_next_text_changed))
        )
        table.insert(
          info,
          ('    ignore_next_cursor_moved: %s'):format(tostring(ce.ignore_next_cursor_moved))
        )
      else
        table.insert(info, '  cmdline_events: nil')
      end

      -- term_events
      if trigger.term_events then
        table.insert(info, '  term_events: present')
      else
        table.insert(info, '  term_events: nil')
      end

      -- Event emitters
      table.insert(info, ('  show_emitter: %s'):format(tostring(trigger.show_emitter ~= nil)))
      table.insert(info, ('  hide_emitter: %s'):format(tostring(trigger.hide_emitter ~= nil)))
    else
      table.insert(info, '  <trigger module unavailable>')
    end

    -- Sources state
    table.insert(info, '')
    table.insert(info, '▸ Sources:')
    local ok_sources, sources = pcall(require, 'blink.cmp.sources.lib')
    if ok_sources and sources then
      local ok_ids, provider_ids = pcall(function()
        return sources.get_enabled_provider_ids('default')
      end)
      if ok_ids then
        table.insert(info, ('  enabled (default): %s'):format(table.concat(provider_ids, ', ')))
      end
      local ok_cmdline_ids, cmdline_ids = pcall(function()
        return sources.get_enabled_provider_ids('cmdline')
      end)
      if ok_cmdline_ids then
        table.insert(info, ('  enabled (cmdline): %s'):format(table.concat(cmdline_ids, ', ')))
      end
    else
      table.insert(info, '  <sources module unavailable>')
    end

    -- Config state
    table.insert(info, '')
    table.insert(info, '▸ Config:')
    local ok_config, config = pcall(require, 'blink.cmp.config')
    if ok_config and config then
      table.insert(
        info,
        safe('  enabled()', function()
          return config.enabled()
        end)
      )
      table.insert(
        info,
        ('  cmdline.enabled: %s'):format(tostring(config.cmdline and config.cmdline.enabled))
      )
      table.insert(
        info,
        ('  signature.enabled: %s'):format(tostring(config.signature and config.signature.enabled))
      )
      if config.completion and config.completion.trigger then
        local t = config.completion.trigger
        table.insert(info, ('  trigger.show_on_keyword: %s'):format(tostring(t.show_on_keyword)))
        table.insert(info, ('  trigger.show_on_insert: %s'):format(tostring(t.show_on_insert)))
        table.insert(info, ('  trigger.show_in_snippet: %s'):format(tostring(t.show_in_snippet)))
      end
    else
      table.insert(info, '  <config module unavailable>')
    end

    -- Keymaps
    table.insert(info, '')
    table.insert(info, '▸ Keymaps (insert mode):')
    table.insert(info, '  ' .. map_info('<A-Space>'))
    table.insert(info, '  ' .. map_info('<CR>'))
    table.insert(info, '  ' .. map_info('<Tab>'))
    table.insert(info, '  ' .. map_info('<S-Tab>'))
    table.insert(info, '  ' .. map_info('<Esc>'))
    table.insert(info, '  ' .. map_info('<Up>'))
    table.insert(info, '  ' .. map_info('<Down>'))

    -- Keymaps cmdline mode
    table.insert(info, '')
    table.insert(info, '▸ Keymaps (cmdline mode):')
    local function cmdline_map_info(lhs)
      local map = vim.fn.maparg(lhs, 'c', false, true)
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
    table.insert(info, '  ' .. cmdline_map_info('<Tab>'))
    table.insert(info, '  ' .. cmdline_map_info('<S-Tab>'))
    table.insert(info, '  ' .. cmdline_map_info('<CR>'))
    table.insert(info, '  ' .. cmdline_map_info('<Esc>'))

    -- nvim-autopairs state
    table.insert(info, '')
    table.insert(info, '▸ nvim-autopairs:')
    local ap_ok, ap = pcall(require, 'nvim-autopairs')
    if ap_ok and ap then
      table.insert(info, '  loaded: true')
      -- State is on the main module as M.state
      if ap.state then
        table.insert(info, ('  state.disabled: %s'):format(tostring(ap.state.disabled)))
        table.insert(info, ('  state.ts_node: %s'):format(tostring(ap.state.ts_node)))
        table.insert(info, ('  state.expr_quote: %s'):format(tostring(ap.state.expr_quote)))
        -- rules is a table keyed by buffer number
        local rules_count = 0
        if ap.state.rules then
          for _ in pairs(ap.state.rules) do
            rules_count = rules_count + 1
          end
        end
        table.insert(info, ('  state.rules (buffers): %d'):format(rules_count))
        -- Current buffer rules
        local buf_rules = ap.get_buf_rules and ap.get_buf_rules() or {}
        table.insert(info, ('  current buf rules: %d'):format(#buf_rules))
      else
        table.insert(info, '  state: nil')
      end
      -- Config
      if ap.config then
        table.insert(info, ('  config.map_cr: %s'):format(tostring(ap.config.map_cr)))
        table.insert(info, ('  config.map_bs: %s'):format(tostring(ap.config.map_bs)))
        table.insert(info, ('  config.check_ts: %s'):format(tostring(ap.config.check_ts)))
        table.insert(
          info,
          ('  config.disable_in_macro: %s'):format(tostring(ap.config.disable_in_macro))
        )
      end
    else
      table.insert(info, '  loaded: false')
    end

    -- vim.snippet state
    table.insert(info, '')
    table.insert(info, '▸ vim.snippet:')
    table.insert(info, ('  active(): %s'):format(tostring(vim.snippet.active())))
    table.insert(
      info,
      ('  active({direction=1}): %s'):format(tostring(vim.snippet.active({ direction = 1 })))
    )
    table.insert(
      info,
      ('  active({direction=-1}): %s'):format(tostring(vim.snippet.active({ direction = -1 })))
    )

    -- Autocmds (grouped by event, showing counts)
    table.insert(info, '')
    table.insert(info, '▸ Autocmds (no group, has callback):')
    local events_to_check = {
      'InsertCharPre',
      'TextChangedI',
      'CursorMoved',
      'CursorMovedI',
      'InsertEnter',
      'InsertLeave',
      'ModeChanged',
      'BufLeave',
      'CompleteChanged',
      'CmdlineEnter',
      'CmdlineLeave',
      'CmdlineChanged',
    }
    local event_counts = {}
    local total_count = 0
    for _, event in ipairs(events_to_check) do
      local ok_ac, acs = pcall(vim.api.nvim_get_autocmds, { event = event })
      if ok_ac then
        local count = 0
        for _, ac in ipairs(acs) do
          if ac.group == nil and ac.callback ~= nil then
            count = count + 1
          end
        end
        if count > 0 then
          event_counts[event] = count
          total_count = total_count + count
        end
      end
    end
    table.insert(info, ('  Total: %d'):format(total_count))
    for _, event in ipairs(events_to_check) do
      if event_counts[event] then
        table.insert(info, ('  %s: %d'):format(event, event_counts[event]))
      end
    end

    -- CRITICAL: Check if the TextChangedI autocmd with blink's ID still exists
    table.insert(info, '')
    table.insert(info, '▸ Critical Autocmd Validation:')
    if ok_trigger and trigger and trigger.buffer_events then
      local be = trigger.buffer_events
      local textchangedi_id = be.textchangedi_id
      if textchangedi_id and textchangedi_id > 0 then
        -- Check if this autocmd ID still exists
        local autocmd_exists = false
        local ok_acs, all_text_changed =
          pcall(vim.api.nvim_get_autocmds, { event = 'TextChangedI' })
        if ok_acs then
          for _, ac in ipairs(all_text_changed) do
            if ac.id == textchangedi_id then
              autocmd_exists = true
              break
            end
          end
        end
        table.insert(
          info,
          ('  TextChangedI id=%d exists: %s %s'):format(
            textchangedi_id,
            tostring(autocmd_exists),
            autocmd_exists and '✓' or '⚠️  MISSING!'
          )
        )
      else
        table.insert(info, '  TextChangedI id: invalid or -1 ⚠️')
      end
    end

    -- Check vim.on_key handlers (blink uses these for backspace detection and ctrl+c)
    table.insert(info, '')
    table.insert(info, '▸ vim.on_key Status:')
    -- We can't enumerate on_key handlers, but we can check if the namespace exists
    local on_key_info = 'Cannot enumerate (no API), but blink.cmp uses vim.on_key for:'
    table.insert(info, '  ' .. on_key_info)
    table.insert(info, '    - Backspace detection in buffer_events')
    table.insert(info, '    - Ctrl+C detection for InsertLeave')
    table.insert(info, '    - Cmdline key tracking')

    -- Check for any scheduled callbacks that might interfere
    table.insert(info, '')
    table.insert(info, '▸ Deferred State:')
    table.insert(info, ('  vim.in_fast_event(): %s'):format(tostring(vim.in_fast_event())))
    table.insert(info, ('  vim.fn.state(): "%s"'):format(vim.fn.state()))

    -- Check pumvisible (native completion menu)
    table.insert(info, ('  vim.fn.pumvisible(): %d'):format(vim.fn.pumvisible()))

    -- Check if we're in a macro or recording
    table.insert(info, ('  vim.fn.reg_recording(): "%s"'):format(vim.fn.reg_recording()))
    table.insert(info, ('  vim.fn.reg_executing(): "%s"'):format(vim.fn.reg_executing()))

    -- Check for block visual mode (can affect autopairs)
    local current_mode = vim.api.nvim_get_mode().mode
    local is_visual_block = current_mode == '\22'
      or current_mode == '<C-V>'
      or current_mode:match('v')
    table.insert(
      info,
      ('  is_visual/block: %s (mode=%s)'):format(tostring(is_visual_block), current_mode)
    )

    -- Direct function call test
    table.insert(info, '')
    table.insert(info, '▸ Direct API Call Test:')
    -- Test if cmp.show() would work
    local show_test_result = 'untested'
    pcall(function()
      -- Don't actually show, just check if the function exists and is callable
      if type(cmp.show) == 'function' then
        show_test_result = 'function exists'
      else
        show_test_result = 'NOT A FUNCTION ⚠️'
      end
    end)
    table.insert(info, ('  cmp.show: %s'):format(show_test_result))

    -- Test resubscribe
    local resubscribe_test = 'untested'
    pcall(function()
      if type(cmp.resubscribe) == 'function' then
        resubscribe_test = 'function exists'
      else
        resubscribe_test = 'NOT A FUNCTION ⚠️'
      end
    end)
    table.insert(info, ('  cmp.resubscribe: %s'):format(resubscribe_test))

    -- Check keymap module state
    table.insert(info, '')
    table.insert(info, '▸ Keymap Module:')
    local ok_keymap, keymap = pcall(require, 'blink.cmp.keymap')
    if ok_keymap and keymap then
      table.insert(info, '  module loaded: true')
      -- Check if setup was called by looking for internal state
      local has_setup = type(keymap.setup) == 'function'
      table.insert(info, ('  has setup fn: %s'):format(tostring(has_setup)))
    else
      table.insert(info, '  module loaded: false ⚠️')
    end

    -- Buffer-local variables that might affect behavior
    table.insert(info, '')
    table.insert(info, '▸ Buffer Variables:')
    local blink_var = vim.b.blink_cmp
    table.insert(info, ('  vim.b.blink_cmp: %s'):format(tostring(blink_var)))
    local autopairs_var = vim.b['nvim-autopairs']
    table.insert(info, ('  vim.b["nvim-autopairs"]: %s'):format(tostring(autopairs_var)))
    local autopairs_keymaps = vim.b.autopairs_keymaps
    local ap_km_count = autopairs_keymaps and #autopairs_keymaps or 0
    table.insert(info, ('  vim.b.autopairs_keymaps: %d keys'):format(ap_km_count))

    -- on_key handlers (count)
    table.insert(info, '')
    table.insert(info, '▸ Registered Modules:')
    local modules_to_check = {
      'blink.cmp',
      'blink.cmp.completion.trigger',
      'blink.cmp.completion.list',
      'blink.cmp.completion.windows.menu',
      'blink.cmp.completion.windows.documentation',
      'blink.cmp.completion.windows.ghost_text',
      'blink.cmp.completion.windows.signature',
      'blink.cmp.lib.buffer_events',
      'blink.cmp.lib.cmdline_events',
      'blink.cmp.lib.term_events',
      'blink.cmp.keymap',
      'blink.cmp.sources.lib',
      'blink.cmp.fuzzy',
      'blink.cmp.config',
      'blink-copilot',
      'nvim-autopairs',
    }
    for _, mod in ipairs(modules_to_check) do
      local loaded = package.loaded[mod] ~= nil
      table.insert(info, ('  %s: %s'):format(mod, loaded and '✓' or '✗'))
    end

    -- Recent messages (last few lines from :messages)
    table.insert(info, '')
    table.insert(info, '▸ Recent Messages (last 5):')
    local messages = vim.fn.execute('messages')
    local msg_lines = vim.split(messages, '\n')
    local start_idx = math.max(1, #msg_lines - 4)
    for i = start_idx, #msg_lines do
      local line = msg_lines[i]
      if line and line ~= '' then
        table.insert(info, '  ' .. line:sub(1, 60))
      end
    end

    -- Timestamp
    table.insert(info, '')
    table.insert(
      info,
      '═════════════════════════════════════════════════════════'
    )
    table.insert(info, ('Captured at: %s'):format(os.date('%Y-%m-%d %H:%M:%S')))

    Notifier.info(table.concat(info, '\n'), { title = 'BlinkDebug Dump', timeout = 30000 })
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
