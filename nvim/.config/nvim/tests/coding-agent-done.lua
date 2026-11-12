-- features.ai.claudecode-nvim.done: a finished agent is flagged in the statusline only while its
-- panel is out of sight, from the Stop hook's mark() until the panel next shows

local t = require('tests.lib.helpers')
local done = require('features.ai.claudecode-nvim.done')
local component = require('chrome.lualine-nvim.components.coding-agent')

--- A stand-in panel: a focused float on a buffer that claudecode.nvim reports as its terminal
--- @return integer win
local function open_panel()
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    row = 1,
    col = 1,
    width = 10,
    height = 1,
  })
  -- After the window, as claudecode.nvim tracks a terminal only once Snacks has opened it
  package.loaded['claudecode.terminal'] = {
    get_active_terminal_bufnr = function()
      return buf
    end,
  }
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

--- @param win integer
local function close_panel(win)
  vim.api.nvim_win_close(win, true)
  package.loaded['claudecode.terminal'] = nil
end

--- @param msg string
local function await_seen(msg)
  t.wait_for(function()
    return not done.unseen()
  end, msg)
end

--- Wait for the statusline lualine last rendered to show the agent's icon, or to drop it
--- @param shown boolean
--- @param msg string
local function await_icon(shown, msg)
  local icon = vim.trim(Conf.icons.cmp_kinds.CodingAgent)
  t.wait_for(function()
    local text = vim.api.nvim_eval_statusline(vim.o.statusline, {}).str
    return (text:find(icon, 1, true) ~= nil) == shown
  end, msg)
end

t.test('a finish before any panel exists is flagged until one opens', function()
  await_icon(false, 'a statusline without the icon before the finish')

  done.mark()
  t.eq(done.unseen(), true, 'unseen after the finish')
  t.eq(component.cond(), true, 'the component shows')
  await_icon(true, 'the icon after the finish')

  local win = open_panel()
  await_seen('the opened panel to clear the flag')
  t.eq(component.cond(), false, 'the component hides')
  await_icon(false, 'the icon to go once the panel shows')
  close_panel(win)
end)

t.test('a finish under a visible panel is not flagged', function()
  local win = open_panel()
  done.mark()
  t.eq(done.unseen(), false)
  close_panel(win)
end)

t.test('a finish under a hidden panel is flagged until the panel shows again', function()
  local code_win = vim.api.nvim_get_current_win()
  local win = open_panel()
  hide_panel(win, code_win)

  done.mark()
  t.eq(done.unseen(), true, 'unseen after the finish')

  -- Focus moving between other windows leaves it
  vim.cmd.split()
  t.settle()
  t.eq(done.unseen(), true, 'unseen after entering another window')
  vim.cmd.close()

  show_panel(win)
  await_seen('the shown panel to clear the flag')

  -- Seen once: hiding the panel again brings nothing back
  hide_panel(win, code_win)
  t.settle()
  t.eq(done.unseen(), false, 'unseen after hiding the panel again')
  close_panel(win)
end)

t.test('a panel in another tab does not count as showing', function()
  local win = open_panel()
  vim.cmd.tabnew()

  done.mark()
  t.eq(done.unseen(), true, 'unseen after the finish')

  vim.cmd.tabclose()
  await_seen('the panel tab to clear the flag')
  close_panel(win)
end)
