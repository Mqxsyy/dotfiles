return {
	cmd = { "biome", "lsp-proxy" },
	filetypes = { "javascript", "typescript", "json", "css", "html", "vue" },
	root_dir = vim.fs.root(0, { "biome.json", "biome.jsonc", "package.json", ".git" }),
}
