--- @module 'utils.common'
local common = Defer.on_exported_call('utils.common')

--- @module 'render-markdown'
local render_markdown = Defer.on_exported_call('render-markdown')

--- @class features.preview.snacks.utils
local M = {}

--- @class features.preview.snacks.utils.HoverState
--- @field win integer
--- @field buf integer
--- @field placement snacks.image.Placement
--- @field augroup integer
--- @field release_keymaps fun()

--- @class features.preview.snacks.utils.State
--- @field hover features.preview.snacks.utils.HoverState? The open hover image popup
--- @field page_renders table<integer, table> Each audio page's latest render, by buffer

--- @type features.preview.snacks.utils.State
M.state = {
  hover = nil,
  page_renders = {},
}

local function close()
  local current = M.state.hover
  if not current then
    return
  end

  M.state.hover = nil

  pcall(vim.api.nvim_del_augroup_by_id, current.augroup)
  current.release_keymaps()
  pcall(function()
    current.placement:close()
  end)
  pcall(vim.api.nvim_win_close, current.win, true)
  if vim.api.nvim_buf_is_valid(current.buf) then
    pcall(vim.api.nvim_buf_delete, current.buf, { force = true })
  end
end

--- A hover-unique src path, so the float gets its own kitty graphics ID (no size juggling with
--- an inline placement of the same image) and unsaved edits (`.mmd`) are re-hashed from the buffer
--- @param original_src string | nil  Resolved on-disk file (used when `content` is nil)
--- @param ext string  File extension without leading dot
--- @param content string | nil  Raw bytes to persist (e.g. live buffer text)
--- @return string?
local function build_hover_src(original_src, ext, content)
  local cache = Snacks.image.config.cache
  vim.fn.mkdir(cache, 'p')

  local hash
  if content then
    hash = vim.fn.sha256(content):sub(1, 12)
  else
    if not original_src or vim.fn.filereadable(original_src) == 0 then
      return nil
    end
    local stat = vim.uv.fs_stat(original_src)
    if not stat then
      return nil
    end
    -- Include nsec + size so a second edit within the same second doesn't
    -- collide with a stale cache entry.
    local key = table.concat({
      original_src,
      tostring(stat.mtime.sec),
      tostring(stat.mtime.nsec),
      tostring(stat.size),
    }, ':')
    hash = vim.fn.sha256(key):sub(1, 12)
  end

  local out = cache .. '/' .. hash .. '-hover.' .. ext

  if vim.fn.filereadable(out) == 1 then
    return out
  end

  if content then
    local fd = io.open(out, 'wb')
    if not fd then
      return nil
    end
    fd:write(content)
    fd:close()
  else
    --- @cast original_src string
    if not vim.uv.fs_copyfile(original_src, out) then
      return nil
    end
  end

  return out
end

--- @param source_buf integer
--- @param src string
local function open(source_buf, src)
  -- A second hover can arrive via the async at_cursor callback before the toggle guard sees the
  -- first; close it, or replacing `M.state.hover` would orphan its window, placement and <Esc> map
  if M.state.hover then
    close()
  end

  local lg = UI.layout.popup('lg')

  local scratch = vim.api.nvim_create_buf(false, true)
  vim.bo[scratch].bufhidden = 'wipe'

  local augroup =
    vim.api.nvim_create_augroup('features.preview.snacks.hover-image', { clear = true })

  local placement = Snacks.image.placement.new(scratch, src, {
    inline = false,
    -- Shift the image 1 cell right; with `w = loc.width + 2` below, that pads 1 cell on each side
    pos = { 1, 1 },
    -- Reserve the 2 padding cells so the image scales down to fit the padded window
    max_width = lg.width - 2,
    -- Reserve 2 rows so the image scales down rather than overflowing the bottom row
    max_height = lg.height - 2,
    -- Open the window only once snacks reports the image's cell dims; opening it upfront would
    -- flash the full `lg` frame before snapping to the image size
    on_update_pre = function(self)
      local current = M.state.hover
      if not current then
        return
      end
      if vim.api.nvim_win_is_valid(current.win) then
        return
      end

      -- Wipe leftover extmarks such as snacks' "<step> loading …" virt_text, which it never clears
      -- once ready; the render() below re-sets the image's own
      vim.api.nvim_buf_clear_namespace(scratch, -1, 0, -1)

      local loc = self:state().loc
      local w = loc.width + 2
      local h = loc.height + 2
      local col, row = UI.layout.center(w, h)

      local win = vim.api.nvim_open_win(scratch, false, {
        relative = 'editor',
        width = w,
        height = h,
        col = col,
        row = row,
        border = 'rounded',
        style = 'minimal',
        focusable = false,
        noautocmd = true,
      })

      if Snacks.image.terminal.env().placeholders then
        vim.wo[win].winblend = 0
      end

      current.win = win
    end,
  })

  M.state.hover = {
    win = -1, -- placeholder until on_update_pre opens the window
    buf = scratch,
    placement = placement,
    augroup = augroup,
    release_keymaps = common.override_buf_keymaps(source_buf, {
      { 'n', '<Esc>', close, { desc = 'Close Hover Image' } },
    }),
  }

  vim.api.nvim_create_autocmd(
    { 'CursorMoved', 'CursorMovedI', 'BufLeave', 'ModeChanged', 'BufWipeout' },
    {
      group = augroup,
      buffer = source_buf,
      callback = close,
    }
  )
