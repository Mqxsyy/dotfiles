local colors = require "nvim-lualine-colors"

local theme = {
    normal = {
        a = { bg = colors.bg, fg = colors.fg, gui = "bold" },
        b = { bg = colors.bg, fg = colors.fg },
        c = { bg = "", fg = "" },
    },
    insert = {
        a = { bg = colors.insert_bg, fg = colors.insert_fg, gui = "bold" },
        b = { bg = colors.insert_bg, fg = colors.insert_fg },
        c = { bg = colors.insert_bg, fg = colors.insert_fg },
    },
    visual = {
        a = { bg = colors.viausl_bg, fg = colors.viausl_fg, gui = "bold" },
        b = { bg = colors.viausl_bg, fg = colors.viausl_fg },
        c = { bg = colors.viausl_bg, fg = colors.viausl_fg },
    },
    replace = {
        a = { bg = colors.replace_bg, fg = colors.replace_fg, gui = "bold" },
        b = { bg = colors.replace_bg, fg = colors.replace_fg },
        c = { bg = colors.replace_bg, fg = colors.replace_fg },
    },
    command = {
        a = { bg = colors.command_bg, fg = colors.command_fg, gui = "bold" },
        b = { bg = colors.command_bg, fg = colors.command_fg },
        c = { bg = colors.command_bg, fg = colors.command_fg },
    },
    inactive = {
        a = { bg = colors.inactive_bg, fg = colors.inactive_fg, gui = "bold" },
        b = { bg = colors.inactive_bg, fg = colors.inactive_fg },
        c = { bg = colors.inactive_bg, fg = colors.inactive_fg },
    },
}

return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
        options = {
            theme = theme,
        },
        sections = {
            lualine_a = { "mode" },
            lualine_b = { "filename" },
            lualine_c = { },
            lualine_x = { "diagnostics" },
            lualine_y = { "diff" },
            lualine_z = { "branch" },
        },
        inactive_sections = {
            lualine_b = { "filename" },
            lualine_c = {},
            lualine_a = {},
            lualine_y = {},
            lualine_z = {},
            lualine_x = {},
        },
    },
}
