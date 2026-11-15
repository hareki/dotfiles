-- UI.cursorline.follow_focus around Terminal mode. Terminal mode starts only from the main loop,
-- which a test running inside this boot's one command never returns to, so a child nvim on this
-- config enters it, driven over RPC

local t = require('tests.lib.helpers')

--- @class tests.ui-cursorline.State
--- @field mode string
--- @field buftype string
--- @field line_shown boolean The cursor line's text is highlighted, not just its number

--- @class tests.ui-cursorline.Child
--- @field lua fun(code: string): any Runs code in it, after what it has queued
--- @field input fun(keys: string) Types keys into it
--- @field wait fun(mode: string): tests.ui-cursorline.State Waits for a mode and the callbacks the switch scheduled

--- A child nvim on this config, booted the way the tests' own is (VeryLazy fired)
--- @return tests.ui-cursorline.Child
local function child()
  local chan = vim.fn.jobstart(
    { vim.v.progpath, '--embed', '--headless', '-i', 'NONE' },
    { rpc = true }
  )
  t.ok(chan > 0, 'the child nvim starts')
  t.cleanup(function()
    -- os.exit, as every boot here ends: no session save
    vim.rpcnotify(chan, 'nvim_exec_lua', 'os.exit(0)', {})
    vim.fn.jobwait({ chan }, 3000)
  end)

  --- @param code string
  --- @return any
  local function lua(code)
    return vim.rpcrequest(chan, 'nvim_exec_lua', code, {})
  end

  --- @return tests.ui-cursorline.State
  local function state()
    return lua([[
      return {
        mode = vim.api.nvim_get_mode().mode,
        buftype = vim.bo.buftype,
        line_shown = vim.wo.cursorline and vim.wo.cursorlineopt ~= 'number',
      }
    ]])
  end

  lua([[
    vim.api.nvim_exec_autocmds('User', { pattern = 'VeryLazy', modeline = false })
    -- The floating terminal runs 'shell', which would load the user's whole zsh config
    vim.o.shell = '/bin/sh'
  ]])

  --- @type tests.ui-cursorline.Child
  return {
    lua = lua,
    input = function(keys)
      vim.rpcrequest(chan, 'nvim_input', keys)
    end,
    wait = function(mode)
      t.wait_for(function()
        return state().mode == mode
      end, mode .. ' mode in the child', 5000)
      t.settle(200)
      return state()
    end,
  }
end

t.test('the floating terminal shows a cursor line in Normal mode, not in Terminal mode', function()
  local c = child()

  c.input('<A-t>')
  local opened = c.wait('t')
  t.eq(opened.buftype, 'terminal', 'the terminal is focused')
  t.eq(opened.line_shown, false, 'cursor line once it opens in Terminal mode')

  c.input([[<C-\><C-n>]])
  t.eq(c.wait('nt').line_shown, true, 'cursor line in Normal mode')

  c.input('i')
  t.eq(c.wait('t').line_shown, false, 'cursor line back in Terminal mode')
end)

t.test('a float opening over the terminal in Terminal mode shows no cursor line on it', function()
  local c = child()

  c.input('<A-t>')
  c.wait('t')
  -- As a notification does: its BufWinEnter schedules a focus() of the then current window
  c.lua([[
    vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), false, {
      relative = 'editor',
      row = 0,
      col = 0,
      width = 10,
      height = 1,
    })
  ]])
  t.eq(c.wait('t').line_shown, false, 'cursor line in Terminal mode')
end)

t.test(
  'hiding the floating terminal from Terminal mode leaves the editor its cursor line',
  function()
    local c = child()

    c.input('<A-t>')
    c.wait('t')
    c.input('<A-t>')
    local back = c.wait('n')
    t.eq(back.buftype, '', 'the editor window is focused')
    t.eq(back.line_shown, true, 'cursor line in the editor window')
  end
)
