-- One-shot renderer: the request a daemon would have been sent (lib/request.lua), in its own nvim.
-- Usage: nvim --clean -l render.lua <request>
-- Exits non-zero unless the render reached the output file: client.sh's cue to show the raw diff.

local dir = vim.fn.fnamemodify(arg[0], ':p:h')
package.path = dir .. '/?.lua;' .. package.path

require('lib.bootstrap').setup()
if not require('lib.request').handle(arg[1]) then
  os.exit(1)
end
