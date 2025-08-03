local M = {}

-- math.random in Lua is deterministic until you seed it yourself.
math.randomseed(vim.loop.hrtime())
math.random() -- Discard the first linear-congruential generator (LCG) output, it's quite repeatable.

function M.get_random_quote()
  local quotes = {
    {
      '“Most people fail in life not because they aim too high and miss,',
      'but because they aim too low and hit.” — Les Brown',
    },
    {
      "“If you set your goals ridiculously high and it's a failure",
      "you will fail above everyone else's success.” — James Cameron",
    },
    {
      '“Never feel shame for trying and failing, for he who has never failed ',
      'is he who has never tried.” — Og Mandino',
    },
    { '“There is little success where there is little laughter.” — Andrew Carnegie' },
  }
  local random_index = math.random(1, #quotes)
  local selected_quote = quotes[random_index]

  local footer = {}

  for _, line in ipairs(selected_quote) do
    table.insert(
      footer,
      { type = 'text', val = line, opts = { position = 'center', hl = 'AlphaQuote' } }
    )
  end

  return footer
end

function M.get_recent_projects()
  local projects = {}
  for i = 1, 4 do
    table.insert(projects, {
      type = 'text',
      val = 'Project ' .. i,
      opts = {
        position = 'center',
        shrink_margin = false,
        hl = 'AlphaItem',
      },
    })
  end
  return projects
end

function M.get_recent_files()
  local files = {}
  for i = 1, 4 do
    table.insert(files, {
      type = 'text',
      val = 'File ' .. i,
      opts = {
        position = 'center',
        shrink_margin = false,
        hl = 'AlphaItem',
      },
    })
  end
  return files
end

function M.get_stats()
  local stats = require('lazy').stats()
  local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)

  local version = vim.version()
  local formatted_version = string.format('%d.%d.%d', version.major, version.minor, version.patch)

  return ' '
    .. stats.loaded
    .. '/'
    .. stats.count
    .. ' plugins  󱎫 '
    .. ms
    .. ' ms   v'
    .. formatted_version
end

function M.get_vertical_offset()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype ~= 'alpha' then
    return 0
  end

  local window_height = vim.opt.lines:get()
  local content_height = vim.api.nvim_buf_line_count(bufnr)

  local remaining_height = window_height - content_height
  local is_even = remaining_height % 2 == 0
  local size = math.floor(((window_height - content_height) / 2)) - (is_even and 1 or 0)
  return size
end

return M
