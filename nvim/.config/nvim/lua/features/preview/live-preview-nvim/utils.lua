--- @class features.preview.live-preview-nvim.utils
local M = {}

--- @class features.preview.live-preview-nvim.utils.State
--- @field port integer? The configured port, since start() replaces livepreview.config's

--- @type features.preview.live-preview-nvim.utils.State
local state = {
  port = nil,
}

-- Swap this file to change the pages' tab icon (any image type); it's inlined as a data URI
local FAVICON_PATH = vim.fs.joinpath(
  vim.fn.stdpath('config'),
  'lua/features/preview/live-preview-nvim/assets/vscode-live-server.svg'
)

-- toHTML() only gets the file's content, so each page names its tab after its own URL
local TITLE_SCRIPT =
  "<script>document.title = decodeURIComponent(location.pathname.split('/').pop())</script>"

--- The first port from `port` up that nothing listens on, else `port`, by the same lsof check the
--- plugin's start warns from; a bind can't tell, since macOS lets one share a port with a listener
--- @param port integer
--- @return integer
local function free_port(port)
  local livepreview_utils = require('livepreview.utils')

  for candidate = port, 65535 do
    if #livepreview_utils.processes_listening_on_port(candidate) == 0 then
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

--- The port the preview server listens on, nil while none runs; polling never loads the plugin
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

local function warn_unsupported()
  Notifier.warn('Only Markdown, HTML, AsciiDoc and SVG files can be previewed', {
    title = 'Live Preview',
  })
end

--- Preview `path` (default: the current buffer, never another loaded file as a bare start does),
--- on the first free port above the configured one when another nvim holds it
--- @param path? string
function M.start(path)
  local livepreview_config = require('livepreview.config')
  local livepreview_utils = require('livepreview.utils')

  path = path or vim.api.nvim_buf_get_name(0)
  if not livepreview_utils.supported_filetype(path) then
    warn_unsupported()
    return
  end

  livepreview_config.set({
    -- Keep a running server's port: the plugin closes and rebinds it in one tick, so its tabs,
    -- which reload as their socket closes, land on the new server
    port = M.running_port() or free_port(state.port),
  })

  -- As a list, so the command gets a path with spaces as one argument
  vim.cmd.LivePreview({ args = { 'start', path } })
end

--- Preview the nvim-tree node under the cursor
function M.start_tree_node()
  local tree = require('features.navigation.nvim-tree-lua.utils')

  local node = tree.node_under_cursor()
  if not node then
    return
  end

  -- supported_filetype() reads only the extension, so it would pass a `docs.md/`
  if node.is_folder then
    warn_unsupported()
    return
  end

  M.start(node.path)
end

--- Preview the file on the Trouble row under the cursor
function M.start_trouble_row()
  local trouble = require('features.diagnostics.trouble-nvim.utils')

  local files = trouble.files_under_cursor()
  if #files == 0 then
    return
  end

  -- Like a folder in the tree, a row of several files (a directory's) has no one file to preview
  if #files > 1 then
    warn_unsupported()
    return
  end

  M.start(files[1])
end

--- Pick a previewable file with the Snacks finder: the plugin's walks the whole cwd synchronously
function M.pick()
  Snacks.picker.files({
    title = 'Live Preview',
    -- The extensions livepreview.utils.supported_filetype() accepts
    ft = { 'md', 'markdown', 'html', 'adoc', 'asciidoc', 'svg' },
    confirm = function(picker, item, action)
      -- From insert mode, jump opens the file a tick later, so start would see the previous buffer
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

--- Refresh the statusline when the server starts or stops, ahead of lualine's timed refresh
local function patch_server_lifecycle()
  local livepreview = require('livepreview')

  -- Every caller goes through the module, so wrapping these reaches every start and stop
  for _, name in ipairs({ 'start', 'close' }) do
    local fn = livepreview[name]
    livepreview[name] = function(...)
      local result = fn(...)
      UI.statusline.refresh()
      return result
    end
  end
end

--- Apply `opts`, keeping their port for start(), and patch the page template and server lifecycle
--- @param opts LivePreviewConfig
function M.setup(opts)
  local livepreview_config = require('livepreview.config')

  livepreview_config.set(opts)
  state.port = livepreview_config.config.port
  patch_template()
  patch_server_lifecycle()
end

return M
