-- features/preview/snacks-nvim: the audio page (ffprobe faked), in a buffer and a picker preview,
-- and the `gi` image hover up to the float snacks shows, as headless nvim draws no pixels

local t = require('tests.lib.helpers')

local FIXTURES = vim.fs.joinpath(vim.fn.stdpath('config'), 'assets/preview-test')

-- audio-page.lua

--- @class tests.media-preview.Probe
--- @field cmd string[]
--- @field reply fun(result: table) Run the probe's on_exit with these vim.SystemCompleted fields

--- Fake ffprobe until the test ends: present on the PATH, each run held until the test replies
--- @return tests.media-preview.Probe[] probes In the order they ran
local function fake_ffprobe()
  local executable = vim.fn.executable
  t.set(vim.fn, 'executable', function(name)
    return name == 'ffprobe' and 1 or executable(name)
  end)

  local probes = {}
  local system = vim.system
  t.set(vim, 'system', function(cmd, opts, on_exit)
    if cmd[1] ~= 'ffprobe' then
      return system(cmd, opts, on_exit)
    end
    probes[#probes + 1] = {
      cmd = cmd,
      reply = function(result)
        on_exit(vim.tbl_extend('keep', result, { code = 0, signal = 0, stdout = '', stderr = '' }))
      end,
    }
  end)
  return probes
end

--- @param probe table ffprobe's JSON report
--- @return vim.SystemCompleted
local function reported(probe)
  return { code = 0, signal = 0, stdout = vim.json.encode(probe), stderr = '' }
end

--- Edit an audio file under the boot's cwd, its bytes not audio at all
--- @param name string
--- @return integer buf
--- @return string path
local function edit_audio(name)
  local buf = t.file(name, { 'not really audio' })
  return buf, vim.api.nvim_buf_get_name(buf)
end

--- @param buf integer
--- @return string[]
local function lines(buf)
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

--- @param path string
--- @return string[]
local function page_head(path)
  return { '# Audio file', '', string.format('- **file**: `%s`', path) }
end

--- @param buf integer
--- @param count integer
local function await_lines(buf, count)
  t.wait_for(function()
    return #lines(buf) == count
  end, string.format('the page to hold %d lines', count))
end

