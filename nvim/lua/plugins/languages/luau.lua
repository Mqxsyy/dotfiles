local function rojo_project()
    return vim.fs.root(0, function(name)
        return name:match "%.project.json$"
    end)
end

if rojo_project() then
    vim.filetype.add {
        extension = {
            lua = function(path)
                return path:match ".nvim.lua$" and "lua" or "luau"
            end,
        },
    }
end

return {
    "lopi-py/luau-lsp.nvim",
    branch = "nvim-011",
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    config = function()
        require("luau-lsp").setup {
            platform = {
                type = "roblox",
            },
            sourcemap = {
                enabled = true,
                autogenerate = true,
                rojo_project_file = "default.project.json",
            },
            types = {
                roblox_security_level = "PluginSecurity",
            },
            fflags = {
                enable_new_solver = false,
                sync = true,
            },
        }
    end,
}
