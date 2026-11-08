--- @class core.nvim-treesitter.utils
local M = {}

--- Parsers kept installed: `true` for one nvim-treesitter ships, else where to fetch a custom one
--- @type table<string, true | { url: string, branch?: string, queries?: string }>
M.parsers = {
  bash = true,
  c = true,
  diff = true,
  html = true,
  javascript = true,
  jsdoc = true,
  json = true,
  lua = true,
  luadoc = true,
  luap = true,
  markdown = true,
  markdown_inline = true,
  printf = true,
  python = true,
  query = true,
  regex = true,
  toml = true,
  tsx = true,
  typescript = true,
  vim = true,
  vimdoc = true,
  xml = true,
  yaml = true,
  css = true,
  scss = {
    url = 'https://github.com/hareki/tree-sitter-scss',
    branch = 'master',
  },
  styled = true,
  zsh = true,
  gitcommit = true,
  astro = true,
  mermaid = true,
  angular = true,
  rust = true,
  go = true,
  ghostty = {
    url = 'https://github.com/bezhermoso/tree-sitter-ghostty',
    queries = 'queries/ghostty',
  },
  glimmer = {
    url = 'https://github.com/hareki/tree-sitter-glimmer',
    queries = 'queries/glimmer',
  },
  applescript = {
    url = 'https://github.com/waddie/tree-sitter-applescript',
    queries = 'queries',
  },
}

--- @return string[]
function M.parser_names()
  return vim.tbl_keys(M.parsers)
end

--- Point nvim-treesitter at the custom parsers' repos on TSUpdate, as the plugin rebuilds its list
--- @return nil
function M.register_custom_parsers()
  local ts_parsers = require('nvim-treesitter.parsers')

  for lang, install_info in pairs(M.parsers) do
    if type(install_info) == 'table' then
      ts_parsers[lang] = ts_parsers[lang] or {}
      ts_parsers[lang].install_info = install_info
    end
  end
end

local detach_patched = false

--- A highlighter's destroy() sources syntax/<ft>.vim (~12 ms for markdown) even from on_detach,
--- where the buffer is going away (a reload takes on_reload), so wiped popups paid for nothing
--- @return nil
function M.skip_syntax_on_detach()
  if detach_patched then
    return
  end
  detach_patched = true

  local noautocmd = require('utils.noautocmd')
  local highlighter = require('vim.treesitter.highlighter') --[[@as table]]
  local on_detach = highlighter.on_detach

  function highlighter:on_detach()
    noautocmd.run(function()
      on_detach(self)
    end)
  end
end

return M
