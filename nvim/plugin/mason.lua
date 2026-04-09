vim.pack.add {
	"https://github.com/williamboman/mason.nvim",
	"https://github.com/williamboman/mason-lspconfig.nvim",
}

require("mason").setup {
	registries = {
		"github:mason-org/mason-registry",
		"github:Crashdummyy/mason-registry",
	},
}

require("mason-lspconfig").setup {
	automatic_installation = true,
	ensure_installed = {
		"lua_ls",
		"stylua",
	},
}
