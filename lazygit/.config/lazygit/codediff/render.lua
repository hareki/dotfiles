-- One-shot renderer: git diff on stdin, ANSI on stdout.
-- Usage: nvim --clean -l render.lua   (also the daemon's fallback path)
--
-- A renderer failure exits non-zero with stdout empty, which is client.sh's cue
-- to show the raw diff instead.

local script = debug.getinfo(1, 'S').source:sub(2)
local dir = vim.fn.fnamemodify(script, ':p:h')
package.path = dir .. '/?.lua;' .. package.path

local input = io.read('*a') or ''

require('lib.bootstrap').setup()
local rendered = require('lib.core').render(input, {
  cwd = vim.fn.getcwd(),
  cols = tonumber(vim.env.COLUMNS),
  layout = vim.env.CODEDIFF_LAYOUT,
  metadata = vim.env.CODEDIFF_METADATA == '1',
  force_fragment = vim.env.CODEDIFF_FORCE_FRAGMENT == '1',
})

io.write(rendered)
io.flush()
os.exit(0)
