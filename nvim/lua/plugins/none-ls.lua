local findPrettierConfig = require "utils.findPrettierConfig"

return {
    "nvimtools/none-ls.nvim",
    config = function()
        local null_ls = require "null-ls"

        local sources = {
            null_ls.builtins.formatting.stylua,
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
