local findPrettierConfig = require "utils.findPrettierConfig"

return {
	"nvimtools/none-ls.nvim",
	config = function()
		local null_ls = require "null-ls"

		local helpers = require "null-ls.helpers"
		local methods = require "null-ls.methods"

		local FORMATTING = methods.internal.FORMATTING
		local DIAGNOSTICS = methods.internal.DIAGNOSTICS

		local sources = {
			null_ls.builtins.formatting.stylua,

			-- gdscript format
			helpers.make_builtin {
				factory = helpers.formatter_factory,
				filetypes = { "gd", "gdscript" },
				generator_opts = {
					command = "gdscript-formatter",
					args = { "--safe" },
					to_stdin = true,
				},
				method = { FORMATTING },
			},

			-- gdscript lint
			helpers.make_builtin {
				factory = helpers.generator_factory,
				filetypes = { "gd", "gdscript" },
				generator_opts = {
					command = "gdscript-formatter",
					args = { "lint", "$FILENAME" },
					to_stdin = false,
					from_stderr = true,
					to_temp_file = true,
					format = "line",
					on_output = helpers.diagnostics.from_patterns {
						{
							pattern = [[^.+:(%d+):[^:]+:[^:]+: (.+)$]],
							groups = { "row", "message" },
						},
					},
				},
				method = DIAGNOSTICS,
			},
		}

		if findPrettierConfig() then
			table.insert(sources, null_ls.builtins.formatting.prettierd)
		else
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
		end

		null_ls.setup { sources = sources }
	end,
}
