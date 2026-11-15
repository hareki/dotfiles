-- One-shot renderer: the request a daemon would have been sent, handled by an
-- nvim started for it alone (lib/request.lua has the request's fields).
-- Usage: nvim --clean -l render.lua <request>
--
-- Exits non-zero unless the render reached the request's output file, which is
-- client.sh's cue to show the raw diff instead.

local dir = vim.fn.fnamemodify(arg[0], ':p:h')
package.path = dir .. '/?.lua;' .. package.path

require('lib.bootstrap').setup()
if not require('lib.request').handle(arg[1]) then
  os.exit(1)
end
