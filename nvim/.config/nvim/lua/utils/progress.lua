--- @class utils.progress.CreateOpts
--- @field client_name  string          -- Label that Noice prints
--- @field bufnr        integer         -- Buffer whose LSP client id is sampled
--- @field pending_ms   integer         -- Delay (in ms) before the first message is shown

--- @class utils.progress.Handle
--- @field token          string
--- @field client_id      integer | nil
--- @field client_name    string
--- @field _pending       boolean
--- @field _cached_kind   'begin' | 'report' | 'end' | nil
--- @field _cached_title  string | nil
--- @field _cached_perc   number | nil
--- @field _timer         uv.uv_timer_t | nil
--- @field start          fun(self: utils.progress.Handle, title: string)
--- @field report         fun(self: utils.progress.Handle, title?: string, percentage?: number)
--- @field finish         fun(self: utils.progress.Handle)

--- @class utils.progress
local M = {}

--- @param bufnr integer
--- @return integer | nil
local function get_valid_client_id(bufnr)
  -- Noice drops progress whose client id isn't a live client (there's no anonymous id), so fall
  -- back to any running client, or nil when none runs
  local client = vim.lsp.get_clients({ bufnr = bufnr })[1] or vim.lsp.get_clients()[1]
  return client and client.id
end

local ProgressHandle = {}
ProgressHandle.__index = ProgressHandle --[[@as utils.progress.Handle]]

--- @private
--- @param kind       'begin' | 'report' | 'end'
--- @param title      string | nil
--- @param percentage number | nil
function ProgressHandle:_send(kind, title, percentage)
  -- Noice can't render progress without a real client to attribute it to
  if not self.client_id then
    return
  end

  local noice_progress = require('noice.lsp.progress')
  noice_progress.progress({
    client_id = self.client_id,
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

-- While pending, cache the latest state; an 'end' cached before the delay elapses aborts the
-- flush, so nothing shows. After the delay, events go straight to Noice
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

--- Complete the progress notification (sends 'end' kind)
--- Cancels any pending timer and closes the progress display.
--- @return nil
function ProgressHandle:finish()
  Snacks.util.stop(self._timer)
  self:_queue_or_send('end')
end

--- Create a new progress handle for showing LSP-style progress notifications
--- Delays display by pending_ms to avoid flicker for fast operations.
--- @param opts utils.progress.CreateOpts
--- @return utils.progress.Handle handle
function M.create(opts)
  --- @type utils.progress.Handle
  local handle = setmetatable({
    token = 'token:' .. vim.uv.hrtime(),
    client_id = get_valid_client_id(opts.bufnr),
    client_name = opts.client_name,
    _pending = true,
  }, ProgressHandle)

  handle._timer = vim.defer_fn(function()
    handle._pending = false

    -- 'end' cached during the pending window means abort: show nothing.
    if handle._cached_kind and handle._cached_kind ~= 'end' then
      ProgressHandle._send(handle, handle._cached_kind, handle._cached_title, handle._cached_perc)
    end
  end, opts.pending_ms)

  return handle
end

return M
