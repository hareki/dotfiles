-- features.ai.claudecode-nvim.done: the panel's agent finishing shows in the statusline while the
-- panel is out of sight, until the statusline finds it showing; no other Claude's finish does

local t = require('tests.lib.helpers')
local done = require('features.ai.claudecode-nvim.done')

--- A stand-in panel until the test ends: a focused float claudecode.nvim takes for its terminal
--- @return integer win
--- @return integer pid Its job's, as the panel's Claude would report it
local function open_panel()
  local win, buf = t.float(true)
  -- Its Claude, which ends when the float's buffer is wiped
  local job = vim.fn.jobstart({ 'sleep', '30' }, { term = true })
  t.set(package.loaded, 'claudecode.terminal', {
    get_active_terminal_bufnr = function()
      return buf
    end,
  })
  return win, vim.fn.jobpid(job)
end

--- The way claudecode.nvim toggles its float off: hidden in place, focus back on the code
--- @param win integer
--- @param code_win integer
local function hide_panel(win, code_win)
  vim.api.nvim_win_set_config(win, { hide = true })
  vim.api.nvim_set_current_win(code_win)
end

--- @param win integer
local function show_panel(win)
  vim.api.nvim_win_set_config(win, { hide = false })
  vim.api.nvim_set_current_win(win)
end

--- A Claude finishing, as its Stop hook reports it. The flag is the module's own, so when the
--- test ends a panel shows to clear whatever it left
--- @param pid integer The Claude's
local function finish(pid)
  t.cleanup(function()
    if done.unseen() then
      open_panel()
      t.eq(done.unseen(), false, 'a shown panel clears the flag the test left')
    end
  end)
  done.mark(tostring(pid))
end

--- Wait for the statusline lualine last rendered to show the agent's icon, or to drop it. Asked
--- from a code window: lualine has drawn none yet for a float just entered
--- @param shown boolean
--- @param msg string
local function await_icon(shown, msg)
  local icon = vim.trim(Conf.icons.cmp_kinds.CodingAgent)
  t.wait_for(function()
    local text = vim.api.nvim_eval_statusline(vim.o.statusline, {}).str
    return (text:find(icon, 1, true) ~= nil) == shown
  end, msg)
end

t.test('a finish under a hidden panel shows in the statusline until it finds the panel', function()
  local code_win = vim.api.nvim_get_current_win()
  local win, pid = open_panel()
  hide_panel(win, code_win)
  await_icon(false, 'a statusline without the icon before the finish')

  finish(pid)
  t.eq(done.unseen(), true, 'unseen after the finish')
  await_icon(true, 'the icon after the finish')

  show_panel(win)
  vim.api.nvim_set_current_win(code_win)
  await_icon(false, 'the icon to go once the panel shows')
  t.eq(done.unseen(), false, 'unseen after the statusline found the panel')
end)

t.test('a finish under a visible panel is not flagged', function()
  local _, pid = open_panel()
  finish(pid)
  t.eq(done.unseen(), false)
end)

t.test('a finish under a hidden panel is flagged until the panel shows again', function()
  local code_win = vim.api.nvim_get_current_win()
  local win, pid = open_panel()
  hide_panel(win, code_win)

  finish(pid)
  t.eq(done.unseen(), true, 'unseen after the finish')

  -- Focus moving between other windows leaves it
  vim.cmd.split()
  t.eq(done.unseen(), true, 'unseen after entering another window')
  vim.cmd.close()

  show_panel(win)
  t.eq(done.unseen(), false, 'unseen with the panel showing again')

  -- Seen once: hiding the panel again brings nothing back
  hide_panel(win, code_win)
  t.eq(done.unseen(), false, 'unseen after hiding the panel again')
end)

t.test('a panel in another tab does not count as showing', function()
  local _, pid = open_panel()
  t.tab()

  finish(pid)
  t.eq(done.unseen(), true, 'unseen after the finish')

  vim.cmd.tabclose()
  t.eq(done.unseen(), false, 'unseen back in the tab of the panel')
end)

t.test("the finish of a Claude that is not the panel's is not flagged", function()
  t.set(package.loaded, 'claudecode.terminal', nil)
  finish(vim.uv.os_getpid())
  t.eq(done.unseen(), false, 'no panel yet')

  local code_win = vim.api.nvim_get_current_win()
  local win, pid = open_panel()
  hide_panel(win, code_win)
  -- One in another terminal, or one the panel's Claude ran itself
  done.mark(tostring(pid + 1))
  t.eq(done.unseen(), false, 'a Claude with another pid')

  -- The hook's expression as tests/entry-points.lua evaluates it, its variable unexpanded
  done.mark('$CLAUDE_PID')
  t.eq(done.unseen(), false, 'no pid')
end)
