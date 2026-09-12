return {
	cmd = vim.lsp.rpc.connect("127.0.0.1", 6005),
	filetypes = { "gd" },
	root_markers = { "project.godot", ".git" },
}
