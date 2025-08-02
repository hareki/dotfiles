---@class utils.progress.CreateOpts
---@field token        string?         -- Stable id that groups begin/report/end
---@field client_name  string?         -- Label that Noice prints
---@field client_id    integer?        -- Explicit client-id (fallback: first LSP)
---@field pending_ms   integer?        -- Delay (in ms) before the first message is shown

---@class utils.progress.Handle
---@field token          string
---@field client_id      integer
---@field client_name    string
---@field pending_ms     integer
---@field _pending       boolean
---@field _aborted       boolean
---@field _cached_kind   'begin'|'report'|nil
---@field _cached_title  string|nil
---@field _cached_perc   number|nil
---@field start          fun(self: utils.progress.Handle, title?: string, percentage?: number)
---@field report         fun(self: utils.progress.Handle, title?: string, percentage?: number)
---@field finish         fun(self: utils.progress.Handle, title?: string)

---@class utils.progress
local M = {}

local noice_prog = require('noice.lsp.progress')

---@param bufnr integer|nil
---@return integer
local function get_valid_client_id(bufnr)
  local client = vim.lsp.get_clients({ bufnr = bufnr or 0 })[1]
  return client and client.id or 0 -- 0 is the “anonymous” id in LSP
end

local ProgressHandle = {}
ProgressHandle.__index = ProgressHandle --[[@as utils.progress.Handle]]

-- Internal low‑level sender ---------------------------------------------------
---@private
---@param kind       'begin'|'report'|'end'
---@param title      string|nil
---@param percentage number|nil
function ProgressHandle:_send(kind, title, percentage)
  noice_prog.progress({
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

-- When progress is still *pending*, we either cache the last state or abort
-- if `finish` is triggered before the delay elapses. Once the delay has passed
-- (`self._pending == false`) all events go straight to Noice.
---@private
---@param kind       'begin'|'report'|'end'
---@param title      string|nil
---@param percentage number|nil
function ProgressHandle:_queue_or_send(kind, title, percentage)
  if self._pending then
    if kind == 'end' then
      -- Abort: nothing should ever be shown
      self._aborted = true
    else
      -- Remember only the latest state so we comply with the spec
      self._cached_kind = kind
      self._cached_title = title
      self._cached_perc = percentage
    end
  else
    -- Normal behaviour
    self:_send(kind, title, percentage)
  end
end

-- Public helpers -------------------------------------------------------------
function ProgressHandle:start(title, percentage)
  self:_queue_or_send('begin', title, percentage)
end

function ProgressHandle:report(title, percentage)
  self:_queue_or_send('report', title, percentage)
end

function ProgressHandle:finish(title)
  -- percentage is not sent for the `end` kind
  self:_queue_or_send('end', title, nil)
end

-- Factory --------------------------------------------------------------------
---@param opts utils.progress.CreateOpts|nil
---@return utils.progress.Handle
function M.create(opts)
  opts = opts or {}

  local pending_ms = opts.pending_ms or 0
  local token = opts.token or ('token:' .. vim.loop.hrtime())
  local client_name = opts.client_name or 'progress'
  local client_id = opts.client_id or get_valid_client_id(vim.api.nvim_get_current_buf())

  ---@type utils.progress.Handle
  local handle = setmetatable({
    token = token,
    client_id = client_id,
    client_name = client_name,
    pending_ms = pending_ms,
    _pending = pending_ms > 0,
    _aborted = false,
    _cached_kind = nil,
  }, ProgressHandle)

  -- If a delay is requested, defer the first real send
  if pending_ms > 0 then
    vim.defer_fn(function()
      -- If aborted we simply exit ‑ nothing should be displayed
      if handle._aborted then
        return
      end

      -- Mark the handle as ready; future events go through immediately
      handle._pending = false

      -- Flush the *latest* cached state (if any)
      if handle._cached_kind then
        ProgressHandle._send(handle, handle._cached_kind, handle._cached_title, handle._cached_perc)
      end
    end, pending_ms)
  end

  return handle
end

return M
