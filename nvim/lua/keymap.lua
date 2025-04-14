local map = require "utils.map"

local exported = {}

--> Nvim
map("i", "<C-h>", "<Left>")
map("i", "<C-j>", "<Down>")
map("i", "<C-k>", "<Up>")
map("i", "<C-l>", "<Right>")

map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

map("v", ">", ">gv", { noremap = true })
map("v", "<", "<gv", { noremap = true })

map("n", "<C-d>", "<C-d>zz", { noremap = true, silent = true })
map("n", "<C-u>", "<C-u>zz", { noremap = true, silent = true })

map("n", "n", "nzz", { noremap = true, silent = true })
map("n", "N", "Nzz", { noremap = true, silent = true })

--> LspConfig
map("n", "gd", vim.lsp.buf.definition)
map("n", "gD", vim.lsp.buf.declaration)
map("n", "gr", vim.lsp.buf.references)
map("n", "K", vim.lsp.buf.hover)
map("n", "<leader>r", vim.lsp.buf.rename)
map("n", "<leader>ca", vim.lsp.buf.code_action)

map("n", "<leader>e", vim.diagnostic.open_float)

--> Nonels
map("n", "<leader>ff", vim.lsp.buf.format)

--> Cmp
exported.cmp = {
	complete = "<C-Space>",
	select_next_item = "<C-j>",
	select_prev_item = "<C-k>",
	confirm = "<CR>",
}

--> NeoTree
map("n", "<C-e>", ":Neotree filesystem toggle left <CR>")

--> Flash
exported.flash = {
	jump = {
		key = "s",
		mode = { "n", "x", "o" },
	},
	treesitter = {
		key = "S",
		mode = { "n", "x", "o" },
	},
	remote = {
		key = "r",
		mode = { "o" },
	},
}

--> Namu
map("n", "<leader>s", ":Namu symbols<cr>", { silent = true })

--> Export
return exported
