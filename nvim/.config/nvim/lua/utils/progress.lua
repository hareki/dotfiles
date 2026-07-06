--- @class utils.progress.CreateOpts
--- @field token        string?         -- Stable id that groups begin/report/end
--- @field client_name  string?         -- Label that Noice prints
--- @field client_id    integer?        -- Explicit client-id (fallback: first LSP)
--- @field pending_ms   integer?        -- Delay (in ms) before the first message is shown

--- @class utils.progress.Handle
--- @field token          string
--- @field client_id      integer
--- @field client_name    string
--- @field _pending       boolean
--- @field _cached_kind   'begin' | 'report' | 'end' | nil
--- @field _cached_title  string | nil
--- @field _cached_perc   number | nil
--- @field _timer         uv.uv_timer_t | nil
--- @field start          fun(self: utils.progress.Handle, title?: string, percentage?: number)
--- @field report         fun(self: utils.progress.Handle, title?: string, percentage?: number)
--- @field finish         fun(self: utils.progress.Handle, title?: string)

--- @class utils.progress
local M = {}

--- @param bufnr integer | nil
--- @return integer
local function get_valid_client_id(bufnr)
  local client = vim.lsp.get_clients({ bufnr = bufnr or 0 })[1]
  return client and client.id or 0 -- 0 is the “anonymous” id in LSP
end

local ProgressHandle = {}
ProgressHandle.__index = ProgressHandle --[[@as utils.progress.Handle]]

-- [[ Internal low‑level sender ]]
--- @private
--- @param kind       'begin' | 'report' | 'end'
--- @param title      string | nil
--- @param percentage number | nil
function ProgressHandle:_send(kind, title, percentage)
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

-- When progress is still *pending*, we cache the latest state. If `finish` is
-- triggered before the delay elapses, we cache 'end' which the timer flush
-- treats as an abort (nothing is ever shown). Once delay passes
-- (`self._pending == false`), all events go straight to Noice.
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

-- [[ Public helpers ]]
--- Start the progress notification (sends 'begin' kind)
--- @param title? string The progress title to display
--- @param percentage? number Initial percentage (0-100)
--- @return nil
function ProgressHandle:start(title, percentage)
  self:_queue_or_send('begin', title, percentage)
end

--- Update the progress notification (sends 'report' kind)
--- @param title? string Updated progress title
--- @param percentage? number Current percentage (0-100)
--- @return nil
function ProgressHandle:report(title, percentage)
  self:_queue_or_send('report', title, percentage)
end

--- Complete the progress notification (sends 'end' kind)
--- Cancels any pending timer and closes the progress display.
--- @param title? string Final title to display
--- @return nil
function ProgressHandle:finish(title)
  if self._timer then
    pcall(self._timer.stop, self._timer)
    pcall(self._timer.close, self._timer)
    self._timer = nil
  end
  self:_queue_or_send('end', title, nil) -- Percentage is not sent for the `end` kind
  -- The timer is gone, so nothing will ever flush the pending cache again;
  -- clear the flag so a reused handle sends straight to Noice instead of
  -- caching into the void.
  self._pending = false
end

-- [[ Factory ]]
--- Create a new progress handle for showing LSP-style progress notifications
--- Supports delayed display via pending_ms to avoid flicker for fast operations.
--- @param opts utils.progress.CreateOpts | nil Options (token, client_name, client_id, pending_ms)
--- @return utils.progress.Handle handle Progress handle with start/report/finish methods
function M.create(opts)
  opts = opts or {}

  local pending_ms = opts.pending_ms or 0
  local token = opts.token or ('token:' .. vim.uv.hrtime())
  local client_name = opts.client_name or 'progress'
  -- Note: client_id of 0 means anonymous progress (fallback when no LSP client is available)
  local client_id = opts.client_id or get_valid_client_id(vim.api.nvim_get_current_buf())

  --- @type utils.progress.Handle
  local handle = setmetatable({
    token = token,
    client_id = client_id,
    client_name = client_name,
    _pending = pending_ms > 0,
    _cached_kind = nil,
    _cached_title = nil,
    _cached_perc = nil,
    _timer = nil,
  }, ProgressHandle)

  if pending_ms == 0 then
    return handle
  end

  local timer = vim.uv.new_timer()
  if not timer then
    handle._pending = false
    return handle
  end
  handle._timer = timer

  local function close_timer()
    if handle._timer then
      pcall(handle._timer.stop, handle._timer)
      pcall(handle._timer.close, handle._timer)
      handle._timer = nil
    end
  end

  timer:start(pending_ms, 0, function()
    vim.schedule(function()
      close_timer()
      handle._pending = false

      -- 'end' cached during the pending window means abort: show nothing.
      if handle._cached_kind and handle._cached_kind ~= 'end' then
        ProgressHandle._send(handle, handle._cached_kind, handle._cached_title, handle._cached_perc)
      end
    end)
  end)

  return handle
end

return M
