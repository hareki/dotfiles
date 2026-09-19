local ts_config = {
  updateImportsOnFileMove = { enabled = 'always' },
  suggest = {
    completeFunctionCalls = false,
  },
  inlayHints = {
    enumMemberValues = { enabled = false },
    functionLikeReturnTypes = { enabled = false },
    -- Unlike its boolean siblings, this key is an enum: 'none' | 'literals' | 'all'
    parameterNames = { enabled = 'none' },
    parameterTypes = { enabled = false },
    propertyDeclarationTypes = { enabled = false },
    variableTypes = { enabled = false },
  },
}

return {
  opts = function()
    -- PERF: Hardcode the mise tool root instead of resolving it with `mise where`,
    -- since the version rarely changes anyway; packages are under lib/node_modules
    local plugin_root =
      vim.fn.expand('~/.local/share/mise/installs/npm-styled-typescript-styled-plugin/1')
    local npm_global_root = plugin_root .. '/lib/node_modules'

    return {
      -- Parent-pid watchdog: vscode-languageserver polls this pid and exits vtsls
      -- normally (running its cleanup hooks, which reap the forked tsserver) if
      -- nvim dies without completing the LSP shutdown handshake
      cmd = { 'vtsls', '--stdio', '--clientProcessId', tostring(vim.uv.os_getpid()) },
      settings = {
        typescript = ts_config,
        javascript = ts_config,
        vtsls = {
          enableMoveToFileCodeAction = true,
          autoUseWorkspaceTsdk = true,
          tsserver = {
            globalPlugins = {
              {
                name = '@styled/typescript-styled-plugin',
                location = npm_global_root,
                enableForWorkspaceTypeScriptVersions = true,
              },
            },
          },
          experimental = {
            completion = {
              enableServerSideFuzzyMatch = true,
            },
          },
        },
      },

      -- Client-side command, which `Client:exec_cmd` checks before asking the server
      commands = {
        ['_typescript.moveToFileRefactoring'] = function(command, ctx)
          local client = vim.lsp.get_client_by_id(ctx.client_id) --[[@as vim.lsp.Client]]
          --- @type string, string, lsp.Range
          local action, uri, range = unpack(command.arguments --[[@as any[] ]])

          local function move(newf)
            client:request('workspace/executeCommand', {
              command = command.command,
              arguments = { action, uri, range, newf },
            })
          end

          local fname = vim.uri_to_fname(uri)
          client:request('workspace/executeCommand', {
            command = 'typescript.tsserverRequest',
            arguments = {
              'getMoveToRefactoringFileSuggestions',
              {
                file = fname,
                startLine = range.start.line + 1,
                startOffset = range.start.character + 1,
                endLine = range['end'].line + 1,
                endOffset = range['end'].character + 1,
              },
            },
          }, function(_, result)
            if not (result and result.body and result.body.files) then
              return
            end
            --- @type string[]
            local files = result.body.files
            table.insert(files, 1, 'Enter new path...')

            local function parent_dir(path)
              local dir = vim.fs.dirname(path)
              return dir and (dir:sub(-1) == '/' and dir or (dir .. '/')) or ''
            end
            vim.ui.select(files, {
              prompt = 'Select Move Destination:',
              format_item = function(f)
                return vim.fn.fnamemodify(f, ':~:.')
              end,
            }, function(f)
              if f and f:find('^Enter new path') then
                vim.ui.input({
                  prompt = 'Enter Move Destination:',
                  default = parent_dir(fname),
                  completion = 'file',
                }, function(newf)
                  if newf then
                    move(newf)
                  end
                end)
              elseif f then
                move(f)
              end
            end)
          end)
        end,
      },
    }
  end,

  setup = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('core.lsp.vtsls.attach', { clear = true }),
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)

        if not (client and client.name == 'vtsls') then
          return
        end

        --- @param action string
        --- @return fun()
        local function code_action(action)
          return function()
            vim.lsp.buf.code_action({
              apply = true,
              context = {
                only = { action },
                diagnostics = {},
              },
            })
          end
        end

        --- @param mode string | string[]
        --- @param lhs string
        --- @param rhs string | function
        --- @param desc string
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, {
            buffer = args.buf,
            desc = 'TypeScript LSP: ' .. desc,
          })
        end

        map('n', '<leader>cu', code_action('source.removeUnused.ts'), 'Remove Unused Imports')
        map('n', '<leader>ci', code_action('source.addMissingImports.ts'), 'Add Missing Imports')
      end,
    })
  end,
}
