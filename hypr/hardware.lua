-- This machine's monitors, drivers and keyboard. Shared by the session
-- (hyprland.lua) and the login screen (greeter.lua), so both look and type
-- the same.

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

hl.monitor({
	output = "HDMI-A-1",
	mode = "1920x1080@60",
	position = "-1920x0",
	scale = 1,
})

---------------------
--- Env Variables ---
---------------------

hl.env("GDK_SCALE", "1")
hl.env("CURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

hl.env("MOZ_DISABLE_RDD_SANDBOX", "1")

hl.env("AQ_DRM_DEVICES", "/dev/dri/card1")

hl.env("QT_QPA_PLATFORM", "wayland;xcb")

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
			disable_while_typing = false,
		},
	},
})
