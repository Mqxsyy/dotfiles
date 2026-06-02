vim.pack.add {
	"https://github.com/lopi-py/luau-lsp.nvim",
}

local function rojo_project()
	return vim.fs.root(0, function(name)
		return name:match "%.project.json$"
	end)
end

if rojo_project() then
	vim.filetype.add {
		extension = {
			lua = function(path)
				return path:match ".nvim.lua$" and "lua" or "luau"
			end,
		},
	}

	require("luau-lsp").setup {
		platform = {
			type = "standard",
		},
	}
else
	require("luau-lsp").setup {
		fflags = {
			enable_new_solver = true,
		},
	}
end
