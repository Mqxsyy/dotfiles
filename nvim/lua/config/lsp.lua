vim.lsp.enable {
	"lua_ls",
	"basedpyright",
	"qmlls",
	"roslyn",
	"gdscript",
	"ts_ls",
	"biome",
}

vim.diagnostic.config { virtual_text = true }

-- vim.lsp.config("*", {
-- 	capabilities = require("lsp").create_capabilities(),
-- })

--> Luau
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

--> Completions
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("my.lsp", {}),
	callback = function(args)
		local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
		if client:supports_method "textDocument/completion" then
			client.server_capabilities.completionProvider.triggerCharacters =
				vim.split("abcdefghijklmnopqrstuvwxyz.", "")

			vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
		end
	end,
})

vim.o.completeopt = "fuzzy,menuone,noinsert,popup"

--> Command to view Lsp logs
vim.api.nvim_create_user_command("LspLog", function()
	vim.cmd("edit " .. vim.lsp.get_log_path())
end, {})
