--- @class core.snacks.pickers.sources.notify
local M = {}

--- Open a notification in a centered float, sized to its content up to the inline popup caps
--- @param notif notify.Record
--- @return nil
local function open_float(notif)
  local notify = require('notify')
  local opened = notify.open(notif)
  local width = math.min(opened.width, UI.layout.inline_max_width())
  local height = math.min(opened.height, UI.layout.inline_max_height())
  local col, row = UI.layout.center(width, height)

  vim.bo[opened.buffer].bufhidden = 'wipe'
  local win = vim.api.nvim_open_win(opened.buffer, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    border = 'rounded',
    style = 'minimal',
  })

  vim.wo[win][0].winhighlight =
    string.format('Normal:%s,FloatBorder:%s', opened.highlights.body, opened.highlights.border)
end

--- Show nvim-notify's notification history, newest first, with each message rendered as
--- markdown in the preview
--- @return snacks.Picker
function M.show()
  local notify = require('notify')
  local history = notify.history()

  local items = {}
  for index = #history, 1, -1 do
    local notif = history[index]
    local message = table.concat(notif.message, '\n')

    items[#items + 1] = {
      notif = notif,
      text = notif.title[1] .. ' ' .. message,
      preview = { text = message, ft = 'markdown' },
    }
  end

  return Snacks.picker({
    title = 'Notifications',
    source = 'notify',
    items = items,
    show_empty = true,
    format = function(item)
      local notif = item.notif
      local level_hl = 'Notify' .. notif.level .. 'Title'

      return {
        { os.date('%T', notif.time), 'NotifyLogTime' },
        { ' ' },
        { notif.title[1], 'NotifyLogTitle' },
        { ' ' },
        { notif.icon, level_hl },
        { ' ' },
        { notif.level, level_hl },
        { ' ' },
        { notif.message[1] or '', 'Notify' .. notif.level .. 'Body' },
      }
    end,
    preview = 'preview',
    win = {
      preview = {
        wo = { wrap = true, number = false, relativenumber = false },
      },
    },
    confirm = function(picker, item)
      picker:close()
      if item then
        open_float(item.notif)
      end
    end,
  })
end

return M
