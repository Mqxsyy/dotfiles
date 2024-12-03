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
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    config = function()
        require("luau-lsp").setup {
            platform = {
                type = "roblox",
            },
            types = {
                roblox_security_level = "PluginSecurity",
            },
            sourcemap = {
                enabled = true,
                autogenerate = true,
                rojo_project_file = "default.project.json",
            },
            server = {
                capabilities = require("lsp").create_capabilities(),
                settings = {
                    ["luau-lsp"] = {
                        completion = {
                            imports = {
                                enabled = true,
                            },
                        },
                        require = {
                            mode = "relativeToFile",
                            directoryAliases = require("luau-lsp").aliases(),
                        },
                        inlayHints = {
                            functionReturnTypes = true,
                            parameterTypes = true,
                        },
                    },
                },
            },
        }
    end,
}