end

function M.hover_image()
  if M.state.hover then
    close()
    return
  end

  local source_buf = vim.api.nvim_get_current_buf()

  if vim.bo.filetype == 'mermaid' then
    local lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
    local content = table.concat(lines, '\n')
    if content == '' then
      return
    end
    local src = build_hover_src(nil, 'mmd', content)
    if not src then
      return
    end
    open(source_buf, src)
    return
  end

  Snacks.image.doc.at_cursor(function(src)
    if not src then
      return
    end

    -- Remote images: snacks downloads URLs itself, while the local-copy step
    -- below would fail filereadable() and silently drop the hover
    if src:find('^%w%w+://') then
      open(source_buf, src)
      return
    end

    local ext = vim.fn.fnamemodify(src, ':e')
    if ext == '' then
      ext = 'png'
    end
    local hover_src = build_hover_src(src, ext, nil)
    if not hover_src then
      return
    end
    open(source_buf, hover_src)
  end)
end

-- Audio has no frame for snacks.image to render, and its bytes are no use as text
local audio_extensions =
  { 'aac', 'aif', 'aiff', 'flac', 'm4a', 'mp3', 'oga', 'ogg', 'opus', 'wav', 'weba', 'wma' }

--- @param path string
--- @return boolean
local function is_audio(path)
  return vim.list_contains(audio_extensions, vim.fn.fnamemodify(path, ':e'):lower())
end

--- Whether `path` opens as a rendered view (snacks.image's viewer or the audio page)
--- rather than as its own bytes
--- @param path string
--- @return boolean
function M.is_media(path)
  return is_audio(path) or Snacks.image.supports_file(path)
end

--- The page never redraws on mode changes or cursor moves: render every mode and the cursor line
--- alike, without the debounce that drops ffprobe's late draw (read on a buffer's first draw)
--- @type render.md.partial.UserConfig
local page_render_config = {
  render_modes = true,
  anti_conceal = { enabled = false },
  win_options = { concealcursor = { rendered = 'nvic' } },
  debounce = 0,
}

--- Draw the page with render-markdown, which only attaches by filetype (the page has none)
--- @param buf integer
local function draw_page(buf)
  render_markdown.render({ buf = buf, config = page_render_config })
end

--- @param buf integer
--- @param start integer First line to replace (0-indexed), or -1 to append
--- @param lines string[]
local function write_page(buf, start, lines)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, start, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
  draw_page(buf)
end

--- @param seconds number
--- @return string duration `m:ss.cc`, led by an hours field from one hour up
local function format_duration(seconds)
  local centis = math.floor(seconds * 100 + 0.5)
  local hours = math.floor(centis / 360000)
  local minutes = math.floor(centis / 6000) % 60
  local secs = centis % 6000 / 100

  if hours > 0 then
    return string.format('%d:%02d:%05.2f', hours, minutes, secs)
  end
  return string.format('%d:%05.2f', minutes, secs)
end

