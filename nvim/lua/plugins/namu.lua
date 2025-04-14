return {
	"bassamsdata/namu.nvim",
	config = function()
		require("namu").setup {
			namu_symbols = {
				enable = true,
				options = {
					AllowKinds = {
						luau = { "Function" },
					},
					movement = {
						next = { "<C-j>" },
						previous = { "<C-k>" },
					},
				},
			},
			ui_select = { enable = false },
		}
	end,
}
