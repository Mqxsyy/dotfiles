return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup {
				ensure_installed = {
					"lua_ls",
					"ts_ls",

					"biome",
				},
			}
		end,
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			local capabilities = require("lsp").create_capabilities()

			require("lspconfig").lua_ls.setup {
				capabilities = capabilities,
				on_init = function(client)
					if client.workspace_folders then
						local path = client.workspace_folders[1].name
						if
							path ~= vim.fn.stdpath "config"
							and (vim.loop.fs_stat(path .. "/.luarc.json") or vim.loop.fs_stat(path .. "/.luarc.jsonc"))
						then
							return
						end
					end

					client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
						runtime = {
							version = "LuaJIT",
						},
						workspace = {
							checkThirdParty = false,
							library = {
								vim.env.VIMRUNTIME,
							},
						},
					})
				end,
				settings = {
					Lua = {},
				},
			}
			require("lspconfig").biome.setup(capabilities)
			require("lspconfig").ts_ls.setup(capabilities)
			require("lspconfig").bashls.setup(capabilities)
		end,
	},
}