--- Page lines for ffprobe's report on the file's first audio stream
--- @param path string
--- @param result vim.SystemCompleted
--- @return string[]
local function audio_details(path, result)
  if result.code ~= 0 then
    local stderr = vim.split(vim.trim(result.stderr), '\n')
    local reason = stderr[#stderr]
    -- ffprobe leads with the path, which the page already shows
    if vim.startswith(reason, path .. ': ') then
      reason = reason:sub(#path + 3)
    end
    return { string.format('- **ffprobe**: %s', reason) }
  end

  local probe = vim.json.decode(result.stdout)
  local format = probe.format
  local stream = probe.streams[1] or {}
  local lines = {}

  local duration = tonumber(format.duration)
  if duration then
    lines[#lines + 1] = string.format('- **duration**: %s', format_duration(duration))
  end

  if stream.codec_long_name then
    lines[#lines + 1] = string.format('- **codec**: %s', stream.codec_long_name)
  end

  -- Lossless streams (FLAC) carry no bitrate of their own, unlike their container
  local bit_rate = tonumber(stream.bit_rate) or tonumber(format.bit_rate)
  if bit_rate then
    lines[#lines + 1] = string.format('- **bitrate**: %d kb/s', math.floor(bit_rate / 1000 + 0.5))
  end

  local sample_rate = tonumber(stream.sample_rate)
  if sample_rate then
    -- A WAV without a channel mask has a channel count but no layout
    local count = stream.channels
    local channels = stream.channel_layout
      or (count and string.format('%d channel%s', count, count == 1 and '' or 's'))
    lines[#lines + 1] = string.format(
      '- **sample rate**: %g kHz%s',
      sample_rate / 1000,
      channels and string.format(' (%s)', channels) or ''
    )
  end

  return lines
end

--- Fill the buffer with the audio page, appending ffprobe's details once it reports
--- @param buf integer
--- @param path string
local function render_audio_page(buf, path)
  -- Highlight without a filetype, whose FileType event would attach LSP clients
  vim.treesitter.start(buf, 'markdown')
  write_page(buf, 0, { '# Audio file', '', string.format('- **file**: `%s`', path) })

  if vim.fn.executable('ffprobe') == 0 then
    return
  end

  -- A probe from an earlier render (an `:edit!` while it ran) must not append to the new page;
  -- changedtick can't tell, since nvim bumps it after the rendering BufReadCmd returns
  local render = {}
  M.state.page_renders[buf] = render
  vim.system({
    'ffprobe',
    '-v',
    'error',
    '-select_streams',
    'a:0',
    '-show_entries',
    'format=duration,bit_rate:stream=codec_long_name,sample_rate,channels,channel_layout,bit_rate',
    '-of',
    'json',
    path,
  }, { text = true }, function(result)
    vim.schedule(function()
      if M.state.page_renders[buf] ~= render then
        return
      end

      M.state.page_renders[buf] = nil
      if vim.api.nvim_buf_is_loaded(buf) then
        write_page(buf, -1, audio_details(path, result))
      end
    end)
  end)
end

--- The picker's file previewer, showing audio as its info page instead of "binary file", the
--- way snacks' own previewer hands images and videos to snacks.image
--- @param ctx snacks.picker.preview.ctx
function M.preview_file(ctx)
  local path = Snacks.picker.util.path(ctx.item)
  if not (path and is_audio(path)) then
    return Snacks.picker.preview.file(ctx)
  end

  -- A fresh scratch buffer per item, wiped once the next item replaces it, so a probe that
  -- reports late finds its buffer unloaded
  local buf = ctx.preview:scratch()
  -- Without a filetype, as on the audio buffer: render-markdown looks its parser up by
  -- filetype, and scratch()'s `snacks_picker_preview` names a language with no parser
  common.noautocmd(function()
    vim.bo[buf].filetype = ''
  end)

  ctx.preview:set_title(ctx.item.preview_title or ctx.item.title or vim.fn.fnamemodify(path, ':t'))
  render_audio_page(buf, path)
end

--- Open audio files as a read-only info page, the way snacks.image opens images and videos
function M.setup_audio_viewer()
  local group =
    vim.api.nvim_create_augroup('features.preview.snacks.audio-viewer', { clear = true })
  local pattern = string.format('*.{%s}', table.concat(audio_extensions, ','))

  vim.api.nvim_create_autocmd('BufReadCmd', {
    group = group,
    pattern = pattern,
    callback = function(args)
      render_audio_page(args.buf, vim.api.nvim_buf_get_name(args.buf))
    end,
  })

  -- A draw only reaches the windows showing the page, so redraw it each time it's shown
  vim.api.nvim_create_autocmd('BufWinEnter', {
    group = group,
    pattern = pattern,
    callback = function(args)
      draw_page(args.buf)
    end,
  })

  -- The buffer holds the info page, which a write would put in place of the audio
  vim.api.nvim_create_autocmd('BufWriteCmd', {
    group = group,
    pattern = pattern,
    callback = function(args)
      vim.bo[args.buf].modified = false
    end,
  })
end

return M
