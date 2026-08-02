-- One-shot renderer: git diff on stdin, ANSI on stdout.
-- Usage: nvim --clean -l render.lua   (also the daemon's fallback path)

local script = arg and arg[0] or debug.getinfo(1, "S").source:sub(2)
local dir = vim.fn.fnamemodify(script, ":p:h")
package.path = dir .. "/?.lua;" .. package.path

local input = io.read("*a") or ""

local ok = pcall(function()
  require("lib.bootstrap").setup()
  local ansi = require("lib.ansi")
  require("lib.core").render(input, {
    cwd = vim.fn.getcwd(),
    cols = tonumber(vim.env.LAZYGIT_COLUMNS) or 120,
    emit = ansi.stdout_emitter(),
    layout = vim.env.CODEDIFF_LAYOUT,
    force_fragment = vim.env.CODEDIFF_FORCE_FRAGMENT == "1",
  })
end)

if not ok then
  -- Renderer failure must never hide the diff: degrade to plain cat.
  io.write(input)
end
io.flush()
os.exit(0)
