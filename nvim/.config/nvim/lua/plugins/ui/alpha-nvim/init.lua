-- https://github.com/goolord/alpha-nvim/blob/2b3cbcdd980cae1e022409289245053f62fb50f6/lua/alpha.lua#L571
local function should_skip_alpha()
  -- don't start when opening a file
  if vim.fn.argc() > 0 then
    return true
  end

  -- Do not open alpha if the current buffer has any lines (something opened explicitly).
  local lines = vim.api.nvim_buf_get_lines(0, 0, 2, false)
  if #lines > 1 or (#lines == 1 and lines[1]:len() > 0) then
    return true
  end

  -- Skip when there are several listed buffers.
  for _, buf_id in pairs(vim.api.nvim_list_bufs()) do
    local bufinfo = vim.fn.getbufinfo(buf_id)
    if bufinfo.listed == 1 and #bufinfo.windows > 0 then
      return true
    end
  end

  -- Handle nvim -M
  if not vim.o.modifiable then
    return true
  end

  ---@diagnostic disable-next-line: undefined-field
  for _, arg in pairs(vim.v.argv) do
    -- whitelisted arguments
    -- always open
    if arg == '--startuptime' then
      return false
    end

    -- blacklisted arguments
    -- always skip
    if
      arg == '-b'
      -- commands, typically used for scripting
      or arg == '-c'
      or vim.startswith(arg, '+')
      or arg == '-S'
    then
      return true
    end
  end

  -- base case: don't skip
  return false
end

return {
  'goolord/alpha-nvim',
  cmd = 'Alpha',
  init = function()
    vim.api.nvim_create_autocmd('VimEnter', {
      once = true,
      callback = function()
        if should_skip_alpha() then
          return
        end

        vim.cmd.Alpha()
      end,
    })
  end,
  opts = function()
    local ui_utils = require('utils.ui')
    local palette = ui_utils.get_palette()
    local utils = require('plugins.ui.alpha-nvim.utils')

    ui_utils.set_highlights({
      AlphaHeader = { fg = palette.blue },
      AlphaStats = { fg = palette.yellow },
      AlphaTitle = { fg = palette.blue },
      AlphaItem = { fg = palette.text },
      AlphaQuote = { fg = palette.green, italic = true },
    })

    local vertical_offset = {
      type = 'padding',
      val = 0,
    }

    local header = {
      type = 'text',
      val = {
        [[                                                                     ]],
        [[       ████ ██████           █████      ██                     ]],
        [[      ███████████             █████                             ]],
        [[      █████████ ███████████████████ ███   ███████████   ]],
        [[     █████████  ███    █████████████ █████ ██████████████   ]],
        [[    █████████ ██████████ █████████ █████ █████ ████ █████   ]],
        [[  ███████████ ███    ███ █████████ █████ █████ ████ █████  ]],
        [[ ██████  █████████████████████ ████ █████ █████ ████ ██████ ]],
      },
      opts = {
        position = 'center',
        hl = 'AlphaHeader',
      },
    }

    local stats = {
      type = 'text',
      val = '',
      opts = {
        position = 'center',
        hl = 'AlphaStats',
      },
    }

    local projects = {
      type = 'group',
      opts = {},
      val = {
        {
          type = 'text',
          val = '󰪺 Projects',
          opts = { position = 'center', hl = 'AlphaTitle', shrink_margin = false },
        },

        {
          type = 'group',
          val = utils.get_recent_projects(),
        },
      },
    }

    local files = {
      type = 'group',
      val = {
        {
          type = 'text',
          val = '󰪺 Files',
          opts = { position = 'center', hl = 'AlphaTitle', shrink_margin = false },
        },

        {
          type = 'group',
          val = utils.get_recent_files(),
        },
      },
    }

    local quote = {
      type = 'group',
      val = utils.get_random_quote(),
    }

    local section = {
      vertical_offset = vertical_offset,
      header = header,
      stats = stats,
      projects = projects,
      files = files,
      quote = quote,
    }

    local config = {
      layout = {
        section.vertical_offset,
        section.header,
        { type = 'padding', val = 1 },
        section.stats,
        { type = 'padding', val = 1 },
        section.projects,
        { type = 'padding', val = 1 },
        section.files,
        { type = 'padding', val = 1 },
        section.quote,
      },

      opts = {
        noautocmd = true,
        autostart = false,
      },
    }

    return {
      config = config,
      section = section,
    }
  end,
  config = function(_, dashboard)
    local utils = require('plugins.ui.alpha-nvim.utils')

    vim.api.nvim_create_autocmd('User', {
      once = true,
      pattern = 'AlphaReady',
      callback = function(ev)
        local alpha_buf = ev.buf
        local map = vim.keymap.set

        map({ 'n', 'v' }, '<PageUp>', '<C-u>', { desc = 'Scroll up', buffer = alpha_buf })
        map({ 'n', 'v' }, '<PageDown>', '<C-d>', { desc = 'Scroll down', buffer = alpha_buf })
      end,
    })

    -- Free up memory, not sure how effective this is, but it should help
    vim.api.nvim_create_autocmd('User', {
      once = true,
      pattern = 'AlphaClosed',
      callback = function()
        for k, _ in pairs(dashboard.config) do
          dashboard.config[k] = nil
        end

        for k, _ in pairs(dashboard.section) do
          dashboard.section[k] = nil
        end

        for k, _ in pairs(dashboard) do
          dashboard[k] = nil
        end

        -- No going back to Alpha after closing it
        pcall(vim.api.nvim_del_user_command, 'Alpha')
        pcall(vim.api.nvim_del_user_command, 'AlphaRedraw')
        pcall(vim.api.nvim_del_user_command, 'AlphaRemap')

        for name, _ in pairs(package.loaded) do
          if name:match('^alpha') then
            package.loaded[name] = nil
          end
        end
        package.loaded['plugins.ui.alpha-nvim.utils'] = nil

        collectgarbage('collect')
      end,
    })

    vim.api.nvim_create_autocmd('User', {
      once = true,
      pattern = 'LazyVimStarted',
      callback = function()
        dashboard.section.stats.val = utils.get_stats()
        dashboard.section.vertical_offset.val = utils.get_vertical_offset()

        pcall(vim.cmd.AlphaRedraw)
      end,
    })

    require('alpha').setup(dashboard.config)
  end,
}
