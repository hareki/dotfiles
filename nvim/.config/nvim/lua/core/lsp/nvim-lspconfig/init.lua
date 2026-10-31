return {
  'neovim/nvim-lspconfig',
  -- VeryLazy, not BufReadPost/BufNewFile, to avoid directory filetype detection issues:
  -- https://www.reddit.com/r/neovim/comments/1l7pz1l/starting_from_0112_i_have_a_weird_issue
  event = 'VeryLazy',
  config = function()
    local range_fix = require('core.lsp.nvim-lspconfig.utils.diagnostic-range-fix')
    local server_loader = require('core.lsp.nvim-lspconfig.utils.server-loader')

    range_fix.setup()

    vim.diagnostic.config({
      severity_sort = true,
      float = {
        border = 'rounded',
        source = true,
      },
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = '',
          [vim.diagnostic.severity.WARN] = '',
          [vim.diagnostic.severity.HINT] = '',
          [vim.diagnostic.severity.INFO] = '',
        },
        numhl = {
          [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
          [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
          [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
          [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
        },
      },
    })

    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup(
        'core.lsp.nvim-lspconfig.attach-keymaps',
        { clear = true }
      ),
      callback = function(args)
        local common = require('utils.common')
        local map = common.buf_mapper(args.buf, { prefix = 'LSP: ' })

        map('n', 'gd', function()
          Snacks.picker.lsp_definitions({
            include_current = true,
          })
        end, 'Go to Definition')

        map('n', 'gr', function()
          Snacks.picker.lsp_references({
            include_current = true,
          })
        end, 'Find References')

        map('n', 'gR', function()
          Snacks.picker.lsp_references({ filter = { buf = 0 } })
        end, 'Find References in Current Buffer')

        map({ 'n', 'x' }, 'gh', '<cmd>EagleWin<cr>', 'Open Info and Diagnostics')
        map({ 'n', 'x' }, 'gH', '<cmd>EagleWinLineDiagnostic<cr>', 'Open Line Diagnostics')

        map('n', '<leader>cr', vim.lsp.buf.rename, 'Rename')
        map({ 'n', 'x' }, '<leader>ca', function()
          local tiny_code_action = require('tiny-code-action')
          tiny_code_action.code_action({
            -- Drop actions the server marked disabled (vtsls's non-applicable refactors); resolving
            -- them for preview surfaces raw server errors
            filter = function(action)
              return action.disabled == nil
            end,
          })
        end, 'Code Actions')

        local client = vim.lsp.get_client_by_id(args.data.client_id) --[[@as vim.lsp.Client]]

        -- Neovim's own K is buffer-local, so config/keymaps.lua's retitle misses it; it also yields
        -- to a filetype's 'keywordprg', which none of these servers' filetypes set
        if client:supports_method('textDocument/hover') then
          map('n', 'K', vim.lsp.buf.hover, 'Hover')
        end

        -- Snacks.words only jumps between references a client highlights; buffers without one keep
        -- the ftplugin's ]] / [[ section jumps (typos_lsp highlights nothing but attaches to all)
        if client:supports_method('textDocument/documentHighlight') then
          map('n', ']]', function()
            Snacks.words.jump(vim.v.count1)
          end, 'Next Reference')
          map('n', '[[', function()
            Snacks.words.jump(-vim.v.count1)
          end, 'Previous Reference')
        end
      end,
    })

    local servers = {
      'marksman', -- Markdown
      'lua_ls',
      'taplo', -- TOML
      'yamlls',
      'typos_lsp', -- Spell checker
      'jsonls',
      'html',
      'cssls',
      'css_variables',
      'vtsls', -- TypeScript
      'tailwindcss',
      'astro',
      'ember', -- Ember/Glimmer
      'angularls',
    }

    -- eslint vs oxlint are mutually exclusive; selected by Project.linter
    -- (defaults to eslint when no .neovimrc.json is present).
    table.insert(servers, Project.linter)

    -- When oxfmt is the selected formatter, run it as an LSP server (see
    -- utils/style-enforcers/oxfmt.lua) instead of spawning the CLI.
    if Project.formatter == 'oxfmt' then
      table.insert(servers, 'oxfmt')
    end

    -- Deferred to yield to the UI, letting the buffer render before LSP servers start matching
    -- and attaching
    vim.defer_fn(function()
      server_loader.load_all()
      vim.lsp.enable(servers)
    end, 75)
  end,
}
