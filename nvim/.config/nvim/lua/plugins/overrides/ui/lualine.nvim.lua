-- Enum-like structure for branch formats
local branch_formats = {
  TASK_ID_ONLY = "task id only",
  TASK_ID_AND_NAME = "task id and name",
  TASK_ID_AND_AUTHOR = "task id and author",
}

-- Start with the default branch format
local branch_display_mode = branch_formats.TASK_ID_ONLY
-- Prevent yelling incorret branch format for the first time loading
local is_first_time_format_set = true

local task_name_start_length = 15
local task_name_end_length = 5
local max_task_name_length = task_name_start_length + task_name_end_length

-- Helper function to check valid branch format
local function is_valid_branch_format(format)
  for _, value in pairs(branch_formats) do
    if value == format then
      return true
    end
  end
  return false
end

local function set_branch_name_format(format_name)
  if is_valid_branch_format(format_name) then
    branch_display_mode = format_name
    LazyVim.notify("Branch name format set to " .. format_name)
    require("lualine").refresh()
  else
    LazyVim.error("Invalid branch name format: " .. format_name)
  end
end

-- Format branch name based on the current display mode
local function format_branch_name(branch_name)
  -- Check if the branch name follows the ClickUp format
  local is_clickup_format = branch_name:match("^CU%-%w+_.+_.+$")
  if not is_clickup_format then
    return branch_name
  end

  is_first_time_format_set = false

  -- Extract the prefix (task ID), task name, and author name
  local prefix, task_name, author_name = branch_name:match("^(CU%-%w+)_([^_]+)_(.+)$")

  -- Handle formatting for different display modes
  if branch_display_mode == branch_formats.TASK_ID_ONLY then
    return prefix
  elseif branch_display_mode == branch_formats.TASK_ID_AND_NAME then
    -- Display task ID and formatted task name
    local formatted_task_name
    if #task_name > max_task_name_length then
      -- Show start and end parts of the task name with ellipsis
      formatted_task_name = task_name:sub(1, task_name_start_length) .. "..." .. task_name:sub(-task_name_end_length)
    else
      formatted_task_name = task_name
    end
    return prefix .. "_" .. formatted_task_name
  elseif branch_display_mode == branch_formats.TASK_ID_AND_AUTHOR then
    -- Display task ID and author name
    return prefix .. "_" .. author_name
  end
end

return {
  "nvim-lualine/lualine.nvim",
  keys = {
    {
      "<leader>ul1",
      function()
        set_branch_name_format(branch_formats.TASK_ID_ONLY)
      end,
      desc = "Set task id only branch name format",
    },
    {
      "<leader>ul2",
      function()
        set_branch_name_format(branch_formats.TASK_ID_AND_NAME)
      end,
      desc = "Set task id and task name branch name format",
    },
    {
      "<leader>ul3",
      function()
        set_branch_name_format(branch_formats.TASK_ID_AND_AUTHOR)
      end,
      desc = "Set task id and author branch name format",
    },
  },
  opts = function(_, opts)
    local icons = LazyVim.config.icons

    opts.options.section_separators = { left = "", right = "" }
    opts.options.component_separators = { left = "", right = "" }

    local extensions = opts.extensions
    for i = #extensions, 1, -1 do
      if extensions[i] == "neo-tree" then
        table.remove(extensions, i)
      end
    end

    -- Update lualine_b section with formatted branch name
    opts.sections.lualine_b = {
      {
        "branch",
        fmt = format_branch_name,
      },
      {
        "diff",
        symbols = {
          added = icons.git.added,
          modified = icons.git.modified,
          removed = icons.git.removed,
        },
        source = function()
          local gitsigns = vim.b.gitsigns_status_dict
          if gitsigns then
            return {
              added = gitsigns.added,
              modified = gitsigns.changed,
              removed = gitsigns.removed,
            }
          end
        end,
      },
    }

    table.insert(opts.sections.lualine_c, 1, {
      function()
        local cwd = vim.loop.cwd()
        return cwd:match("([^/]+)$")
      end,
      icon = "󱉭",
    })

    -- ===== SECTION X ====
    Util.remove_lualine_component("diff", opts.sections.lualine_x)

    -- ===== SECTION Y ====
    opts.sections.lualine_y = {
      {
        "diagnostics",
        symbols = {
          error = icons.diagnostics.Error,
          warn = icons.diagnostics.Warn,
          info = icons.diagnostics.Info,
          hint = icons.diagnostics.Hint,
        },
        always_visible = true,
      },
    }

    -- ===== SECTION Z ====
    opts.sections.lualine_z = {
      { "location", padding = { left = 1, right = 1 }, separator = "|" },
      { "progress", padding = { left = 1, right = 1 }, separator = "|" },
    }
  end,
}
