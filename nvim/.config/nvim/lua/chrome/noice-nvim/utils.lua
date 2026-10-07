--- @class chrome.noice.utils
local M = {}

local PROGRESS_TIMEOUT_MS = 30 * 1000

--- Close every noice progress item after `PROGRESS_TIMEOUT_MS`. noice only closes an item on its
--- 'end' notification (or when the client exits), and re-renders it until then, so a server that
--- never ends a token leaves its spinner up forever, outliving the mini view's own timeout.
function M.cap_progress_lifetime()
  local progress = require('noice.lsp.progress')
  local handle_progress = progress.progress

  -- Tokens closed by the cap, muted until the server ends them or reuses them for a new 'begin',
  -- so the stuck token's late reports can't bring the item back
  --- @type table<string, true>
  local expired = {}

  progress.progress = function(data)
    local params = data.params
    -- noice's own key for `progress._progress`
    local id = data.client_id .. '.' .. params.token
    local kind = params.value.kind

    if expired[id] and kind ~= 'begin' then
      if kind == 'end' then
        expired[id] = nil
      end
      return
    end
    expired[id] = nil

    local is_new = progress._progress[id] == nil
    handle_progress(data)

    local message = progress._progress[id]
    if is_new and message then
      vim.defer_fn(function()
        -- Skip when noice already closed this item (the token ended or the client exited), even
        -- if the token has since been reused for a new item
        if progress._progress[id] == message then
          expired[id] = true
          progress.close(id)
        end
      end, PROGRESS_TIMEOUT_MS)
    end
  end
end

return M
