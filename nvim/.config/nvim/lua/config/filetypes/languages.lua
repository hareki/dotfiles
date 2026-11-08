--- Language aliases this config adds to nvim-treesitter's own: its plugin/filetypes.lua registers
--- handlebars and htmlangular, but not mdx
--- Entry point: lazygit's diff renderer dofiles this under `nvim --clean`
--- (codediff/lib/bootstrap.lua), so it uses none of this config's globals or modules
--- @class config.filetypes.languages
local M = {}

--- Filetype => the tree-sitter language its text parses with
--- @type table<string, string>
local ALIASES = {
  mdx = 'markdown',
}

--- @return nil
function M.register()
  for filetype, language in pairs(ALIASES) do
    vim.treesitter.language.register(language, filetype)
  end
end

return M
