return function()
	return vim.fn.glob "biome.json" ~= ""
end