t.test("an audio file opens as a read-only page, then ffprobe's details join it", function()
  local probes = fake_ffprobe()
  local buf, path = edit_audio('song.mp3')

  t.eq(lines(buf), page_head(path), 'the page before ffprobe reports')
  t.eq({ vim.bo[buf].modifiable, vim.bo[buf].modified }, { false, false }, 'modifiable, modified')
  t.eq(vim.bo[buf].filetype, '', 'the filetype, whose FileType would attach language servers')
  t.ok(vim.treesitter.highlighter.active[buf], 'no markdown highlighting')
  t.eq(#probes, 1, 'the ffprobe runs')
  t.eq(probes[1].cmd[#probes[1].cmd], path, 'the file ffprobe reads')

  probes[1].reply(reported({
    format = { duration = '3725.456', bit_rate = '1000' },
    streams = {
      {
        codec_long_name = 'MP3 (MPEG audio layer 3)',
        bit_rate = '320000',
        sample_rate = '44100',
        channels = 2,
        channel_layout = 'stereo',
      },
    },
  }))
  await_lines(buf, 7)
  t.eq(vim.list_slice(lines(buf), 4), {
    '- **duration**: 1:02:05.46',
    '- **codec**: MP3 (MPEG audio layer 3)',
    '- **bitrate**: 320 kb/s',
    '- **sample rate**: 44.1 kHz (stereo)',
  }, 'the details')
  t.eq({ vim.bo[buf].modifiable, vim.bo[buf].modified }, { false, false }, 'after the details')
end)

t.test("the details take the container's bitrate, and a channel count without a layout", function()
  local probes = fake_ffprobe()
  local mono = edit_audio('mono.flac')
  probes[1].reply(reported({
    format = { duration = '65.5', bit_rate = '900400' },
    streams = { { codec_long_name = 'FLAC', sample_rate = '48000', channels = 1 } },
  }))
  await_lines(mono, 7)
  t.eq(vim.list_slice(lines(mono), 4), {
    '- **duration**: 1:05.50',
    '- **codec**: FLAC',
    '- **bitrate**: 900 kb/s',
    '- **sample rate**: 48 kHz (1 channel)',
  }, 'a mono file')

  local wav = edit_audio('stereo.wav')
  probes[2].reply(reported({ format = {}, streams = { { sample_rate = '8000', channels = 2 } } }))
  await_lines(wav, 4)
  t.eq(lines(wav)[4], '- **sample rate**: 8 kHz (2 channels)', 'a file with two channels')
end)

t.test('an ffprobe failure shows its last line, without the path it leads with', function()
  local probes = fake_ffprobe()
  local buf, path = edit_audio('broken.ogg')

  probes[1].reply({
    code = 1,
    stderr = string.format('some warning\n%s: Invalid data found when processing input\n', path),
  })
  await_lines(buf, 4)
  t.eq(lines(buf)[4], '- **ffprobe**: Invalid data found when processing input')
end)

t.test('a probe still running when the page renders again adds nothing', function()
  local probes = fake_ffprobe()
  local buf, path = edit_audio('reloaded.m4a')

  vim.cmd('edit!')
  t.eq(#probes, 2, 'the ffprobe runs')
  probes[1].reply(reported({ format = { duration = '1' }, streams = {} }))
  t.settle()
  t.eq(lines(buf), page_head(path), 'the page after the stale probe reported')

  probes[2].reply(reported({ format = { duration = '2' }, streams = {} }))
  await_lines(buf, 4)
  t.eq(lines(buf)[4], '- **duration**: 0:02.00', 'the details of the current probe')
end)

t.test('without ffprobe the page shows the file alone', function()
  local executable = vim.fn.executable
  t.set(vim.fn, 'executable', function(name)
    return name ~= 'ffprobe' and executable(name) or 0
  end)
  local calls = t.spy(vim, 'system')
  local buf, path = edit_audio('alone.wav')

  t.eq(lines(buf), page_head(path), 'the page')
  t.eq(#calls, 0, 'the processes run')
end)

t.test('a write leaves the audio file alone', function()
  fake_ffprobe()
  local buf, path = edit_audio('kept.mp3')
  local bytes = vim.fn.readblob(path)

  vim.cmd.write()
  t.eq(vim.fn.readblob(path), bytes, 'the file on disk')
  t.eq(vim.bo[buf].modified, false, 'modified')
end)

t.test('a picker without a previewer of its own previews audio as its page', function()
  local probes = fake_ffprobe()
  local path = t.write('preview.mp3', { 'not really audio' })

  local picker = t.open_picker(
    function()
      Snacks.picker({ source = 'audio-preview-test', items = { { file = path, text = path } } })
    end,
    'audio-preview-test',
    function(picker)
      local buf = picker.preview.win.buf
      return buf ~= nil and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == '# Audio file'
    end,
    'the preview to show the audio page'
  )

  local buf = t.ok(picker.preview.win.buf, 'no preview buffer')
  t.eq(lines(buf), page_head(path), 'the preview')
  t.eq(vim.bo[buf].filetype, '', 'the filetype')
  probes[1].reply(reported({ format = { duration = '3' }, streams = {} }))
  await_lines(buf, 4)
end)

-- hover-image.lua

--- The floats open now
--- @return integer[]
local function floats()
  return vim.tbl_filter(function(win)
    return vim.api.nvim_win_get_config(win).relative == 'editor'
  end, vim.api.nvim_list_wins())
end

--- The hover copies in snacks.image's cache
--- @param ext string
--- @return string[]
local function hover_copies(ext)
  return vim.fn.glob(vim.fs.joinpath(Snacks.image.config.cache, '*-hover.' .. ext), false, true)
end

--- A markdown file whose third line holds an image, the cursor on it
--- @param name string
--- @param image string The image's path, relative to the boot's cwd
--- @return integer buf
local function markdown_with_image(name, image)
  local buf = t.file(name, { '# Doc', '', string.format('![picture](%s)', image) })
  vim.api.nvim_win_set_cursor(0, { 3, 3 })
  -- A gi comes after the buffer opened: till the loop has run, snacks finds no image in it
  t.settle()
  return buf
end

--- Copy a fixture image under the boot's cwd
--- @param fixture string
--- @param name string
local function place_image(fixture, name)
  vim.fn.writefile(vim.fn.readblob(vim.fs.joinpath(FIXTURES, fixture)), name, 'b')
end

--- Press `gi` and wait for the hover float; closed when the test ends
--- @return integer win
local function hover()
  local before = floats()
  t.cleanup(function()
    for _, win in ipairs(floats()) do
      if not vim.list_contains(before, win) then
        vim.api.nvim_win_close(win, true)
      end
    end
  end)

  t.map_callback('n', 'gi')()
  local win
  t.wait_for(function()
    win = vim.iter(floats()):find(function(w)
      return not vim.list_contains(before, w)
    end)
    return win ~= nil
  end, 'the hover float')
  return win
end

t.test('gi on an image opens a hover sized to it once snacks knows its cells', function()
  place_image('arch-black-4k.png', 'picture.png')
  markdown_with_image('hover.md', 'picture.png')

  local win = hover()
  local lg = UI.layout.float('lg')
  t.wait_for(function()
    return not vim.api.nvim_win_get_config(win).hide
  end, 'the hover to show', 5000)

  local config = vim.api.nvim_win_get_config(win)
  t.ok(config.width <= lg.width and config.height <= lg.height, 'larger than the lg frame')
  t.eq({ config.col, config.row }, { UI.layout.center(config.width, config.height) }, 'centered')
  t.eq(config.focusable, false, 'focusable')
  t.eq(t.ok(t.keymap('n', '<Esc>', 0), 'no <Esc> in the source').desc, 'Close Hover Image')
  t.eq(t.keymap('n', '<Tab>', 0), nil, 'a <Tab> lent to the source, for a float taking no focus')
end)

t.test('gi again, a cursor move or <Esc> in the source closes the hover', function()
  place_image('arch-black-4k.png', 'closing.png')
  local buf = markdown_with_image('closing.md', 'closing.png')

  local before = #floats()
  local win = hover()
  t.map_callback('n', 'gi')()
  t.eq(vim.api.nvim_win_is_valid(win), false, 'open after a second gi')
  t.settle(200)
  t.eq(#floats(), before, 'the floats after a second gi')

  win = hover()
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.api.nvim_exec_autocmds('CursorMoved', { buf = buf })
  t.eq(vim.api.nvim_win_is_valid(win), false, 'open after a cursor move')

  vim.api.nvim_win_set_cursor(0, { 3, 3 })
  win = hover()
  t.map_callback('n', '<Esc>', buf)()
  t.eq(vim.api.nvim_win_is_valid(win), false, 'open after <Esc>')
  t.eq(t.keymap('n', '<Esc>', buf), nil, 'the <Esc> lent to the source')
end)

t.test('the hover shows an edited image from a copy of its own', function()
  place_image('arch-black-4k.png', 'edited.png')
  markdown_with_image('edited.md', 'edited.png')

  local copies = #hover_copies('png')
  hover()
  t.eq(#hover_copies('png'), copies + 1, 'the copies after the first hover')
  t.map_callback('n', 'gi')()

  hover()
  t.eq(#hover_copies('png'), copies + 1, 'the copies after a second hover of the same image')
  t.map_callback('n', 'gi')()

  place_image('windows-black.png', 'edited.png')
  hover()
  t.eq(#hover_copies('png'), copies + 2, 'the copies after the image changed')
end)

t.test('gi off an image opens nothing', function()
  t.file('no-image.md', { '# Doc', '', 'plain text' })
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  t.settle()
  local before = #floats()

  t.map_callback('n', 'gi')()
  t.settle(200)
  t.eq(#floats(), before)
end)

t.test('gi in a mermaid buffer hovers a copy of its text, unless it is empty', function()
  -- Converting the diagram would start mermaid-cli and a browser; snacks asks once per command
  local executable = vim.fn.executable
  t.set(vim.fn, 'executable', function(name)
    return name == 'mmdc' and 0 or executable(name)
  end)

  local before = #floats()
  t.buffer('mermaid')
  t.map_callback('n', 'gi')()
  t.settle()
  t.eq(#floats(), before, 'the floats after gi in an empty buffer')

  local text = { 'graph TD', '  A --> B' }
  t.buffer('mermaid', text)
  local copies = hover_copies('mmd')
  hover()
  local added = vim.tbl_filter(function(copy)
    return not vim.list_contains(copies, copy)
  end, hover_copies('mmd'))
  t.eq(#added, 1, 'the new copies')
  t.eq(vim.fn.readfile(added[1]), text, 'the copy')
end)
