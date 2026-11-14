--- @class features.formatting.conform-nvim.style-enforcer.progress.CreateOpts
--- @field client_name  string          -- Label that Noice prints
--- @field pending_ms   integer         -- Delay (in ms) before the first message is shown

--- @class features.formatting.conform-nvim.style-enforcer.progress.Handle
--- @field token          string
--- @field client_name    string
--- @field _pending       boolean
--- @field _cached_kind   'begin' | 'report' | 'end' | nil
--- @field _cached_title  string | nil
--- @field _cached_perc   number | nil
--- @field _timer         uv.uv_timer_t | nil
--- @field start          fun(self: features.formatting.conform-nvim.style-enforcer.progress.Handle, title: string)
--- @field report         fun(self: features.formatting.conform-nvim.style-enforcer.progress.Handle, title?: string, percentage?: number)
--- @field finish         fun(self: features.formatting.conform-nvim.style-enforcer.progress.Handle)

--- @class features.formatting.conform-nvim.style-enforcer.progress
local M = {}

local ProgressHandle = {}
ProgressHandle.__index = ProgressHandle --[[@as features.formatting.conform-nvim.style-enforcer.progress.Handle]]

--- @private
--- @param kind       'begin' | 'report' | 'end'
--- @param title      string | nil
--- @param percentage number | nil
function ProgressHandle:_send(kind, title, percentage)
  local noice_progress = require('noice.lsp.progress')
  -- No client id: the noice fork shows such a report as the editor's own, under `client`
  noice_progress.progress({
    params = {
      token = self.token,
      value = {
        kind = kind,
        title = title,
        percentage = percentage,
        client = self.client_name,
      },
    },
  })
end

-- While pending, cache the latest state; finish() closes the timer, so a run that ends inside the
-- delay shows nothing. After the delay, events go straight to Noice
--- @private
--- @param kind       'begin' | 'report' | 'end'
--- @param title      string | nil
--- @param percentage number | nil
function ProgressHandle:_queue_or_send(kind, title, percentage)
  if self._pending then
    self._cached_kind = kind
    self._cached_title = title
    self._cached_perc = percentage
  else
    self:_send(kind, title, percentage)
  end
end

--- Start the progress notification (sends 'begin' kind)
--- @param title string
--- @return nil
function ProgressHandle:start(title)
  self:_queue_or_send('begin', title)
end

--- Update the progress notification (sends 'report' kind)
--- @param title? string
--- @param percentage? number Current percentage (0-100)
--- @return nil
function ProgressHandle:report(title, percentage)
  self:_queue_or_send('report', title, percentage)
end

--- Complete the progress notification (sends 'end' kind), stopping any pending timer
--- @return nil
function ProgressHandle:finish()
  Snacks.util.stop(self._timer)
  self:_queue_or_send('end')
end

--- Create an LSP-style progress handle, shown after pending_ms to spare fast operations a flicker
--- @param opts features.formatting.conform-nvim.style-enforcer.progress.CreateOpts
--- @return features.formatting.conform-nvim.style-enforcer.progress.Handle handle
function M.create(opts)
  --- @type features.formatting.conform-nvim.style-enforcer.progress.Handle
  local handle = setmetatable({
    token = 'token:' .. vim.uv.hrtime(),
    client_name = opts.client_name,
    _pending = true,
  }, ProgressHandle)

  handle._timer = vim.defer_fn(function()
    handle._pending = false

    -- A cached 'end' shows nothing. finish() closes this timer, so this sees 'end' only from a run
    -- ending in the iteration that fires it: libuv runs timers after the poll that queues finish()
    if handle._cached_kind and handle._cached_kind ~= 'end' then
      ProgressHandle._send(handle, handle._cached_kind, handle._cached_title, handle._cached_perc)
    end
  end, opts.pending_ms)

  return handle
end

return M
