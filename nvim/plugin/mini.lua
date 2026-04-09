vim.pack.add {
	"https://github.com/nvim-mini/mini.icons",
	"https://github.com/nvim-mini/mini.files",
	"https://github.com/nvim-mini/mini.pick",
	"https://github.com/nvim-mini/mini.pairs",
}

require("mini.icons").setup()
require("mini.files").setup()

local mini_pick = require "mini.pick"
mini_pick.setup()

local builtin = mini_pick.builtin
vim.keymap.set("n", "<C-p>", builtin.files, {})
vim.keymap.set("n", "<leader>fg", builtin.grep_live, {})
vim.keymap.set("n", "<leader>fb", builtin.buffers, {})

-- Src: https://gist.github.com/tmerse/dc21ec932860013e56882f23ee9ad8d2
require("mini.pairs").setup {
	modes = { insert = true, command = false, terminal = false },
	mappings = {
		[")"] = { action = "close", pair = "()", neigh_pattern = "[^\\]." },
		["]"] = { action = "close", pair = "[]", neigh_pattern = "[^\\]." },
		["}"] = { action = "close", pair = "{}", neigh_pattern = "[^\\]." },

		["["] = { action = "open", pair = "[]", neigh_pattern = ".[%s%z%)}%]]" },
		["{"] = { action = "open", pair = "{}", neigh_pattern = ".[%s%z%)}%]]" },
		["("] = { action = "open", pair = "()", neigh_pattern = ".[%s%z%)]" },

		['"'] = { action = "closeopen", pair = '""', neigh_pattern = "[^%w\\][^%w]" },
		["'"] = { action = "closeopen", pair = "''", neigh_pattern = "[^%w\\][^%w]" },
		["`"] = { action = "closeopen", pair = "``", neigh_pattern = "[^%w\\][^%w]" },
	},
}
