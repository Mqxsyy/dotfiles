local findBiomeConfig = require "../findFiles/findBiomeConfig"

return {
	"nvimtools/none-ls.nvim",
	config = function()
		local null_ls = require "null-ls"

		local sources = {
			null_ls.builtins.formatting.stylua,
		}

		if findBiomeConfig() then
			table.insert(
				sources,
				null_ls.builtins.formatting.biome.with {
					args = {
						"check",
						"--write",
						"--skip-errors",
						"--stdin-file-path=$FILENAME",
					},
				}
			)
		else
			table.insert(sources, null_ls.builtins.formatting.prettierd)
		end

		null_ls.setup {
			sources = sources,
		}

		vim.keymap.set("n", "<leader>ff", vim.lsp.buf.format, {})
	end,
}
