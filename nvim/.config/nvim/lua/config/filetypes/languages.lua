--- Language aliases nvim-treesitter's plugin/filetypes.lua lacks (it has handlebars, not mdx)
--- Entry point: lazygit's diff renderer dofiles this under --clean, so no config globals or modules
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
