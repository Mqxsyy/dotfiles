return {
    {
        "williamboman/mason.nvim",
        lazy = false,
        config = function()
            require("mason").setup()
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        lazy = false,
        config = function()
            require("mason-lspconfig").setup {
                automatic_installation = true,
                ensure_installed = {
                    "lua_ls",
                    "luau_lsp",
                    "ts_ls",

                    "biome",
                },
            }
        end,
    },
}
