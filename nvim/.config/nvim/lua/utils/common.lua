-- TODO: Lazy load/split functions and add documents
local M = {}

--- @param name? "frappe" | "latte" | "macchiato" | "mocha"
M.get_palette = function(name)
    return require("catppuccin.palettes").get_palette(name or "mocha")
end

---@generic T
---@param list T[]
---@return T[]
function M.deduplicate_list(list)
    local result = {}
    local seen = {}
    for _, v in ipairs(list) do
        if not seen[v] then
            table.insert(result, v)
            seen[v] = true
        end
    end
    return result
end

--- @param group string
--- @param style vim.api.keyset.highlight
M.highlight = function(group, style)
    vim.api.nvim_set_hl(0, group, style)
end

--- A table of custom highlight groups and their corresponding styles.
--- @param custom_highlights table<string, vim.api.keyset.highlight>
M.highlights = function(custom_highlights)
    for group, style in pairs(custom_highlights) do
        Util.highlight(group, style)
    end
end

function M.is_loaded(name)
    local Config = require("lazy.core.config")
    return Config.plugins[name] and Config.plugins[name]._.loaded
end

-- LazyVim
---@param name string
---@param fn fun(name:string)
function M.on_load(name, fn)
    if M.is_loaded(name) then
        fn(name)
    else
        vim.api.nvim_create_autocmd("User", {
            pattern = "LazyLoad",
            callback = function(event)
                if event.data == name then
                    fn(name)
                    return true
                end
            end,
        })
    end
end

return M
