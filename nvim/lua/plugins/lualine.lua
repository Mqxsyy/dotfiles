local colors = require "nvim-lualine-colors"

local theme = {
    normal = {
        a = { bg = colors.bg_normal_a, fg = colors.fg_normal, gui = "bold" },
        b = { bg = colors.bg_normal_b, fg = colors.fg_normal },
        c = { bg = "", fg = colors.fg_normal },
    },
    insert = {
        a = { bg = colors.bg_insert_a, fg = colors.fg_insert, gui = "bold" },
        b = { bg = colors.bg_insert_b, fg = colors.fg_insert },
        c = { bg = "", fg = colors.fg_insert },
    },
    visual = {
        a = { bg = colors.bg_visual_a, fg = colors.fg_visual, gui = "bold" },
        b = { bg = colors.bg_visual_b, fg = colors.fg_visual },
        c = { bg = "", fg = colors.fg_visual },
    },
    command = {
        a = { bg = colors.bg_command_a, fg = colors.fg_command, gui = "bold" },
        b = { bg = colors.bg_command_b, fg = colors.fg_command },
        c = { bg = "", fg = colors.fg_command },
    },
    replace = {
        a = { bg = colors.bg_replace_a, fg = colors.fg_replace, gui = "bold" },
        b = { bg = colors.bg_replace_b, fg = colors.fg_replace },
        c = { bg = "", fg = colors.fg_replace },
    },
    inactive = {
        a = { bg = colors.bg_inactive_a, fg = colors.fg_inactive, gui = "bold" },
        b = { bg = colors.bg_inactive_b, fg = colors.fg_inactive },
        c = { bg = "", fg = colors.fg_inactive },
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
            lualine_c = { "diagnostics" },
            lualine_x = {},
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
