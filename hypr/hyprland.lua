---------------
--- Monitors ---
----------------

hl.monitor({
	output = "DP-1",
	mode = "2560x1440@280",
	position = "0x0",
	scale = 1.0,
	bitdepth = 8, -- 10
	cm = "srgb", -- hdr
})

hl.monitor({
	output = "eDP-1",
	mode = "2560x1600@165",
	position = "2560x0",
	scale = 1.6,
})

for i = 1, 10 do
	hl.workspace_rule({
		workspace = i,
		monitor = i <= 7 and "DP-1" or "eDP-1",
		default = i == 1 or i == 10,
	})
end

hl.workspace_rule({ workspace = 1, monitor = "DP-1", default = true })
hl.workspace_rule({ workspace = 2, monitor = "DP-1" })
hl.workspace_rule({ workspace = 3, monitor = "DP-1" })
hl.workspace_rule({ workspace = 4, monitor = "DP-1" })
hl.workspace_rule({ workspace = 5, monitor = "DP-1" })
hl.workspace_rule({ workspace = 6, monitor = "DP-1" })
hl.workspace_rule({ workspace = 7, monitor = "DP-1" })

hl.workspace_rule({ workspace = 8, monitor = "eDP-1" })
hl.workspace_rule({ workspace = 9, monitor = "eDP-1" })
hl.workspace_rule({ workspace = 10, monitor = "eDP-1", default = true })

-----------------
--- Autostart ---
-----------------

hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("$HOME/dotfiles/scripts/randomizeWallpaper.sh")

	hl.exec_cmd("vesktop")
	hl.exec_cmd("zen-browser")
	hl.exec_cmd("obsidian")
end)

---------------------
--- Env Variables ---
---------------------

hl.env("GDK_SCALE", "1")
hl.env("CURSOR_SIZE", "24")
hl.env("YPRCURSOR_SIZE", "24")

hl.env("IBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

hl.env("OZ_DISABLE_RDD_SANDBOX", "1")

hl.env("AQ_DRM_DEVICES", "/dev/dri/card1")

hl.env("QT_QPA_PLATFORM", "wayland;xcb")

---------------
--- Visuals ---
---------------

hl.config({
	general = {
		gaps_in = 4,
		gaps_out = 0,

		border_size = 0,

		col = {
			active_border = { colors = { "rgba(ffb2b7ff)", "rgba(f6b6baff)" }, angle = 45 },
			inactive_border = "rgba(a38b8cff)",
		},

		resize_on_border = false,
		allow_tearing = true,
		layout = "dwindle",
	},

	decoration = {
		rounding = 0,

		active_opacity = 1.0,
		inactive_opacity = 1.0,

		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = "rgba(000000ff)",
		},

		blur = {
			enabled = true,
			size = 3,
			passes = 2,
			vibrancy = 0.2,
		},
	},

	animations = {
		enabled = true,
	},
})

hl.curve("Linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("Spring", { type = "spring", mass = 1, stiffness = 500, dampening = 100 })

hl.animation({ leaf = "global", enabled = true, speed = 1, spring = "Spring" })
hl.animation({ leaf = "windows", enabled = true, speed = 1, spring = "Spring", style = "popin" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1, spring = "Spring", style = "fade" })

hl.config({
	dwindle = {
		preserve_split = true,
	},
})

hl.config({
	xwayland = {
		-- use_nearest_neighbor = true
		force_zero_scaling = true,
	},
})

------------
--- Misc ---
------------

hl.config({
	misc = {
		force_default_wallpaper = -1,
		disable_hyprland_logo = true,
		disable_splash_rendering = true,

		font_family = "FiraCode Nerd Font",
		middle_click_paste = false,
	},
})

-------------
--- Input ---
-------------

hl.config({
	input = {
		kb_layout = "ee",
		kb_variant = "us",
		kb_options = "caps:escape",

		follow_mouse = 1,

		sensitivity = 0,
		accel_profile = "flat",

		touchpad = {
			natural_scroll = true,
			scroll_factor = 0.2,
		},
	},
})

----------------
--- Keybinds ---
----------------

local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nautilus"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("hyprlauncher"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("wayscriber --active"))

hl.bind(mainMod .. " + C", hl.dsp.window.close())

hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))

hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.move({ direction = "down" }))

hl.bind(mainMod .. " + bracketleft", hl.dsp.exec_cmd("~/dotfiles/scripts/gif-recorder/start.sh"))
hl.bind(mainMod .. " + bracketright", hl.dsp.exec_cmd("~/dotfiles/scripts/gif-recorder/stop.sh"))

for i = 1, 10 do
	local key = i % 10
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })

-- Multimedia & Laptop
do
	local opts = { locked = true, repeating = true }
	hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), opts)
	hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), opts)
	hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), opts)
	hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), opts)
	hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 10%+"), opts)
	hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), opts)
end

do
	local opts = { locked = true }
	hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), opts)
	hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), opts)
	hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), opts)
	hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), opts)
end

-- Extra
hl.bind("CTRL + SHIFT + S", hl.dsp.exec_cmd("grimblast --freeze copy area"))
hl.bind(mainMod .. " + KP_End", hl.dsp.exec_cmd("python $HOME/dotfiles/scripts/obs/obs-control.py")) -- request StartRecord
hl.bind(mainMod .. " + KP_Page_Down", hl.dsp.exec_cmd("python $HOME/dotfiles/scripts/obs/obs-control.py")) -- request StopRecord

-------------------
--- Windowrules ---
-------------------

hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

hl.window_rule({
	name = "zen-default-workspace",
	match = {
		class = "zen",
	},
	workspace = "1",
})

hl.window_rule({
	name = "vesktop-default-workspace",
	match = {
		class = "vesktop",
	},
	workspace = "2",
})

hl.window_rule({
	name = "obsidian-default-workspace",
	match = {
		class = "obsidian",
	},
	workspace = "special:magic",
})
