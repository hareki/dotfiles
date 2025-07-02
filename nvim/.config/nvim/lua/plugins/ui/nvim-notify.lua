local function renderer(bufnr, notif, highlights, config)
    local api = vim.api
    local base = require("notify.render.base")
    local icon = notif.icon
    local message = notif.message
    local namespace = base.namespace()

    -- Normal body highlight, same as the stock "minimal" renderer
    api.nvim_buf_set_lines(bufnr, 0, -1, false, message)
    api.nvim_buf_set_extmark(bufnr, namespace, 0, 0, {
        hl_group = highlights.icon,
        end_line = #message - 1,
        end_col = #message[#message],
        priority = 50,
    })

    -- Let the floating-window border itself carry the title
    local title = notif.title[1] or ""
    if notif.duplicates then
        title = string.format("%s (x%d)", title, #notif.duplicates)
    end
    title = string.format(" %s %s ", icon, title)

    -- We don't have the win id to set the title yet => temporarly store it in the buffer variable, set it on `on_open`
    api.nvim_buf_set_var(bufnr, "notify_border_title", title)
    api.nvim_buf_set_var(bufnr, "notify_border_title_hl", highlights.title)
end

return {
    "rcarriga/nvim-notify",
    keys = {
        {
            "<leader>un",
            function()
                require("notify").dismiss({ silent = true, pending = true })
            end,
            desc = "Dismiss All Notifications",
        },
    },
    opts = {
        stages = "static",
        timeout = 10000,
        render = renderer,
        max_height = function()
            return math.floor(vim.o.lines * 0.75)
        end,
        max_width = function()
            return math.floor(vim.o.columns * 0.75)
        end,
        on_open = function(win)
            local api = vim.api
            api.nvim_win_set_config(win, { zindex = 100 })

            local buf = api.nvim_win_get_buf(win)
            local ok1, title = pcall(api.nvim_buf_get_var, buf, "notify_border_title")
            local ok2, title_hl = pcall(api.nvim_buf_get_var, buf, "notify_border_title_hl")

            if ok1 and ok2 and title ~= "" then
                api.nvim_win_set_config(win, {
                    title = title,
                    title_pos = "center",
                })

                local winhl = api.nvim_win_get_option(win, "winhighlight")
                local prefix = (winhl ~= "" and (winhl .. ",") or "")
                api.nvim_win_set_option(
                    win,
                    "winhighlight",
                    -- Keep existing highlight mappings and append title_hl mapping to match the notification styles
                    prefix .. "FloatTitle:" .. title_hl
                )
            end
        end,
    },
}
