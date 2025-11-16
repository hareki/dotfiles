return {
  'neovim/nvim-lspconfig',
  -- Don't use 'LazyFile' event, it will mess up the file type detection when opening a directory with nvim
  -- We can either:
  -- 1. Use 'VeryLazy' event
  -- 2. Use 'BufReadPre' event
  -- 3 Putting vim.lsp.enable() in the init function
  -- https://www.reddit.com/r/neovim/comments/1l7pz1l/starting_from_0112_i_have_a_weird_issue
  event = 'VeryLazy',
  dependencies = { 'folke/lazydev.nvim' },
  config = function()
    vim.diagnostic.config({
      -- https://neovim.io/doc/user/diagnostic.html#vim.diagnostic.Opts.VirtualLines
      -- virtual_lines = {
      --   current_line = true,
      -- },

      -- https://neovim.io/doc/user/diagnostic.html#vim.diagnostic.Opts.VirtualText
      -- virtual_text = {
      --   current_line = true,
      --   source = false,
      --   prefix = '●',
      -- },
      underline = true,
      update_in_insert = true,
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
      callback = function(args)
        local function opts(desc)
          return {
            buffer = args.buf,
            desc = desc,
          }
        end

        local map = vim.keymap.set

        map('n', 'gd', function()
          Snacks.picker.lsp_definitions()
        end, opts('Go to Definition'))

        map('n', 'gr', function()
          Snacks.picker.lsp_references()
        end, opts('Find References'))

        -- map('n', 'gh', vim.lsp.buf.hover, opts('Hover'))
        map({ 'n', 'x' }, '<leader>ca', function()
          require('actions-preview').code_actions()
        end, opts('Code Actions')) -- Ctrl + Z
        map('n', '<leader>cr', vim.lsp.buf.rename, opts('Rename')) -- F2
        map('n', ']]', function()
          Snacks.words.jump(vim.v.count1)
        end, opts('Next Reference'))
        map('n', '[[', function()
          Snacks.words.jump(-vim.v.count1)
        end, opts('Previous Reference'))
      end,
    })

    vim.lsp.enable({
      'marksman', -- Markdown
      'lua_ls', -- Lua
      'taplo', -- Toml
      'yamlls', -- Yaml
      'typos_lsp', -- Spelling checker
      'eslint', -- JS/TS linter
      'jsonls', -- JSON
      'html', -- HTML
      'cssls', -- CSS
      'css_variables', -- CSS
      'copilot', -- GitHub Copilot
      -- 'vtsls', -- Tytescript (Trying out typescript-tools.nvim)
    })

    vim.lsp.config('yamlls', {
      settings = {
        yaml = {
          schemas = {
            ['https://json.schemastore.org/github-workflow.json'] = '/.github/workflows/*',
          },
        },
      },
    })

    vim.lsp.config('typos_lsp', {
      init_options = {
        config = '~/.config/typos/typos.toml',
        diagnosticSeverity = 'Info',
      },
    })

    local base_on_eslint_attach = vim.lsp.config.eslint.on_attach
    local eslint_registered = false

    -- HINT: Restart eslint with `:LspRestart eslint`
    vim.lsp.config('eslint', {
      on_attach = function(client, bufnr)
        if base_on_eslint_attach then
          base_on_eslint_attach(client, bufnr)
        end

        if eslint_registered then
          return
        end

        require('utils.linters').register(
          'eslint',
          { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' },
          require('utils.linters.eslint').run
        )

        eslint_registered = true
      end,
    })

    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client or client.name ~= 'eslint' then
          return
        end

        -- Ask server to emit trace
        client:notify('$/setTrace', { value = 'verbose' })

        -- Use circular buffer to avoid O(n) table.remove operation
        local store, max = {}, 200
        local store_index = 0 -- Current write position
        local store_count = 0 -- Number of entries written
        local function push(line)
          store_index = (store_index % max) + 1
          store[store_index] = line
          store_count = store_count + 1
        end

        local original_trace = client.handlers['$/logTrace']
        local original_log = client.handlers['window/logMessage']
          or vim.lsp.handlers['window/logMessage']

        client.handlers['$/logTrace'] = function(err, params, ctx, cfg)
          push(
            ('%s %s%s'):format(os.date('%Y-%m-%d %H:%M:%S '), params.message, params.verbose or '')
          )
          if original_trace then
            return original_trace(err, params, ctx, cfg)
          end
        end

        client.handlers['window/logMessage'] = function(err, params, ctx, cfg)
          local lvl = ({ 'Error', 'Warn', 'Info', 'Log' })[params.type] or tostring(params.type)
          push(('%s [%s] %s'):format(os.date('%Y-%m-%d %H:%M:%S'), lvl, params.message))
          if original_log then
            original_log(err, params, ctx, cfg)
          end
        end

        vim.api.nvim_create_user_command('EslintLog', function()
          -- Reconstruct log in correct order from circular buffer
          local lines = {}
          local actual_count = math.min(store_count, max)

          if store_count <= max then
            -- Haven't wrapped around yet, store is in order
            for i = 1, actual_count do
              lines[i] = store[i]
            end
          else
            -- Wrapped around, need to reconstruct order
            local start_idx = (store_index % max) + 1
            for i = 1, max do
              local idx = ((start_idx + i - 2) % max) + 1
              lines[i] = store[idx]
            end
          end

          local buf = vim.api.nvim_create_buf(false, true)
          vim.bo[buf].filetype = 'eslint-log'
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
          vim.cmd('botright 15split')
          vim.api.nvim_win_set_buf(0, buf)
        end, {
          force = true, -- Override any previous definition
        })
      end,
    })
  end,
}
