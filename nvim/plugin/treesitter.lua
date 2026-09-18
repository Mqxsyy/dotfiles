-- TreeSitter is archived

vim.pack.add {
	"https://github.com/nvim-treesitter/nvim-treesitter",
}

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "luau", "gdscript", "gdshader" },
	callback = function()
		vim.treesitter.start()
	end,
})

require("nvim-treesitter").install { "luau", "gdscript", "gdshader" }
