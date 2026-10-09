.pragma library

// Nerd Font (Material Design) glyphs used across the shell.
// Draw them with font.family: Theme.iconFont.

const play = "󰐊";
const pause = "󰏤";
const next = "󰒭";
const previous = "󰒮";
const music = "󰎇";

const volumeOff = "󰖁";
// Volume glyph from the lowest level it applies at. The no-waves speaker is
// kept for nearly silent, so everyday volumes (20-50%) still show waves.
const volume = [
    { from: 0, glyph: "󰕿" },
    { from: 0.1, glyph: "󰖀" },
    { from: 0.45, glyph: "󰕾" },
];

const brightness = ["󰃞", "󰃟", "󰃠"];          // low .. high

const wifiOff = "󰤮";
const wifi = ["󰤟", "󰤢", "󰤥", "󰤨"];           // weak .. strong
const ethernet = "󰈀";

const batteryCharging = "󰂄";
const battery = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]; // 10% .. 100%
const batteryAlert = "󰂃";

const mic = "󰍬";
const micOff = "󰍭";
const speaker = "󰓃";
const app = "󰀻";

const lock = "󰌾";
const close = "󰅖";
const shuffle = "󰒝";
const repeat = "󰑖";
const repeatOne = "󰑘";
const search = "󰍉";
const image = "󰋩";

const power = "󰐥";
const restart = "󰜉";
const suspend = "󰒲";
const logout = "󰍃";

const cpu = "󰻠";
const memory = "󰍛";
const gpu = "󰢮";
const disk = "󰋊";
const download = "󰇚";
const upload = "󰕒";

const screenshot = "󰹑";
const record = "󰻃";        // dot in a ring
const stop = "󰓛";
const monitor = "󰍹";
const region = "󰩬";
const colorPicker = "󰈊";
const folder = "󰉋";
const clipboard = "󰅌";
const trash = "󰆴";

const bell = "󰂚";
const bellOff = "󰂛";
const moon = "󰖔";
const sun = "󰖨";
const nightLight = "󰖛";
const settings = "󰒓";
const refresh = "󰑐";
const chevronLeft = "󰅁";
const chevronRight = "󰅂";

// The volume glyph for a 0..1 level.
function volumeLevel(fraction) {
    let glyph = volume[0].glyph;
    for (const step of volume) {
        if (fraction >= step.from)
            glyph = step.glyph;
    }
    return glyph;
}

// Pick the glyph for a 0..1 level from a low-to-high list.
function level(glyphs, fraction) {
    const index = Math.floor(fraction * glyphs.length);
    return glyphs[Math.max(0, Math.min(glyphs.length - 1, index))];
}
