pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

// Night light: warmer screen colors, through a Hyprland screen shader
// (decoration.screen_shader) that tints everything toward `temperature`.
// Screenshots and recordings get the tint too while it's on.
// On/off from Quick settings or "> night"; with `automatic` it turns on at
// `from` and off at `to` (hours), and a manual toggle lasts until the next one.
// All of it is set on the settings page.
//   qs ipc call nightlight toggle
Singleton {
    id: root

    readonly property bool on: Settings.nightLight
    readonly property int temperature: Settings.nightLightTemperature // kelvin; 6500 = no change
    readonly property bool automatic: Settings.nightLightAuto
    readonly property int from: Settings.nightLightFrom
    readonly property int to: Settings.nightLightTo

    // Inside the from-to hours (which can wrap past midnight).
    readonly property bool nightTime: {
        const hour = clock.hours;
        return from > to ? hour >= from || hour < to : hour >= from && hour < to;
    }

    // One file per temperature: Hyprland only reloads the shader when the path changes.
    readonly property string shaderPath: Quickshell.env("HOME") + `/.local/state/quickshell/night-light-${temperature}.frag`

    function toggle() {
        Settings.set("nightLight", !on);
    }

    function followSchedule() {
        if (automatic)
            Settings.set("nightLight", nightTime);
    }

    // Red, green and blue of white light at `kelvin`, 0..1 (Tanner Helland's
    // fit of the blackbody colors).
    function whitePoint(kelvin) {
        const t = kelvin / 100;
        const red = t <= 66 ? 255 : 329.698727446 * Math.pow(t - 60, -0.1332047592);
        const green = t <= 66 ? 99.4708025861 * Math.log(t) - 161.1195681661 : 288.1221695283 * Math.pow(t - 60, -0.0755148492);
        const blue = t >= 66 ? 255 : t <= 19 ? 0 : 138.5177312231 * Math.log(t - 10) - 305.0447927307;
        return [red, green, blue].map(value => Math.max(0, Math.min(255, value)) / 255);
    }

    function shader(kelvin) {
        const tint = whitePoint(kelvin).map(value => value.toFixed(3)).join(", ");
        return `#version 300 es
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 color = texture(tex, v_texcoord);
    fragColor = vec4(color.rgb * vec3(${tint}), color.a);
}
`;
    }

    function apply() {
        if (on)
            shaderFile.setText(shader(temperature));
        const path = on ? shaderPath : "";
        Quickshell.execDetached(["hyprctl", "eval", `hl.config({ decoration = { screen_shader = "${path}" } })`]);
    }

    onOnChanged: apply()
    onTemperatureChanged: if (on) apply()
    onNightTimeChanged: followSchedule()
    onAutomaticChanged: followSchedule()

    Component.onCompleted: {
        followSchedule();
        apply();
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    FileView {
        id: shaderFile
        path: root.shaderPath
        preload: false // only written
        blockWrites: true
    }

    // Reloading the Hyprland config resets the shader.
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "configreloaded")
                root.apply();
        }
    }

    IpcHandler {
        target: "nightlight"

        function toggle(): void {
            root.toggle();
        }
    }
}
