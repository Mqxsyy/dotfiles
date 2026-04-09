vim.pack.add {
	"https://github.com/folke/tokyonight.nvim",
}

vim.cmd.colorscheme "tokyonight-night"

vim.cmd [[
	highlight Normal guibg=NONE ctermbg=NONE
	highlight NormalNC guibg=NONE ctermbg=NONE

	highlight StatusLine guibg=NONE ctermbg=NONE
	highlight StatusLineNC guibg=NONE ctermbg=NONE

	highlight SignColumn guibg=NONE ctermbg=NONE
]]
