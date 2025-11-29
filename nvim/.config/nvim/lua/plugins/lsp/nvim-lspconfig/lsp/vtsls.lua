local ts_config = {
  updateImportsOnFileMove = { enabled = 'always' },
  suggest = {
    completeFunctionCalls = false,
  },
  inlayHints = {
    enumMemberValues = { enabled = false },
    functionLikeReturnTypes = { enabled = false },
    parameterNames = { enabled = false },
    parameterTypes = { enabled = false },
    propertyDeclarationTypes = { enabled = false },
    variableTypes = { enabled = false },
  },
}

local js_config = ts_config

return {
  setup = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('vtsls_lsp_attach', { clear = true }),
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)

        if not (client and client.name == 'vtsls') then
          return
        end

        ---@param lhs string
        ---@param action string
        ---@param desc string
        local function map(lhs, action, desc)
          vim.keymap.set('n', lhs, function()
            vim.lsp.buf.code_action({
              apply = true,
              context = {
                only = { action },
                diagnostics = {},
              },
            })
          end, {
            buffer = args.buf,
            desc = 'TypeScript: ' .. desc,
          })
        end

        map('<leader>cu', 'source.removeUnused.ts', 'Remove Unused Imports')
        map('<leader>ci', 'source.addMissingImports.ts', 'Add Missing Imports')

        Snacks.util.lsp.on({ name = 'vtsls' }, function(buffer, client)
          client.commands['_typescript.moveToFileRefactoring'] = function(command, ctx)
            ---@type string, string, lsp.Range
            local action, uri, range = unpack(command.arguments)

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
              ---@type string[]
              local files = result.body.files
              table.insert(files, 1, 'Enter new path...')
              vim.ui.select(files, {
                prompt = 'Select move destination:',
                format_item = function(f)
                  return vim.fn.fnamemodify(f, ':~:.')
                end,
              }, function(f)
                if f and f:find('^Enter new path') then
                  vim.ui.input({
                    prompt = 'Enter move destination:',
                    default = vim.fn.fnamemodify(fname, ':h') .. '/',
                    completion = 'file',
                  }, function(newf)
                    return newf and move(newf)
                  end)
                elseif f then
                  move(f)
                end
              end)
            end)
          end
        end)
      end,
    })
  end,

  opts = function()
    local npm_global_root = vim.fn.trim(vim.fn.system('npm root -g'))

    return {
      settings = {
        complete_function_calls = false,
        typescript = ts_config,
        javascript = js_config,
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
    }
  end,
}
