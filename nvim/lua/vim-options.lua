vim.cmd "set expandtab"
vim.cmd "set tabstop=4"
vim.cmd "set softtabstop=4"
vim.cmd "set shiftwidth=4"
vim.cmd "set scrolloff=10"

vim.opt.swapfile = false

vim.cmd "set clipboard+=unnamedplus"
-- vim.g.clipboard = {
-- 	name = "WslClipboard",
-- 	copy = {
-- 		["+"] = "clip.exe",
-- 		["*"] = "clip.exe",
-- 	},
-- 	paste = {
-- 		["+"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
-- 		["*"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
-- 	},
-- 	cache_enabled = 0,
-- }

vim.g.mapleader = " "

vim.opt.number = true
vim.o.relativenumber = true

vim.api.nvim_set_keymap("n", "<C-d>", "<C-d>zz", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-u>", "<C-u>zz", { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "n", "nzz", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "N", "Nzz", { noremap = true, silent = true })

-- vim.api.nvim_create_autocmd("LspAttach", {
--     group = vim.api.nvim_create_augroup("lsp", { clear = true }),
--     callback = function(args)
--         vim.api.nvim_create_autocmd("BufWritePre", {
--             buffer = args.buf,
--             callback = function()
--                 vim.lsp.buf.format { async = false, id = args.data.client_id }
--             end,
--         })
--     end,
-- })

local map = vim.keymap.set
map("i", "<C-h>", "<Left>", {})
map("i", "<C-j>", "<Down>", {})
map("i", "<C-k>", "<Up>", {})
map("i", "<C-l>", "<Right>", {})

vim.cmd "cnoreabbrev W w"
vim.cmd "cnoreabbrev Wqa wqa"
