local keymap = require "keymap"

return {
	{
		"hrsh7th/cmp-nvim-lsp",
	},
	{
		"hrsh7th/nvim-cmp",
		config = function()
			local cmp = require "cmp"

			cmp.setup {
				snippet = {
					expand = function(args)
						vim.snippet.expand(args.body)
					end,
				},
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
				}, {
					{ name = "buffer" },
				}),
			}
		end,
	},
}
