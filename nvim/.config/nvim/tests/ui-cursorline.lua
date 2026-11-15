-- UI.cursorline.follow_focus around Terminal mode. Terminal mode starts only from the main loop,
-- which a test running inside this boot's one command never returns to, so a child nvim on this
-- config enters it, driven over RPC

local t = require('tests.lib.helpers')

--- @class tests.ui-cursorline.State
--- @field mode string
--- @field buftype string
--- @field line_shown boolean The cursor line's text is highlighted, not just its number
--- @field terminal_lines_shown boolean[] The same, for every window on a terminal

--- @class tests.ui-cursorline.Child
--- @field lua fun(code: string): any Runs code in it, after what it has queued
--- @field input fun(keys: string) Types keys into it
--- @field wait fun(mode: string): tests.ui-cursorline.State Waits for a mode; its answer comes after the callbacks the switch queued
--- @field settled fun(): tests.ui-cursorline.State The state 200 ms on, for a line that must stay hidden in Terminal mode: by then only a timer could still show it

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
      local function line_shown(win)
        return vim.wo[win].cursorline and vim.wo[win].cursorlineopt ~= 'number'
      end
      local terminal_lines_shown = {}
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.bo[vim.api.nvim_win_get_buf(win)].buftype == 'terminal' then
          terminal_lines_shown[#terminal_lines_shown + 1] = line_shown(win)
        end
      end
      return {
        mode = vim.api.nvim_get_mode().mode,
        buftype = vim.bo.buftype,
        line_shown = line_shown(0),
        terminal_lines_shown = terminal_lines_shown,
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
      return state()
    end,
    settled = function()
      t.settle(200)
      return state()
    end,
  }
end

t.test('the floating terminal shows a cursor line in Normal mode, not in Terminal mode', function()
  local c = child()

  c.input('<A-t>')
  t.eq(c.wait('t').buftype, 'terminal', 'the terminal is focused')
  t.eq(c.settled().line_shown, false, 'cursor line once it opens in Terminal mode')

  c.input([[<C-\><C-n>]])
  t.eq(c.wait('nt').line_shown, true, 'cursor line in Normal mode')

  c.input('i')
  c.wait('t')
  t.eq(c.settled().line_shown, false, 'cursor line back in Terminal mode')
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
  c.wait('t')
  t.eq(c.settled().line_shown, false, 'cursor line in Terminal mode')
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

t.test('a terminal left from Terminal mode keeps only its line number', function()
  local c = child()

  c.lua([[vim.cmd('vsplit | terminal')]])
  c.input('i')
  c.wait('t')
  -- Go to Left Window, mapped in Terminal mode too. The mode ends after the terminal is left, and
  -- Neovim then puts back the full line it had when the mode began
  c.input('<A-m>')
  local back = c.wait('n')
  t.eq(back.buftype, '', 'the editor window is focused')
  t.eq(back.line_shown, true, 'cursor line in the editor window')
  t.eq(back.terminal_lines_shown, { false }, 'cursor line in the terminal left behind')
end)

t.test('terminals switched between in Terminal mode keep only their line numbers', function()
  local c = child()

  -- The editor, with two terminals to its right
  c.lua([[
    vim.cmd('vsplit | terminal')
    vim.cmd('vsplit | terminal')
  ]])
  c.input('i')
  c.wait('t')
  -- To the other terminal, which keeps the mode going: Neovim puts the first one's full line back
  -- with no event to tell. Then on to the editor
  c.input('<A-m><A-m>')
  local back = c.wait('n')
  t.eq(back.buftype, '', 'the editor window is focused')
  t.eq(back.line_shown, true, 'cursor line in the editor window')
  t.eq(back.terminal_lines_shown, { false, false }, 'cursor lines in the terminals left behind')
end)
