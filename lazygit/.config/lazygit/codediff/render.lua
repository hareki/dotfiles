-- One-shot renderer: git diff on stdin, ANSI on stdout.
-- Usage: nvim --clean -l render.lua   (also the daemon's fallback path)
--
-- A renderer failure exits non-zero with stdout empty, which is client.sh's cue
-- to show the raw diff instead.

local dir = vim.fn.fnamemodify(arg[0], ':p:h')
package.path = dir .. '/?.lua;' .. package.path

local input = io.read('*a')

require('lib.bootstrap').setup()
local rendered = require('lib.core').render(input, {
  cwd = vim.fn.getcwd(),
  cols = tonumber(vim.env.COLUMNS),
  layout = vim.env.CODEDIFF_LAYOUT,
  metadata = vim.env.CODEDIFF_METADATA == '1',
})

io.write(rendered)
