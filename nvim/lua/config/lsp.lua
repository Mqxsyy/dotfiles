vim.lsp.config("*", {
	capabilities = {
		textDocument = {
			semanticTokens = {
				multilineTokenSupport = true,
			},
		},
	},
})

vim.diagnostic.config { virtual_text = true }
vim.o.completeopt = "fuzzy,menuone,noinsert,popup"
vim.o.pumheight = 10

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("my.lsp", {}),
	callback = function(args)
		local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
		if not client:supports_method("textDocument/completion") then
			return
		end

		client.server_capabilities.completionProvider.triggerCharacters = vim.split("abcdefghijklmnopqrstuvwxyz.", "")
		vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
	end,
})

vim.lsp.enable {
	"lua_ls",
	"basedpyright",
	"qmlls",
	"roslyn",
	"gdscript",
	"ts_ls",
	"biome",
}

vim.lsp.config("luau-lsp", {
	settings = {
		["luau-lsp"] = {
			completion = {
				imports = {
					enabled = true,
					ignoreGlobs = { "**/_Index/**" },
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
