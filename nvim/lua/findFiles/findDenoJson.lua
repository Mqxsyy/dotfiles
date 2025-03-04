return function()
	return vim.fn.glob "deno.json" ~= ""
end
