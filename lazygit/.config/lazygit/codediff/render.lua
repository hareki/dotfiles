-- One-shot renderer: git diff on stdin, ANSI on stdout.
-- Usage: nvim --clean -l render.lua   (also the daemon's fallback path)

local script = arg and arg[0] or debug.getinfo(1, "S").source:sub(2)
local dir = vim.fn.fnamemodify(script, ":p:h")
package.path = dir .. "/?.lua;" .. package.path

local input = io.read("*a") or ""

-- Buffered, not streamed: core.render emits one chunk per file section, so an
-- error on the third file of five would leave two already on stdout and the
-- degrade-to-cat below would then print those hunks a second time.
local chunks = {}

local ok = pcall(function()
  require("lib.bootstrap").setup()
  require("lib.core").render(input, {
    cwd = vim.fn.getcwd(),
    cols = tonumber(vim.env.LAZYGIT_COLUMNS) or 120,
    emit = function(chunk)
      chunks[#chunks + 1] = chunk
    end,
    layout = vim.env.CODEDIFF_LAYOUT,
    force_fragment = vim.env.CODEDIFF_FORCE_FRAGMENT == "1",
  })
end)

-- Renderer failure must never hide the diff: degrade to plain cat.
io.write(ok and table.concat(chunks) or input)
io.flush()
os.exit(0)
