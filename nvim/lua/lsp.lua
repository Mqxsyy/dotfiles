vim.api.nvim_create_user_command("LspInfo", function()
	vim.cmd "checkhealth vim.lsp"
end, {})

vim.api.nvim_create_user_command("LspLog", function()
	vim.cmd("edit " .. vim.lsp.log.get_filename())
end, {})

vim.diagnostic.config { virtual_text = true }

vim.lsp.enable {
	"lua_ls",

	"gdscript",
	"roslyn",

	"basedpyright",
	"ruff",

	-- "bashls",
	-- "qmlls",
	-- "ts_ls",
	-- "biome",
}
