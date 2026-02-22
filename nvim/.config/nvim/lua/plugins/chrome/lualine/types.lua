---@meta _

-- Types extracted from https://github.com/nvim-lualine/lualine.nvim/blob/master/lua/lualine/component.lua
---@class lualine.component
---@field super lualine.component
---@field options table
---@field status string
---@field init fun(self, options?: table)
---@field create_hl fun(self, color: table|string|function, hint?: string): table
---@field format_hl fun(self, hl_token: table): string
