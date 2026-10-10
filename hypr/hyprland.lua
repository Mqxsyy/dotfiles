require("hardware") -- monitors, drivers, keyboard

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

-- hl.workspace_rule({ workspace = 7, monitor = "DP-1" })
hl.workspace_rule({ workspace = 7, monitor = "HDMI-A-1" })

hl.workspace_rule({ workspace = 8, monitor = "eDP-1" })
hl.workspace_rule({ workspace = 9, monitor = "eDP-1" })
hl.workspace_rule({ workspace = 10, monitor = "eDP-1", default = true })

-----------------
--- Autostart ---
-----------------

-- Apps started at login, and the workspace each one opens on.
local startupApps = {
	{ command = "vesktop", class = "vesktop", workspace = "2" },
	{ command = "zen-browser", class = "zen", workspace = "1" },
	{ command = "obsidian", class = "md.obsidian.Obsidian", workspace = "special:magic" },
}

-- The workspace shown after logging in: just the wallpaper.
local startupWorkspace = 3

-- How long after login the apps open without being switched to.
local quietStartup = 60000 -- ms

-- Opening one of the apps switches to its workspace.
local appRules = {}
for _, app in ipairs(startupApps) do
	table.insert(appRules, hl.window_rule({
		name = app.class .. "-workspace",
		match = { class = app.class },
		workspace = app.workspace,
	}))
end

hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

	hl.exec_cmd("qs -n -d") -- at boot it also picks a new wallpaper (services/Lock.qml)

	-- At login the apps open on their workspaces in the background
	-- ("silent"), so none of them is what greets you; after `quietStartup`
	-- the usual rules are back.
	local quietRules = {}
	for _, rule in ipairs(appRules) do
		rule:set_enabled(false)
	end
	for _, app in ipairs(startupApps) do
		table.insert(quietRules, hl.window_rule({
			name = app.class .. "-workspace-quiet",
			match = { class = app.class },
			workspace = app.workspace .. " silent",
		}))
	end
	hl.timer(function()
		for _, rule in ipairs(quietRules) do
			rule:set_enabled(false)
		end
		for _, rule in ipairs(appRules) do
			rule:set_enabled(true)
		end
	end, { timeout = quietStartup, type = "oneshot" })

	hl.dispatch(hl.dsp.focus({ workspace = startupWorkspace }))

	for _, app in ipairs(startupApps) do
		hl.exec_cmd(app.command)
	end
end)


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
			size = 4,
			passes = 2,
			vibrancy = 0.2,
		},
	},

	animations = {
		enabled = true,
	},
})

hl.curve("Linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("Spring", { type = "spring", mass = 1, stiffness = 1500, dampening = 100 })

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

		-- At boot the session starts locked and the shell's lock screen takes
		-- over (greetd/config.toml); give it time before warning that no lock
		-- screen is there.
		lockdead_screen_delay = 5000,
	},
})


----------------
--- Keybinds ---
----------------

local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nautilus"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("qs ipc call launcher toggle"))
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("qs ipc call windows toggle"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("wayscriber --active"))

hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("qs ipc call lock lock"))

hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("qs ipc call popup toggle clipboard"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))

hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.move({ direction = "down" }))

-- Screen recording and screenshots through quickshell (Recorder.qml); the
-- record and screenshot panels show these keys as hints.
hl.bind(mainMod .. " + bracketleft", hl.dsp.exec_cmd("qs ipc call popup toggle record"))
hl.bind(mainMod .. " + bracketright", hl.dsp.exec_cmd("qs ipc call recorder stop"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("qs ipc call recorder screenshot region"))

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
	hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("qs ipc call brightness up"), opts)
	hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("qs ipc call brightness down"), opts)
end

do
	local opts = { locked = true }
	hl.bind("XF86AudioNext", hl.dsp.exec_cmd("qs ipc call media next"), opts)
	hl.bind("XF86AudioPause", hl.dsp.exec_cmd("qs ipc call media playPause"), opts)
	hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("qs ipc call media playPause"), opts)
	hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("qs ipc call media previous"), opts)
end

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

------------------
--- Layerrules ---
------------------

-- Frosted glass behind quickshell. Quickshell names its layers "qs-blur-*"
-- while "Glass" is on in its settings page. ignore_alpha keeps the blur to the
-- surfaces themselves, not their faint shadows.
hl.layer_rule({
	name = "quickshell-glass",
	match = { namespace = "qs-blur-.*" },
	blur = true,
	ignore_alpha = 0.15,
})
