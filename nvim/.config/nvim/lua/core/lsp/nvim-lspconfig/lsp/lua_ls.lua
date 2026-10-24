return {
  opts = {
    -- nvim-lspconfig ranks .luarc.json above .stylua.toml, so the dotfiles-root one (for Claude
    -- Code's LuaLS) would become the root and override lazydev; one group lets the nearest win
    root_markers = {
      {
        '.emmyrc.json',
        '.luarc.json',
        '.luarc.jsonc',
        '.luacheckrc',
        '.stylua.toml',
        'stylua.toml',
        'selene.toml',
        'selene.yml',
      },
      { '.git' },
    },
    settings = {
      Lua = {
        diagnostics = {
          unusedLocalExclude = { '_*' },
        },
      },
    },
  },
}
