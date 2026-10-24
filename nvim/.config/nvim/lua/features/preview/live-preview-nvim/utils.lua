--- @class features.preview.live-preview.utils
local M = {}

--- @class features.preview.live-preview.utils.State
--- @field port integer? The configured port, since start() replaces livepreview.config's

--- @type features.preview.live-preview.utils.State
M.state = {
  port = nil,
}

-- Swap this file to change the preview pages' tab icon (any image type). It's inlined as a
-- data URI, so it never has to sit under the server's webroot
local FAVICON_PATH = vim.fn.stdpath('config')
  .. '/lua/features/preview/live-preview-nvim/assets/vscode-live-server.svg'

-- toHTML() only gets the file's content, so each page names its tab after its own URL
local TITLE_SCRIPT =
  "<script>document.title = decodeURIComponent(location.pathname.split('/').pop())</script>"

--- Whether something listens on `port` at `address` or a loopback/wildcard address, since macOS
--- lets a bind to `address` share the port with those (even taking a wildcard one's connections)
--- @param address string
--- @param port integer
--- @return boolean
local function port_in_use(address, port)
  for _, probe_address in ipairs({ address, '127.0.0.1', '::1', '0.0.0.0', '::' }) do
    local tcp = assert(vim.uv.new_tcp())
    -- libuv defers bind()'s EADDRINUSE, and getsockname() reports it without the listen() that
    -- would open the wildcard addresses to incoming connections
    local ok, _, err = tcp:bind(probe_address, port)
    if ok then
      _, _, err = tcp:getsockname()
    end
    tcp:close()
    -- Other errors, e.g. EACCES or no IPv6 stack, aren't a listener
    if err == 'EADDRINUSE' then
      return true
    end
  end
  return false
end

--- The first port from `port` up that nothing listens on, else `port`
--- @param address string
--- @param port integer
--- @return integer
local function free_port(address, port)
  for candidate = port, 65535 do
    if not port_in_use(address, candidate) then
      return candidate
    end
  end
  return port
end

--- The favicon `<link>` with the file inlined
--- @return string
local function favicon_link()
  local content_type = require('livepreview.server.utils.content_type')

  local mime = content_type.get(FAVICON_PATH)
  local data = vim.base64.encode(vim.fn.readblob(FAVICON_PATH))
  return string.format('<link rel="icon" href="data:%s;base64,%s">', mime, data)
end

--- The port the preview server listens on, nil while none runs. Safe to poll on every statusline
--- redraw: it never loads the plugin, since no server exists before its main module is required
--- @return integer?
function M.running_port()
  local livepreview = package.loaded['livepreview']
  if not (livepreview and livepreview.is_running()) then
    return nil
  end

  -- Ask the socket, since livepreview.config's port can change under a running server
  local address = livepreview.serverObj.server:getsockname()
  return address and address.port
end

--- Preview the current buffer, never another loaded file like `:LivePreview start`, moving to the
--- first free port above the configured one while something else (a second nvim) listens there
function M.start()
  local livepreview_config = require('livepreview.config')
  local livepreview_utils = require('livepreview.utils')

  local path = vim.api.nvim_buf_get_name(0)
  if not livepreview_utils.supported_filetype(path) then
    Notifier.warn('Only Markdown, HTML, AsciiDoc and SVG files can be previewed', {
      title = 'Live Preview',
    })
    return
  end

  local address = livepreview_config.config.address --[[@as string]]
  livepreview_config.set({
    -- Keep a running server's port: the plugin closes and rebinds it in one tick, so its tabs,
    -- which reload as their socket closes, land on the new server
    port = M.running_port() or free_port(address, M.state.port),
  })

  vim.cmd.LivePreview('start')
end

--- Pick a previewable file with the Snacks file finder, which skips ignored files, unlike the
--- plugin's picker that walks the whole cwd synchronously (node_modules included)
function M.pick()
  local actions = require('features.search.snacks-nvim.actions')

  Snacks.picker.files({
    title = 'Live Preview',
    -- The extensions livepreview.utils.supported_filetype() accepts
    ft = { 'md', 'markdown', 'html', 'adoc', 'asciidoc', 'svg' },
    layout = {
      --- @diagnostic disable-next-line: assign-type-mismatch Wrong type from snacks
      preview = actions.preview_shown.files,
    },
    confirm = function(picker, item, action)
      -- From insert mode, jump defers opening the file to a later tick, where start would
      -- still see the previous buffer
      picker:norm(function()
        Snacks.picker.actions.jump(picker, item, action)
        if item then
          M.start()
        end
      end)
    end,
  })
end

--- Give the generated Markdown, AsciiDoc and SVG pages the file name as their tab title and the
--- favicon at FAVICON_PATH. HTML files are served as written, keeping their own title and icon
local function patch_template()
  local template = require('livepreview.template')
  local head = favicon_link() .. TITLE_SCRIPT

  -- toHTML() looks these up on the module at call time, so wrapping them reaches every page
  for _, name in ipairs({ 'md2html', 'adoc2html', 'svg2html' }) do
    local render = template[name]
    template[name] = function(...)
      return (render(...):gsub('</head>', head .. '</head>', 1))
    end
  end
end

--- Refresh the statusline whenever the server starts or stops, so its indicator updates right
--- away instead of on lualine's next timed refresh
local function patch_server_lifecycle()
  local livepreview = require('livepreview')

  -- The command, the plugin's picker, start() itself and the exit hook all call these through the
  -- module, so wrapping them reaches every start and stop
  for _, name in ipairs({ 'start', 'close' }) do
    local fn = livepreview[name]
    livepreview[name] = function(...)
      local result = fn(...)
      UI.statusline.refresh()
      return result
    end
  end
end

--- Apply `opts` to the plugin, keeping their port for start(), and patch its page template and
--- server lifecycle
--- @param opts LivePreviewConfig
function M.setup(opts)
  local livepreview_config = require('livepreview.config')

  --- @diagnostic disable-next-line: param-type-mismatch Wrong type from live-preview
  livepreview_config.set(opts)
  M.state.port = livepreview_config.config.port
  patch_template()
  patch_server_lifecycle()
end

return M
