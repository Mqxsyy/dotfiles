return {
    -- Normal
    bg_normal_a = "{{colors.surface.default.hex | set_lightness: 20.0 }}",
    bg_normal_b = "{{colors.surface.default.hex | set_lightness: 10.0 }}",

    fg_normal = "{{colors.on_surface.default.hex}}",

    -- Insert
    bg_insert_a = "{{colors.primary.default.hex | set_lightness: -10.0 }}",
    bg_insert_b = "{{colors.primary.default.hex }}",

    fg_insert = "{{colors.on_primary.default.hex}}",

    -- Visual
    bg_visual_a = "{{colors.secondary.default.hex | set_lightness: -10.0 }}",
    bg_visual_b = "{{colors.secondary.default.hex }}",

    fg_visual = "{{colors.on_secondary.default.hex}}",

    -- Command
    bg_command_a = "{{colors.tertiary.default.hex | set_lightness: -10.0 }}",
    bg_command_b = "{{colors.tertiary.default.hex }}",

    fg_command = "{{colors.on_tertiary.default.hex}}",

    -- Replace
    bg_replace_a = "{{colors.error.default.hex | set_lightness: -10.0 }}",
    bg_replace_b = "{{colors.error.default.hex }}",

    fg_replace = "{{colors.on_error.default.hex}}",

    -- Inactive
    bg_inactive_a = "{{colors.surface.default.hex | set_lightness: 5.0 }}",
    bg_inactive_b = "{{colors.surface.default.hex | set_lightness: 5.0 }}",

    fg_inactive = "{{colors.on_surface.default.hex | set_lightness: -10.0 }}",
}
