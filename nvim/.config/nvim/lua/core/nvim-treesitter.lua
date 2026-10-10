local ensure_installed = {
  'bash',
  'c',
  'diff',
  'html',
  'javascript',
  'jsdoc',
  'json',
  'lua',
  'luadoc',
  'luap',
  'markdown',
  'markdown_inline',
  'printf',
  'python',
  'query',
  'regex',
  'toml',
  'tsx',
  'typescript',
  'vim',
  'vimdoc',
  'xml',
  'yaml',
  'css',
  'scss',
  'styled',
  'zsh',
  'gitcommit',
  'astro',
  'mermaid',
  'angular',
  'rust',
  'go',
  'ghostty',
  'glimmer',
}

return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  build = ':TSUpdate',
  cmd = { 'TSUpdate', 'TSInstall', 'TSLog', 'TSUninstall' },
  event = { 'BufReadPost', 'BufNewFile' },

  init = function()
    -- Languages with no parser, recorded only from plugin UI buffers (pickers, panels), whose
    -- filetypes never get one: each failed lookup re-scans the whole runtimepath
    --- @type table<string, true>
    local no_parser = {}

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('core.nvim-treesitter.start', { clear = true }),
      pattern = '*',
      callback = function(args)
        local lang = vim.treesitter.language.get_lang(args.match)
        -- File buffers always look the parser up, so one installed mid-session starts on :edit
        local is_ui = vim.bo[args.buf].buftype ~= ''
        if not lang or (is_ui and no_parser[lang]) then
          return
        end

        if not vim.treesitter.language.add(lang) then
          if is_ui then
            no_parser[lang] = true
          end
          return
        end

        pcall(vim.treesitter.start, args.buf, lang)
      end,
    })

    vim.api.nvim_create_autocmd('User', {
      group = vim.api.nvim_create_augroup('core.nvim-treesitter.custom-parsers', { clear = true }),
      pattern = 'TSUpdate',
      callback = function()
        local ts_parsers = require('nvim-treesitter.parsers')

        local install_infos = {
          glimmer = {
            url = 'https://github.com/hareki/tree-sitter-glimmer',
            queries = 'queries/glimmer',
          },

          scss = {
            url = 'https://github.com/hareki/tree-sitter-scss',
            branch = 'master',
          },

          ghostty = {
            url = 'https://github.com/bezhermoso/tree-sitter-ghostty',
            queries = 'queries/ghostty',
          },
        }

        for lang, install_info in pairs(install_infos) do
          ts_parsers[lang] = ts_parsers[lang] or {}
          ts_parsers[lang].install_info = install_info
        end
      end,
    })

    vim.api.nvim_create_user_command('TSInstallAll', function()
      local treesitter = require('nvim-treesitter')
      treesitter.install(ensure_installed)
    end, {})
  end,

  config = function()
    local treesitter = require('nvim-treesitter')

    local installed = {}
    for _, lang in ipairs(treesitter.get_installed('parsers')) do
      installed[lang] = true
    end

    local missing = vim.tbl_filter(function(lang)
      return not installed[lang]
    end, ensure_installed)

    if #missing > 0 then
      treesitter.install(missing, { summary = true })
    end

    -- https://morizbuesing.com/blog/mdx-support-in-nvchad/
    vim.treesitter.language.register('markdown', 'mdx')

    -- The handlebars grammar is provided by the glimmer parser
    vim.treesitter.language.register('glimmer', 'handlebars')

    -- The angular grammar drives Angular component templates (htmlangular)
    vim.treesitter.language.register('angular', 'htmlangular')
  end,
}
