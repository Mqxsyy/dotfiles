return {
	{
		"nvim-mini/mini.icons",
		version = false,
		config = function()
			require("mini.icons").setup()
		end,
	},
	{
		"nvim-mini/mini.pairs",
		version = false,
		config = function()
			require("mini.pairs").setup()
		end,
	},
	{
		"nvim-mini/mini.files",
		version = false,
		config = function()
			require("mini.files").setup()
		end,
	},
	{
		"nvim-mini/mini.pick",
		version = false,
		config = function()
			require("mini.pick").setup()

			local builtin = require("mini.pick").builtin

			vim.keymap.set("n", "<C-p>", builtin.files, {})
			vim.keymap.set("n", "<leader>fg", builtin.grep_live, {})
			vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
		end,
	},
}
