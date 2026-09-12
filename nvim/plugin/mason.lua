vim.pack.add {
	"https://github.com/williamboman/mason.nvim",
}

require("mason").setup {
	registries = {
		"github:mason-org/mason-registry",
		"github:Crashdummyy/mason-registry",
	},
}
