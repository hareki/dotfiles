---@class constant.icons
---@field misc table<string, string>
---@field ft table<string, string>
---@field dap table<string, string | table<string, string>>
---@field diagnostics table<string, string>
---@field git table<string, string>
---@field kinds table<string, string>
local M = {
    misc = {
        dots = "󰇘",
    },
    ft = {
        octo = "",
    },
    dap = {
        Stopped             = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
        Breakpoint          = " ",
        BreakpointCondition = " ",
        BreakpointRejected  = { " ", "DiagnosticError" },
        LogPoint            = ".>",
    },
    diagnostics = {
        Error = " ",
        Warn  = " ",
        Hint  = " ",
        Info  = " ",
    },
    git = {
        added    = " ",
        modified = " ",
        removed  = " ",
    },
    kinds = {
        Array         = " ",
        Boolean       = "󰨙 ",
        Class         = " ",
        Codeium       = "󰘦 ",
        Color         = " ",
        Control       = " ",
        Collapsed     = " ",
        Constant      = "󰏿 ",
        Constructor   = " ",
        Copilot       = " ",
        Enum          = " ",
        EnumMember    = " ",
        Event         = " ",
        Field         = " ",
        File          = " ",
        Folder        = " ",
        Function      = "󰊕 ",
        Interface     = " ",
        Key           = " ",
        Keyword       = " ",
        Method        = "󰊕 ",
        Module        = " ",
        Namespace     = "󰦮 ",
        Null          = " ",
        Number        = "󰎠 ",
        Object        = " ",
        Operator      = " ",
        Package       = " ",
        Property      = " ",
        Reference     = " ",
        Snippet       = "󱄽 ",
        String        = " ",
        Struct        = "󰆼 ",
        Supermaven    = " ",
        TabNine       = "󰏚 ",
        Text          = " ",
        TypeParameter = " ",
        Unit          = " ",
        Value         = " ",
        Variable      = "󰀫 ",
    },
}


return M
