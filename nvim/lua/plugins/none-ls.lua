local function biome_config_exists()
    return vim.fn.glob ".biome.json" ~= ""
end

return {
    "nvimtools/none-ls.nvim",
    config = function()
        local null_ls = require "null-ls"

        local sources = {
            null_ls.builtins.formatting.stylua,
        }

        if biome_config_exists() then
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
            table.insert(sources, null_ls.builtins.diagnostics.eslint_d)
        end

        null_ls.setup {
            sources = sources,
        }

        vim.keymap.set("n", "<leader>ff", vim.lsp.buf.format, {})
    end,
}
