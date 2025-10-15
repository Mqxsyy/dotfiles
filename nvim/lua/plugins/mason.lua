return {
	{
		"williamboman/mason.nvim",
		lazy = false,
		config = function()
			require("mason").setup {
				registries = {
					"github:mason-org/mason-registry",
					"github:Crashdummyy/mason-registry",
				},
			}
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		lazy = false,
		config = function()
			require("mason-lspconfig").setup {
				automatic_installation = true,
				ensure_installed = {
					-- Lua + Luau
					"lua_ls",
					"luau_lsp",

					-- TypeScript
					"ts_ls",
					"biome",

					-- Python
					"basedpyright",
				},
			}
		end,
	},
}
