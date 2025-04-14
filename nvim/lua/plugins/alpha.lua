return {
	"goolord/alpha-nvim",
	config = function()
		-- NOTE: not being able to reopen alpha after intial open is a known plugin problem not related to this config.
		-- Pixel art to ascii https://dom111.github.io/image-to-ansi/

		local alpha = require "alpha"
		local dashboard = require "alpha.themes.dashboard"
		require "alpha.term"

		alpha.setup {
			layout = {
				{ type = "padding", val = 4 },
				{
					type = "terminal",
					command = "lua "
						.. debug.getinfo(1, "S").source:match "@?(.*/)"
						.. "animations/animationPlayer.lua",
					width = 48,
					height = 24,
					opts = {
						redraw = true,
					},
				},
				{ type = "padding", val = 4 },
				{
					type = "group",
					val = {
						dashboard.button("r", "  > Recent", ":Telescope oldfiles<CR>"),
						dashboard.button("s", "  > Settings", ":e $MYVIMRC | :cd %:p:h<CR>"),
						dashboard.button("q", "󰅘  > Quit NVIM", ":qa<CR>"),
					},
					opts = {
						spacing = 1,
					},
				},
			},
		}
	end,
}
