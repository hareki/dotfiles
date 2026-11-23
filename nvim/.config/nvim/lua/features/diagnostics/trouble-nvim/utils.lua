--- @class features.diagnostics.trouble-nvim.utils
local M = {}

--- Jump [count] items forward/backward in the open trouble view, else in the quickfix list
--- @param direction 'next' | 'prev'
function M.jump(direction)
  local trouble = require('trouble')

  if trouble.is_open() then
    -- Trouble's next and prev read v:count1 themselves
    --- @diagnostic disable-next-line: missing-parameter, missing-fields
    trouble[direction]({ jump = true })
  else
    local ok, err =
      pcall(vim.cmd[direction == 'next' and 'cnext' or 'cprev'], { count = vim.v.count1 })
    if not ok then
      -- A chunk: Vim's error text is not markdown
      Notifier.error({ { tostring(err), 'Normal' } }, { title = 'Quickfix' })
    end
  end
end

--- Open a picker's results in Trouble, whose snacks source asserts every item has a file or a
--- buffer: a picker of keymaps or commands warns instead
--- @param picker snacks.Picker
function M.snacks_to_trouble(picker)
  -- The items the source's default "smart" open takes: the selection, else every item
  local items = picker:selected()
  if #items == 0 then
    items = picker:items()
  end

  for _, item in ipairs(items) do
    if not item.file and not item.buf then
      local source = picker.opts.source
      local name = source and string.format('`%s` ', source) or ''
      Notifier.warn(
        string.format('The %sSnacks picker has no files to send to Trouble', name),
        { title = 'Snacks Picker' }
      )
      return
    end
  end

  local snacks_source = require('trouble.sources.snacks')
  snacks_source.open(picker)
end

M.SNACKS_WINBAR = "%{%v:lua.require'features.diagnostics.trouble-nvim.utils'.snacks_title()%}"

--- The pinned title of a list sent from a Snacks picker: icon, name and item count
--- @return string winbar
function M.snacks_title()
  local snacks_source = require('trouble.sources.snacks')
  return string.format(
    '%%#TroubleSnacksIcon# %s %%#Title#Snacks %%#TroubleSnacksCount#%d',
    Conf.icons.tools.SNACKS,
    #snacks_source.items
  )
end

--- Trouble's own dirname takes its trailing slash from `:p`, which adds one only to a directory
--- still on disk, so `{dirname}{basename}` glues a deleted file's two parts together
--- @param ctx trouble.Formatter.ctx
--- @return trouble.Format
function M.format_dirname(ctx)
  local dir = vim.fn.fnamemodify(ctx.item.dirname --[[@as string]], ':p:~:.')
  if dir ~= '' and not vim.endswith(dir, '/') then
    dir = dir .. '/'
  end
  return { text = dir }
end

--- Move focus from the trouble list into its preview float, with buffer-local keys to get back
function M.toggle_focus()
  local preview_manager = require('trouble.view.preview')
  local preview = preview_manager.preview

  if not preview then
    return
  end

  local trouble_win = vim.api.nvim_get_current_win()
  local keymap = require('utils.keymap')
  local popup = require('utils.popup')
  local map = keymap.buf_mapper(preview.buf)

  popup.focus_win(preview.win)

  map('n', '<Tab>', function()
    popup.focus_win(trouble_win)
  end, 'Focus Trouble Window')

  map('n', '<CR>', function()
    local trouble_view = require('trouble.view')
    local first_view = trouble_view.get({ open = true })[1]
    if first_view and preview.item then
      first_view.view:jump(preview.item)
    end
  end, 'Jump to Item')

  map('n', 'q', function()
    popup.focus_win(trouble_win)
    preview_manager.close()
  end, 'Close Preview')
end

return M
