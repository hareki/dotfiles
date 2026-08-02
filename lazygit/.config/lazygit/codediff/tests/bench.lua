-- Render benchmark for the codediff renderer.
--
--   nvim --clean -l tests/bench.lua [opts] [file.diff ...]
--
--   --iterations=N   timed renders per corpus file per layout (default 7)
--   --warmup=N       untimed renders first, to warm the caches (default 2)
--   --layout=L       inline | side-by-side | both (default both)
--   --fragment       skip git blob lookups (repo-independent, fragment mode)
--   --profile        also break the time down by phase
--   --json=PATH      write the raw per-file medians there, for a before/after diff
--
-- With no files the tests/fixtures corpus is used. Timings are wall clock around
-- core.render only: the daemon is warm by the time a user sees a diff, so the
-- nvim startup and bootstrap costs are deliberately outside the measurement.

local script = arg and arg[0] or debug.getinfo(1, "S").source:sub(2)
local dir = vim.fn.fnamemodify(script, ":p:h")
package.path = dir .. "/../?.lua;" .. package.path

local opts = { iterations = 7, warmup = 2, layout = "both", fragment = false, profile = false, json = nil }
local files = {}
for i = 1, #(arg or {}) do
  local a = arg[i]
  local key, value = a:match("^%-%-([%w_]+)=(.*)$")
  if key == "iterations" or key == "warmup" then
    opts[key] = tonumber(value)
  elseif key == "layout" or key == "json" then
    opts[key] = value
  elseif a == "--fragment" then
    opts.fragment = true
  elseif a == "--profile" then
    opts.profile = true
  else
    files[#files + 1] = a
  end
end
if #files == 0 then
  for name, kind in vim.fs.dir(dir .. "/fixtures") do
    if kind == "file" and name:sub(-5) == ".diff" then
      files[#files + 1] = dir .. "/fixtures/" .. name
    end
  end
  table.sort(files)
end

require("lib.bootstrap").setup()
local core = require("lib.core")

-- Phase accounting, wired by wrapping the module entry points rather than by
-- instrumenting them: the measured code stays exactly the shipped code.
local prof = {}
local function timed(name, fn)
  return function(...)
    local t0 = vim.uv.hrtime()
    local a, b = fn(...)
    prof[name] = (prof[name] or 0) + (vim.uv.hrtime() - t0)
    return a, b
  end
end
if opts.profile then
  local blob = require("lib.blob")
  local diffparse = require("lib.diffparse")
  local engine = require("lib.engine")
  local highlight = require("lib.highlight")
  local layout = require("lib.layout")
  diffparse.parse = timed("parse", diffparse.parse)
  blob.acquire = timed("blob", blob.acquire)
  highlight.line_spans = timed("treesitter", highlight.line_spans)
  engine.compute = timed("diff-engine", engine.compute)
  layout.content_line = timed("emit", layout.content_line)
  layout.split_line = timed("emit", layout.split_line)
  layout.hunk_header = timed("emit", layout.hunk_header)
end

local layouts = opts.layout == "both" and { "inline", "side-by-side" } or { opts.layout }
local cwd = vim.fn.getcwd()

local function render(input, layout)
  return core.render(input, { cwd = cwd, cols = 120, layout = layout, force_fragment = opts.fragment })
end

local function median(t)
  table.sort(t)
  local n = #t
  if n % 2 == 1 then
    return t[(n + 1) / 2]
  end
  return (t[n / 2] + t[n / 2 + 1]) / 2
end

local function ms(ns)
  return string.format("%8.2f", ns / 1e6)
end

io.write(string.format("corpus: %d file(s)  iterations: %d  warmup: %d  mode: %s\n\n", #files, opts.iterations, opts.warmup, opts.fragment and "fragment" or "full"))
io.write(string.format("%-24s %-13s %9s %9s %9s %9s\n", "file", "layout", "median", "min", "max", "KiB/s"))
io.write(string.rep("-", 79) .. "\n")

local results = {}
local grand_total = 0
for _, path in ipairs(files) do
  local f = assert(io.open(path, "rb"))
  local input = f:read("*a")
  f:close()
  local name = vim.fn.fnamemodify(path, ":t")

  for _, layout in ipairs(layouts) do
    for _ = 1, opts.warmup do
      render(input, layout)
    end
    prof = {}
    local samples = {}
    for _ = 1, opts.iterations do
      local t0 = vim.uv.hrtime()
      render(input, layout)
      samples[#samples + 1] = vim.uv.hrtime() - t0
    end
    local med = median(samples)
    grand_total = grand_total + med
    results[name .. " " .. layout] = med / 1e6
    io.write(string.format("%-24s %-13s %s %s %s %9.1f\n", name, layout, ms(med), ms(samples[1]), ms(samples[#samples]), (#input / 1024) / (med / 1e9)))
  end
end

io.write(string.rep("-", 79) .. "\n")
io.write(string.format("%-24s %-13s %s\n", "TOTAL (sum of medians)", "", ms(grand_total)))

if opts.profile then
  io.write("\nphase breakdown (last measured run only):\n")
  local names = vim.tbl_keys(prof)
  table.sort(names, function(x, y)
    return prof[x] > prof[y]
  end)
  for _, name in ipairs(names) do
    io.write(string.format("  %-14s %s ms\n", name, ms(prof[name] / opts.iterations)))
  end
end

if opts.json then
  local out = assert(io.open(opts.json, "w"))
  out:write(vim.json.encode({ total_ms = grand_total / 1e6, per_case = results }))
  out:close()
end

io.write("\n")
os.exit(0)
