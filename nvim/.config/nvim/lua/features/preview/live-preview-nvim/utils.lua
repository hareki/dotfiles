--- @class features.preview.live-preview.utils
local M = {}

-- Swap this file to change the preview pages' tab icon (any image type). It's inlined as a
-- data URI, so it never has to sit under the server's webroot
local FAVICON_PATH = vim.fn.stdpath('config') .. '/assets/live-preview/favicon.svg'

-- toHTML() only gets the file's content, so each page names its tab after its own URL
local TITLE_SCRIPT =
  "<script>document.title = decodeURIComponent(location.pathname.split('/').pop())</script>"

--- Bind a throwaway listener to check that `port` is free; port 0 lets the OS pick a free one
--- @param address string
--- @param port integer
--- @return integer? port The bound port, nil when it's taken
local function probe_port(address, port)
  local tcp = assert(vim.uv.new_tcp())
  -- libuv may defer bind()'s EADDRINUSE to listen()
  local ok = tcp:bind(address, port) and tcp:listen(1, function() end)
  local sockname = ok and tcp:getsockname()
  tcp:close()
  return sockname and sockname.port
end

--- The favicon `<link>` with the file inlined
--- @return string
local function favicon_link()
  local content_type = require('livepreview.server.utils.content_type')

  local mime = content_type.get(FAVICON_PATH)
  local data = vim.base64.encode(vim.fn.readblob(FAVICON_PATH))
  return string.format('<link rel="icon" href="data:%s;base64,%s">', mime, data)
end

--- Preview the current buffer. Unlike `:LivePreview start`, it never falls back to another
--- loaded file, and when another process, e.g. a second nvim's preview, holds the default port,
--- it moves to a free one instead of failing
function M.start()
  local livepreview = require('livepreview')
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
    port = livepreview.is_running() and livepreview_config.config.port
      or probe_port(address, livepreview_config.default.port)
      or probe_port(address, 0),
  })

  vim.cmd.LivePreview('start')
end

--- Pick a previewable file with the Snacks file finder, which skips ignored files, unlike the
--- plugin's picker that walks the whole cwd synchronously (node_modules included)
function M.pick()
  local actions = require('core.snacks-nvim.actions')

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
function M.patch_template()
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

return M
