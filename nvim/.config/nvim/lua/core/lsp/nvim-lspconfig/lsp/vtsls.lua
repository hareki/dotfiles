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
    -- Snacks.util.lsp.on already fires once per attaching client matching the filter,
    -- so it must be registered at top level — nesting it inside LspAttach leaks watchers.
    Snacks.util.lsp.on({ name = 'vtsls' }, function(_, client)
      client.commands['_typescript.moveToFileRefactoring'] = function(command, _)
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
          local cwd = vim.uv.cwd()
          local home = vim.env.HOME

          local function shorten_path(path)
            local normalized = vim.fs.normalize(path)
            local rel = cwd and vim.fs.relpath(cwd, normalized) or nil
            local display = rel or normalized

            if home and display:sub(1, #home) == home then
              display = '~' .. display:sub(#home + 1)
            end

            return display
          end

          local function parent_dir(path)
            local dir = vim.fs.dirname(path)
            return dir and (dir:sub(-1) == '/' and dir or (dir .. '/')) or ''
          end
          vim.ui.select(files, {
            prompt = 'Select Move Destination:',
            format_item = function(f)
              return shorten_path(f)
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
      end
    end)

    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('core.lsp.vtsls.attach', { clear = true }),
      callback = function(args)
        local lsp_client = vim.lsp.get_client_by_id(args.data.client_id)

        if not (lsp_client and lsp_client.name == 'vtsls') then
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

        --- @param mode string|string[]
        --- @param lhs string
        --- @param rhs string|function
        --- @param desc string
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, {
            buffer = args.buf,
            desc = 'TypeScript: ' .. desc,
          })
        end

        map('n', '<leader>cu', code_action('source.removeUnused.ts'), 'Remove Unused Imports')
        map('n', '<leader>ci', code_action('source.addMissingImports.ts'), 'Add Missing Imports')
      end,
    })
  end,

  opts = function()
    -- PERF: Hardcode it for faster resolve time, since the version rarely changes anyway
    local mise_where =
      vim.fn.expand('~/.local/share/mise/installs/npm-styled-typescript-styled-plugin/1')
    local plugin_root = mise_where
    -- mise where returns the tool root, packages are under lib/node_modules
    local npm_global_root = plugin_root ~= '' and (plugin_root .. '/lib/node_modules') or ''

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
