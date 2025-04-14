local keymap = require "keymap"

return {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
        {
            keymap.flash.jump.key,
            mode = keymap.flash.jump.mode,
            function()
                require("flash").jump()
            end,
        },
        {
            keymap.flash.treesitter.key,
            mode = keymap.flash.treesitter.mode,
            function()
                require("flash").treesitter()
            end,
        },
        {
            keymap.flash.remote.key,
            mode = keymap.flash.remote.mode,
            function()
                require("flash").remote()
            end,
        },
    },
}
