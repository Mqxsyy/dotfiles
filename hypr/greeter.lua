-- Hyprland for the login screen. greetd runs it as the `greeter` user
-- (greetd/config.toml); it only shows the quickshell greeter
-- (quickshell/greeter.qml), on the same monitors and keyboard as the session.

require("hardware") -- monitors, drivers, keyboard

-- Who logs in. The greeter reads their colors, settings and wallpaper, so
-- it runs with HOME set to their home (readable by `greeter` through an
-- ACL, see guides/greeter.md), and quickshell's own files go somewhere
-- `greeter` can write.
local user = "mqx"
local home = "/home/" .. user
local scratch = "/tmp/quickshell-greeter"

hl.config({
	animations = { enabled = false },
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
	},
	ecosystem = {
		no_update_news = true,
		no_donation_nag = true,
	},
})

-- When the greeter quits (logged in, or crashed), so does this Hyprland:
-- greetd then starts the session, or the greeter again.
hl.on("hyprland.start", function()
	hl.exec_cmd(
		"HOME=" .. home .. " GREETER_USER=" .. user
			.. " XDG_CACHE_HOME=" .. scratch .. "/cache"
			.. " XDG_STATE_HOME=" .. scratch .. "/state"
			.. " XDG_DATA_HOME=" .. scratch .. "/data"
			.. " qs -p " .. home .. "/dotfiles/quickshell/greeter.qml"
			.. "; hyprctl dispatch 'hl.dsp.exit()'"
	)
end)
