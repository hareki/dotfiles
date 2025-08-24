vim.api.nvim_create_user_command('HLHere', function()
  local buf = 0
  local cur = vim.api.nvim_win_get_cursor(0) -- {line(1-based), col(0-based)}
  local row, col = cur[1] - 1, cur[2]
  local groups, seen = {}, {}

  local function push(name)
    if name and name ~= '' and not seen[name] then
      seen[name] = true
      table.insert(groups, name)
    end
  end

  if vim.inspect_pos then
    local info = vim.inspect_pos(buf, row, col)
    for _, x in ipairs(info.treesitter or {}) do
      push(x.hl_group or x.capture)
    end
    for _, x in ipairs(info.semantic_tokens or {}) do
      push(x.hl_group)
    end
    for _, x in ipairs(info.extmarks or {}) do
      push(x.hl_group)
    end
    for _, x in ipairs(info.syntax or {}) do
      push(x.hl_group or x.name)
    end
  else
    -- Fallback for older Neovim: use :synstack
    for _, id in ipairs(vim.fn.synstack(cur[1], col + 1)) do
      local name = vim.fn.synIDattr(vim.fn.synIDtrans(id), 'name')
      push(name)
    end
  end

  local title = ('HL @ %d:%d'):format(cur[1], col + 1)
  if #groups == 0 then
    vim.notify('No highlight groups here', vim.log.levels.INFO, { title = title })
  else
    vim.notify(table.concat(groups, ' -> '), vim.log.levels.INFO, { title = title })
  end
end, { desc = 'Show highlight groups under cursor' })

vim.api.nvim_create_user_command('TabRename', function(command_opts)
  vim.t.tab_name = command_opts.args
  require('lualine').refresh({ place = { 'statusline' } })
end, { nargs = 1 })
