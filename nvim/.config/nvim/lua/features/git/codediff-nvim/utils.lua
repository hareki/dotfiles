--- @class features.git.codediff.utils
local M = {}

-- tabpage -> last explorer-selected file path (relative to git root)
local selected = {}
-- tabpage -> winsaveview() of the modified pane (the working file)
local views = {}

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
--- (TabLeave handler). The diff tab's windows close before CodeDiffClose fires.
function M.capture_view()
  local tabpage = vim.api.nvim_get_current_tabpage()
  views[tabpage] = modified_view(tabpage) or views[tabpage]
end

--- Drop state for tabpages that no longer exist: a codediff tab closed via
--- :tabclose (rather than CodeDiffClose) never reaches restore_focus, which is
--- what normally evicts these entries (TabClosed handler).
function M.evict_closed_tabs()
  for _, state in ipairs({ selected, views }) do
    for tabpage in pairs(state) do
      if not vim.api.nvim_tabpage_is_valid(tabpage) then
        state[tabpage] = nil
      end
    end
  end
end

--- Open the last-focused file in the initial tab and restore its scroll position,
--- so quitting feels like simply turning codediff off (CodeDiffClose handler).
--- @param args { data: { tabpage: integer } }
function M.restore_focus(args)
  local tabpage = args.data.tabpage
  local rel = selected[tabpage]
  local view = modified_view(tabpage) or views[tabpage]
  selected[tabpage] = nil
  views[tabpage] = nil
  if not rel then
    return
  end

  -- git_root is immutable per session; modified_path is not reliably absolute,
  -- so resolve against git_root from the still-alive session.
  local ok, lifecycle = pcall(require, 'codediff.ui.lifecycle')
  local ctx = ok and lifecycle.get_git_context(tabpage)
  local git_root = ctx and ctx.git_root
  if not git_root then
    return
  end

  local abs = git_root .. '/' .. rel
  vim.schedule(function()
    if vim.fn.filereadable(abs) == 1 then
      vim.cmd.edit(vim.fn.fnameescape(abs))
      if view then
        vim.fn.winrestview(view)
      end
    end
  end)
end

return M
