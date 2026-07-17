local M = {}

--- @module 'telescope.actions'
local actions = Defer.on_exported_call('telescope.actions')

--- @module 'telescope.state'
local state = Defer.on_exported_call('telescope.state')

function M.find_command()
  if 1 == vim.fn.executable('rg') then
    return { 'rg', '--files', '--color', 'never', '-g', '!.git' }
  elseif 1 == vim.fn.executable('fd') then
    return { 'fd', '--type', 'f', '--color', 'never', '-E', '.git' }
  elseif 1 == vim.fn.executable('fdfind') then
    return { 'fdfind', '--type', 'f', '--color', 'never', '-E', '.git' }
  elseif 1 == vim.fn.executable('find') and vim.fn.has('win32') == 0 then
    return { 'find', '.', '-type', 'f' }
  elseif 1 == vim.fn.executable('where') then
    return { 'where', '/r', '.', '*' }
  end
end

-- Heavily modify the "vertical" strategy, the point is to merge prompt and results windows
-- In general, this layout mimics the "dropdown" theme, but take the "previewer" panel into account of the height layout
-- https://www.reddit.com/r/neovim/comments/10asvod/telescopenvim_how_to_remove_windows_titles_and/
function M.install_vertical_layout()
  local layout_strategies = require('telescope.pickers.layout_strategies')
  local default_vertical = layout_strategies.vertical

  layout_strategies.vertical = function(self, max_columns, max_lines, layout_config)
    local size = self.layout_config.vertical.size or 'lg'
    -- 0. Use the default vertical layout as the base
    local layout = default_vertical(self, max_columns, max_lines, layout_config)
    -- 1. Collapse the blank row between *prompt* and *results*
    layout.results.line = layout.results.line - 1
    layout.results.height = layout.results.height + 1

    -- 2. Seems like telescope.nvim exclude the statusline when centering the layout,
    -- Which is different from our logic in `size_utils.get_float_config('lg')`
    -- So we need to adjust/shift the position if needed
    local target_row = UI.layout.popup(size, true).row
    -- The top most component is the prompt window, so we use it as the anchor to adjust the position
    local top_line = layout.prompt.line

    -- Minus 1 for the top border and the other one
    -- Minus 1 for the difference of how nvim_open_win and telescope handle the position:
    -- nvim_open_win puts the window BELOW the specified row, while telescope doesn't
    top_line = top_line - 2

    local shift = target_row - top_line
    if shift ~= 0 then
      for _, win in ipairs({ layout.prompt, layout.results, layout.preview }) do
        if win then
          win.line = win.line + shift
        end
      end
    end

    return layout
  end
end

-- https://github.com/nvim-telescope/telescope.nvim/issues/2778#issuecomment-2202572413
--- @param prompt_bufnr integer
function M.toggle_focus_preview(prompt_bufnr)
  local actions_state = require('telescope.actions.state')
  local common = require('utils.common')

  local picker = actions_state.get_current_picker(prompt_bufnr)
  local prompt_win = picker.prompt_win
  local status = state.get_status(prompt_bufnr)
  local previewer_winid = status and status.preview_win or nil
  local previewer_bufnr = previewer_winid and vim.api.nvim_win_get_buf(previewer_winid) or nil

  if not (previewer_winid and vim.api.nvim_win_is_valid(previewer_winid)) then
    common.focus_win(prompt_win)
    return
  end

  local set_cursorline = UI.cursorline.set_cursorline
  local default_modifiable = previewer_bufnr and vim.bo[previewer_bufnr].modifiable or false

  vim.bo[previewer_bufnr].modifiable = false

  local function restore_buf_state()
    vim.bo[previewer_bufnr].modifiable = default_modifiable
  end

  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, {
      buffer = previewer_bufnr,
      desc = desc,
    })
  end

  map('n', '<Tab>', function()
    restore_buf_state()
    set_cursorline(false, previewer_winid)
    common.focus_win(prompt_win)
  end, 'Focus Prompt Window')

  map('n', 'q', function()
    restore_buf_state()
    actions.close(prompt_bufnr)
  end, 'Close Telescope')

  map('n', '<CR>', function()
    restore_buf_state()
    actions.select_default(prompt_bufnr)
  end, 'Select Default')

  if common.focus_win(previewer_winid) then
    vim.schedule(function()
      set_cursorline(true, previewer_winid)
    end)
  end
end

function M.setup_previewer_autocmd()
  vim.api.nvim_create_autocmd('User', {
    group = vim.api.nvim_create_augroup('navigation.telescope.previewer-loaded', { clear = true }),
    pattern = 'TelescopePreviewerLoaded',

    -- Make it look more like the actual window we use to edit files
    callback = function(ev)
      local buftype = vim.bo[ev.buf].buftype
      if buftype == 'terminal' then
        return
      end

      vim.opt_local.number = true
      vim.opt_local.relativenumber = true
      vim.opt_local.numberwidth = 1
      vim.opt_local.cursorline = true
      vim.opt_local.cursorlineopt = 'number'
    end,
  })
end

--- @param direction 'up' | 'down'
function M.scroll_results(direction)
  --- @param prompt_bufnr integer
  return function(prompt_bufnr)
    local action_set = require('telescope.actions.set')

    local status = state.get_status(prompt_bufnr)
    local winid = status.layout.results.winid
    local default_speed = vim.api.nvim_win_get_height(winid) / 2
    local speed = status.picker.layout_config.scroll_speed or default_speed

    action_set.shift_selection(prompt_bufnr, math.floor(speed) * (direction == 'up' and -1 or 1))

    vim.api.nvim_win_call(winid, function()
      vim.cmd.normal({ args = { 'zz' }, bang = true })
    end)
  end
end

--- @param prompt_bufnr integer
function M.telescope_to_trouble(prompt_bufnr)
  -- Trouble's telescope source requires every entry to resolve to a file
  -- location (path/filename/bufnr); non-file pickers (e.g. notification
  -- history) would otherwise crash it with "filename is required".
  local entry = state.get_global_key('selected_entry')
  if entry and not (entry.path or entry.filename or entry.bufnr) then
    Notifier.warn('This picker has no file locations to send to Trouble')
    return
  end

  local trouble_sources = require('trouble.sources.telescope')
  trouble_sources.open(prompt_bufnr)
end

--- @param source string
function M.trouble_open(source)
  return function(bufnr)
    actions.close(bufnr)
    local trouble = require('trouble')
    trouble.open(source)
  end
end

return M
