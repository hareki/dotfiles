-- features.ai.claudecode-nvim.done: a finished agent is flagged in the statusline only while its
-- panel is out of sight, from the Stop hook's mark() until the statusline finds the panel showing

local t = require('tests.lib.helpers')
local done = require('features.ai.claudecode-nvim.done')

--- A stand-in panel, gone when the test ends: a focused float on a buffer that claudecode.nvim
--- reports as its terminal
--- @return integer win
local function open_panel()
  local win, buf = t.float(true)
  t.set(package.loaded, 'claudecode.terminal', {
    get_active_terminal_bufnr = function()
      return buf
    end,
  })
  return win
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

--- The agent finishing, as its Stop hook reports it. The flag is the module's own, so when the
--- test ends a panel shows to clear whatever it left
local function finish()
  t.cleanup(function()
    if done.unseen() then
      open_panel()
      t.eq(done.unseen(), false, 'a shown panel clears the flag the test left')
    end
  end)
  done.mark()
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

t.test('a finish before any panel exists is flagged until the statusline finds one', function()
  local code_win = vim.api.nvim_get_current_win()
  await_icon(false, 'a statusline without the icon before the finish')

  finish()
  t.eq(done.unseen(), true, 'unseen after the finish')
  await_icon(true, 'the icon after the finish')

  open_panel()
  vim.api.nvim_set_current_win(code_win)
  await_icon(false, 'the icon to go once the panel shows')
  t.eq(done.unseen(), false, 'unseen after the statusline found the panel')
end)

t.test('a finish under a visible panel is not flagged', function()
  open_panel()
  finish()
  t.eq(done.unseen(), false)
end)

t.test('a finish under a hidden panel is flagged until the panel shows again', function()
  local code_win = vim.api.nvim_get_current_win()
  local win = open_panel()
  hide_panel(win, code_win)

  finish()
  t.eq(done.unseen(), true, 'unseen after the finish')

  -- Focus moving between other windows leaves it
  vim.cmd.split()
  t.settle()
  t.eq(done.unseen(), true, 'unseen after entering another window')
  vim.cmd.close()

  show_panel(win)
  t.eq(done.unseen(), false, 'unseen with the panel showing again')

  -- Seen once: hiding the panel again brings nothing back
  hide_panel(win, code_win)
  t.eq(done.unseen(), false, 'unseen after hiding the panel again')
end)

t.test('a panel in another tab does not count as showing', function()
  open_panel()
  t.tab()

  finish()
  t.eq(done.unseen(), true, 'unseen after the finish')

  vim.cmd.tabclose()
  t.eq(done.unseen(), false, 'unseen back in the tab of the panel')
end)
