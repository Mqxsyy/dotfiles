vim.lsp.enable {
    "lua_ls",
}

vim.diagnostic.config { virtual_text = true }

vim.lsp.config("*", {
    capabilities = require("lsp").create_capabilities(),
})

--> Luau
vim.lsp.config("luau_lsp", {
    settings = {
        ["luau-lsp"] = {
            completion = {
                imports = {
                    enabled = true,
                    ignoreGlobs = { "**/_Index/**", "**/Packages/**", "**/ServerPackages/**" },
                },
            },
            require = {
                mode = "relativeToFile",
            },
            inlayHints = {
                functionReturnTypes = true,
                parameterTypes = true,
            },
            ignoreGlobs = { "**/_Index/**", "**/Packages/**", "**/ServerPackages/**" },
        },
    },
})

--> Command to view Lsp logs
vim.api.nvim_create_user_command("LspLog", function()
    vim.cmd("edit " .. vim.lsp.get_log_path())
end, {})
