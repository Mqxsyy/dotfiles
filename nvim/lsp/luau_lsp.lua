local function rojo_project(bufnr)
	return vim.fs.root(bufnr, function(name)
		return name:match ".+%.project%.json$"
	end)
end

local lspDir = vim.fn.stdpath "data" .. "/luau-lsp"

-- TODO: download and manage the files myself

return {
	cmd = {
		"luau-lsp",
		"lsp",
		"--definitions:@roblox=" .. lspDir .. "/globalTypes.PluginSecurity.d.luau",
		"--docs=" .. lspDir .. "/api-docs.json",
	},
	filetypes = { "luau" },
	root_markers = { ".git" },
	-- root_dir = function(bufnr, on_dir)
	-- 	on_dir(rojo_project(bufnr))
	-- end,
	settings = {
		["luau-lsp"] = {
			platform = {
				type = "roblox",
			},
			types = {
				roblox_security_level = "PluginSecurity",
			},
		},
	},
}
