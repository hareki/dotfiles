--- @class features.git.codediff.utils
local M = {}

-- tabpage -> last explorer-selected file path (relative to git root)
local selected = {}
-- tabpage -> winsaveview() of the modified pane (the working file)
local views = {}

--- Whether the tabpage hosts a codediff diff/merge session
--- @param tabpage integer
--- @return boolean
function M.is_codediff_tab(tabpage)
  -- Requiring codediff (lazy, cmd = 'CodeDiff') would force-load it from every caller (statusline
  -- redraws, git-conflict scans), and while it isn't loaded there are no sessions
  local lifecycle = package.loaded['codediff.ui.lifecycle']
  return lifecycle ~= nil and lifecycle.get_session(tabpage) ~= nil
end

--- Save the modified pane's view; it maps 1:1 to the working file's lines.
--- @param tabpage integer
--- @return table | nil view winsaveview() result, or nil if the pane is gone
local function modified_view(tabpage)
  local lifecycle = require('codediff.ui.lifecycle')
  local _, modified_win = lifecycle.get_windows(tabpage)
  if modified_win and vim.api.nvim_win_is_valid(modified_win) then
    return vim.api.nvim_win_call(modified_win, vim.fn.winsaveview)
  end
end

--- Remember the file selected in the explorer (CodeDiffFileSelect handler).
--- @param args { data: { tabpage: integer, path: string } }
function M.remember_selection(args)
  selected[args.data.tabpage] = args.data.path
end

--- Snapshot the modified pane's scroll/cursor while its window is still alive
--- (TabClosedPre handler). The diff tab's windows close before CodeDiffClose fires.
function M.capture_view()
  local tabpage = vim.api.nvim_get_current_tabpage()
  views[tabpage] = modified_view(tabpage)
end

--- Consume the remembered state of a codediff tab
--- @param tabpage integer
--- @return string | nil path Absolute path of the file last focused in the tab
--- @return table | nil view winsaveview() result to restore on it
local function take_focus_target(tabpage)
  local rel = selected[tabpage]
  local view = modified_view(tabpage) or views[tabpage]
  selected[tabpage] = nil
  views[tabpage] = nil
  if not rel then
    return
  end

  -- git_root is immutable per session; modified_path is not reliably absolute,
  -- so resolve against git_root from the still-alive session.
  local lifecycle = require('codediff.ui.lifecycle')
  local ctx = lifecycle.get_git_context(tabpage)
  local git_root = ctx and ctx.git_root
  if not git_root then
    return
  end

  return vim.fs.joinpath(git_root, rel), view
end

--- @param path string | nil
--- @param view table | nil
local function open_focus_target(path, view)
  if path and vim.fn.filereadable(path) == 1 then
    vim.cmd.edit(vim.fn.fnameescape(path))
    if view then
      vim.fn.winrestview(view)
    end
  end
end

--- Open the last-focused file in the initial tab and restore its scroll position,
--- so quitting feels like simply turning codediff off (CodeDiffClose handler).
--- @param args { data: { tabpage: integer } }
function M.restore_focus(args)
  local path, view = take_focus_target(args.data.tabpage)
  vim.schedule(function()
    open_focus_target(path, view)
  end)
end

--- Close every codediff tab, for the exit path: a session saved with one restores it as an
--- empty layout
--- @return nil
function M.close_tabs()
  for _, tab in ipairs(vim.tbl_filter(M.is_codediff_tab, vim.api.nvim_list_tabpages())) do
    if vim.api.nvim_tabpage_is_valid(tab) then
      -- The last tabpage can't be closed (E784); replace it with the file last focused
      -- in codediff. A blank tab would be saved over the cwd session as an empty layout
      if #vim.api.nvim_list_tabpages() == 1 then
        vim.cmd.tabnew()
        -- Synchronous, unlike restore_focus: a scheduled edit would land after the session save
        open_focus_target(take_focus_target(tab))
      end
      -- Without the switch, tabclose would close whichever tabpage is current instead
      if pcall(vim.api.nvim_set_current_tabpage, tab) then
        vim.cmd.tabclose({ mods = { silent = true } })
      end
    end
  end
end

return M
