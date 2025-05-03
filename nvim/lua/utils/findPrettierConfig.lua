return function()
	return vim.fn.glob ".prettierrc" ~= ""
end
