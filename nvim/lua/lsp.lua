local function create_capabilities()
	local capabilities = vim.tbl_deep_extend(
		"force",
		vim.lsp.protocol.make_client_capabilities(),
		require("cmp_nvim_lsp").default_capabilities()
	)

	return vim.tbl_deep_extend("force", capabilities, {
		workspace = {
			didChangeWatchedFiles = {
				dynamicRegistration = true,
			},
		},
	})
end

vim.lsp.enable {
	"lua_ls",
	"basedpyright",
	"qmlls",
	"roslyn",
	"gdscript",
	"ts_ls",
	"biome",
	"rust-analyzer",
}

vim.diagnostic.config { virtual_text = true }

vim.lsp.config("*", {
	capabilities = create_capabilities(),
})

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

--> Command to view Lsp logs
vim.api.nvim_create_user_command("LspLog", function()
	vim.cmd("edit " .. vim.lsp.get_log_path())
end, {})
