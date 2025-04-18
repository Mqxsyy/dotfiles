return function()
	return vim.fn.glob ".prettierrc.json" ~= ""
end
