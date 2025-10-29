local keymap = require "keymap"

return {
	{
		"hrsh7th/cmp-nvim-lsp",
	},
	-- {
	-- 	"L3MON4D3/LuaSnip",
	-- 	dependencies = {
	-- 		"saadparwaiz1/cmp_luasnip",
	-- 		"rafamadriz/friendly-snippets",
	-- 	},
	-- 	config = function()
	-- 		require("luasnip").filetype_extend("luau", { "lua" })
	-- 	end,
	-- },
	{
		"hrsh7th/nvim-cmp",
		config = function()
			local cmp = require "cmp"
			-- require("luasnip.loaders.from_vscode").lazy_load()

			cmp.setup {
				-- snippet = {
				-- 	expand = function(args)
				-- 		require("luasnip").lsp_expand(args.body)
				-- 	end,
				-- },
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				mapping = cmp.mapping.preset.insert {
					[keymap.cmp.complete] = cmp.mapping.complete(),
					[keymap.cmp.select_next_item] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert },
					[keymap.cmp.select_prev_item] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert },
					[keymap.cmp.confirm] = cmp.mapping.confirm { select = true },
				},
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					-- { name = "luasnip" },
				}, {
					{ name = "buffer" },
				}),
			}
		end,
	},
}
