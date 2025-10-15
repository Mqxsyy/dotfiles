return {
	"nvim-neo-tree/neo-tree.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		require("neo-tree").setup {
			filesystem = {
				filtered_items = {
					hide_by_pattern = {
						"*.gd.uid",
						"*.tscn",
					},
					show_hidden_count = false,
				},
			},
		}
	end,
}
