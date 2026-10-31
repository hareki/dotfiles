--- @class features.search.snacks.actions
local M = {}

--- Whether the preview is shown, for the sources that keep it across openings (their
--- keymaps open them with it); add a source here to have toggle_preview remember it
--- @type table<string, boolean>
M.preview_shown = { files = true }

--- Wrap default toggle_preview to remember the choice for the sources in M.preview_shown
--- @module 'snacks'
--- @param picker snacks.Picker
function M.toggle_preview(picker)
  picker:toggle('preview')

  local source = picker.opts.source
  if source and M.preview_shown[source] ~= nil then
    M.preview_shown[source] = not M.preview_shown[source]
  end
end

--- @param picker snacks.Picker
--- @param direction 1 | -1 Down or up, flipped by the list itself for reversed layouts
local function move_half_page(picker, direction)
  -- state.height follows window resizes, unlike the state.scroll snacks samples once on show
  local half = math.max(1, math.floor(picker.list.state.height / 2))
  picker.list:move(direction * half)
end

--- @param picker snacks.Picker
function M.list_half_page_down(picker)
  move_half_page(picker, 1)
end

--- @param picker snacks.Picker
function M.list_half_page_up(picker)
  move_half_page(picker, -1)
end

--- Toggle focus between the picker input and preview window
--- @param picker snacks.Picker
--- @return nil
function M.toggle_preview_focus(picker)
  local common = require('utils.common')
  local preview_win = picker.preview.win.win

  -- No-op for pickers with `preview = false` (e.g. keymaps), where <Tab> is still bound
  if not preview_win then
    return
  end

  if picker:current_win() == 'preview' then
    common.focus_win(picker.input.win.win)
    UI.cursorline.set_cursorline(false, preview_win)
  elseif common.focus_win(preview_win) then
    UI.cursorline.set_cursorline(true, preview_win)
  end
end

--- Send picker results to Trouble for persistent viewing
--- @param picker snacks.Picker
--- @return nil
function M.snacks_to_trouble(picker)
  local trouble_sources = require('trouble.sources.snacks')
  trouble_sources.open(picker)
end

--- The todo_comments source's snacks_to_trouble: Trouble's todo view, filtered to its keywords
--- @param picker snacks.Picker
--- @return nil
function M.todo_to_trouble(picker)
  local keywords = picker
    --- @module "todo-comments"
    .opts --[[@as snacks.picker.todo.Config]]
    .keywords

  picker:close()
  local trouble = require('trouble')
  --- @diagnostic disable-next-line: missing-fields
  trouble.toggle({
    mode = 'todo',
    filter = keywords and { tag = keywords },
  })
end

--- The tabs source's confirm: switch to the tabpage under the cursor
--- @param picker snacks.Picker
--- @param item? snacks.picker.Item The item under the cursor
--- @return nil
function M.tab_switch(picker, item)
  -- Leave insert mode first, or picker:close()'s stopinsert moves the target tab's cursor
  picker:norm(function()
    picker:close()
    if item and vim.api.nvim_tabpage_is_valid(item.tab) then
      vim.api.nvim_set_current_tabpage(item.tab)
    end
  end)
end

--- Close the tabpage hosting the picker's floats and resume the picker where nvim lands
--- @param picker snacks.Picker
--- @return nil
local function close_current_tab(picker)
  local insert = vim.fn.mode():sub(1, 1) == 'i'

  -- Leave insert mode first, or picker:close()'s stopinsert lands where the tabclose leaves us
  picker:norm(function()
    picker.list:set_selected() -- Don't resume with the closed tabs still selected
    picker:close()
    vim.cmd.tabclose()

    -- Focusing the resumed input runs its BufEnter startinsert!, which restores insert mode
    local resumed = Snacks.picker.resume({ source = picker.opts.source })
    if not resumed or insert then
      return
    end

    -- Cancel that startinsert! so x can be repeated. The picker shows synchronously when resumed
    -- with an empty pattern (the matcher's fast path), otherwise later, right before on_show runs
    if resumed.shown then
      vim.cmd.stopinsert()
    else
      resumed.opts.on_show = function()
        vim.cmd.stopinsert()
      end
    end
  end)
end

--- Close the selected tabpages (or the one under the cursor), the tabs source's bufdelete
--- @param picker snacks.Picker
--- @return nil
function M.tab_close(picker)
  picker.preview:reset()
  local current_tab = vim.api.nvim_get_current_tabpage()
  local close_current = false

  for _, item in ipairs(picker:selected({ fallback = true })) do
    if item.tab == current_tab then
      close_current = true -- Closing it takes the picker with it, so it goes last
    elseif vim.api.nvim_tabpage_is_valid(item.tab) then
      vim.cmd.tabclose(vim.api.nvim_tabpage_get_number(item.tab))
    end
  end

  if close_current then
    if #vim.api.nvim_list_tabpages() > 1 then
      close_current_tab(picker)
      return
    end
    Notifier.warn('Cannot close the last tab', { title = 'Snacks Picker' }) -- E784
  end

  picker:refresh()
end

return M
