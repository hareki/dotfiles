-- features.git.snacks-nvim.lazygit as lazygit's config.yml reaches it: each edit command sends a
-- `--remote-expr` to this nvim first, and one that fails stops the `&&` chain before the file opens

local t = require('tests.lib.helpers')

-- The dotfiles repo holds this config at nvim/.config/nvim, beside lazygit/.config/lazygit
local repo = vim.fs.dirname(
  vim.fs.dirname(vim.fs.dirname(assert(vim.uv.fs_realpath(vim.env.NVIM_TEST_CONFIG))))
)
local config_yml = vim.fs.joinpath(repo, 'lazygit/.config/lazygit/config.yml')

t.test("every --remote-expr in lazygit's edit commands evaluates here", function()
  local exprs = {}
  for expr in vim.fn.readblob(config_yml):gmatch('%-%-remote%-expr "([^"]+)"') do
    exprs[#exprs + 1] = expr
  end
  t.ok(#exprs > 0, 'config.yml sends no --remote-expr')

  for _, expr in ipairs(exprs) do
    --- @type vim.SystemCompleted?
    local result
    vim.system(
      { vim.v.progpath, '--headless', '--server', vim.v.servername, '--remote-expr', expr },
      { timeout = 5000 },
      function(completed)
        result = completed
      end
    )
    -- Not SystemObj:wait(), which runs only fast events and so never answers the client's request
    t.wait_for(function()
      return result ~= nil
    end, expr, 6000)

    local completed = assert(result)
    t.eq(completed.code, 0, string.format('%s: %s', expr, completed.stderr))
  end
end)
