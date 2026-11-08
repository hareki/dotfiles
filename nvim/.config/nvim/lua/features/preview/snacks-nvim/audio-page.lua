--- @module 'utils.noautocmd'
local noautocmd = Defer.on_exported_call('utils.noautocmd')

--- @module 'render-markdown'
local render_markdown = Defer.on_exported_call('render-markdown')

--- Audio files open as a read-only info page, in buffers and picker previews alike
--- @class features.preview.snacks-nvim.audio-page
local M = {}

--- Each audio page's latest render, by buffer
--- @type table<integer, table>
local page_renders = {}

-- Audio has no frame for snacks.image to render, and its bytes are no use as text
local audio_extensions =
  { 'aac', 'aif', 'aiff', 'flac', 'm4a', 'mp3', 'oga', 'ogg', 'opus', 'wav', 'weba', 'wma' }

--- @param path string
--- @return boolean
local function is_audio(path)
  return vim.list_contains(audio_extensions, vim.fs.ext(path):lower())
end

--- Whether `path` opens as a rendered view (snacks.image's viewer or the audio page)
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
  page_renders[buf] = render
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
      if page_renders[buf] ~= render then
        return
      end

      page_renders[buf] = nil
      if vim.api.nvim_buf_is_loaded(buf) then
        write_page(buf, -1, audio_details(path, result))
      end
    end)
  end)
end

--- The picker's file previewer, showing audio as its info page instead of "binary file"
--- @param ctx snacks.picker.preview.ctx
function M.preview_file(ctx)
  local path = Snacks.picker.util.path(ctx.item)
  if not (path and is_audio(path)) then
    return Snacks.picker.preview.file(ctx)
  end

  -- A fresh scratch buffer per item, wiped by the next one, so a late probe finds it unloaded
  local buf = ctx.preview:scratch()
  -- No filetype: render-markdown looks its parser up by it, and `snacks_picker_preview` has none
  noautocmd.run(function()
    vim.bo[buf].filetype = ''
  end)

  ctx.preview:set_title(ctx.item.preview_title or ctx.item.title or vim.fs.basename(path))
  render_audio_page(buf, path)
end

--- Open audio files as a read-only info page, the way snacks.image opens images and videos
function M.setup_audio_viewer()
  local group =
    vim.api.nvim_create_augroup('features.preview.snacks-nvim.audio-viewer', { clear = true })
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
