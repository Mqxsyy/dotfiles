pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// CPU, memory, GPU, temperatures, disk, network speed and the busiest
// processes. Only measured while some SystemView is on screen (`viewers`).
// Each source is one command, parsed by the function next to it.
Singleton {
    id: root

    property int viewers: 0
    readonly property bool active: viewers > 0
    property int interval: 2000
    property int historyLength: 40

    // 0..1 unless said otherwise. -1 = unknown.
    property real cpu: 0
    property real cpuTemp: -1        // °C
    property real memoryUsed: 0      // bytes
    property real memoryTotal: 0
    property real swapUsed: 0
    property real gpu: -1
    property real gpuTemp: -1
    property real gpuMemoryUsed: 0   // bytes
    property real gpuMemoryTotal: 0
    property real gpuPower: -1       // W
    property real diskUsed: 0        // bytes, of /
    property real diskTotal: 0
    property real download: 0        // bytes per second
    property real upload: 0

    // [{ pid, name, cpu, memory }], cpu as a share of the whole machine.
    property var processes: []

    // Recent cpu and memory (0..1), oldest first, for the graphs.
    property var cpuHistory: []
    property var memoryHistory: []

    property int cores: 1
    property var lastNet: null

    function push(history, value) {
        return [...history, value].slice(-historyLength);
    }

    // "4.2 GB", "512 MB" (powers of 1024, like btop)
    function formatBytes(bytes) {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let value = bytes;
        let unit = 0;
        while (value >= 1024 && unit < units.length - 1) {
            value /= 1024;
            unit++;
        }
        return `${value.toFixed(value < 100 && unit > 0 ? 1 : 0)} ${units[unit]}`;
    }

    function kill(pid) {
        Quickshell.execDetached(["kill", String(pid)]);
    }

    function refresh() {
        top.running = true;
        sensors.running = true;
        nvidia.running = true;
        disk.running = true;
        net.running = true;
    }

    Timer {
        running: root.active
        interval: root.interval
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        running: true
        command: ["nproc"]
        stdout: StdioCollector {
            onStreamFinished: root.cores = parseInt(text) || 1
        }
    }

    // Two frames half a second apart; the second has current usage, not
    // averages since boot.
    Process {
        id: top
        command: ["top", "-b", "-n", "2", "-d", "0.5", "-w", "200"]
        stdout: StdioCollector {
            onStreamFinished: root.parseTop(text)
        }
    }

    function parseTop(text) {
        const frame = text.slice(text.lastIndexOf("top -"));
        const lines = frame.split("\n");

        const idle = frame.match(/([\d.]+) id,/);
        if (idle) {
            cpu = 1 - parseFloat(idle[1]) / 100;
            cpuHistory = push(cpuHistory, cpu);
        }

        const mem = frame.match(/MiB Mem :\s+([\d.]+) total/);
        const avail = frame.match(/([\d.]+) avail Mem/);
        if (mem && avail) {
            memoryTotal = parseFloat(mem[1]) * 1048576;
            memoryUsed = memoryTotal - parseFloat(avail[1]) * 1048576;
            memoryHistory = push(memoryHistory, memoryUsed / memoryTotal);
        }

        const swap = frame.match(/MiB Swap:.*?([\d.]+) used/);
        if (swap)
            swapUsed = parseFloat(swap[1]) * 1048576;

        // PID USER PR NI VIRT RES SHR S %CPU %MEM TIME+ COMMAND
        const header = lines.findIndex(line => line.trim().startsWith("PID"));
        processes = lines.slice(header + 1)
            .map(line => line.trim().split(/\s+/))
            .filter(fields => fields.length >= 12)
            .slice(0, 8)
            .map(fields => ({
                pid: parseInt(fields[0]),
                name: fields.slice(11).join(" "),
                cpu: parseFloat(fields[8]) / 100 / cores,
                memory: parseFloat(fields[9]) / 100,
            }));
    }

    Process {
        id: sensors
        command: ["sensors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.parseSensors(text)
        }
    }

    // CPU package temperature from coretemp (Intel) or k10temp (AMD).
    function parseSensors(text) {
        let chips;
        try {
            chips = JSON.parse(text);
        } catch (e) {
            return;
        }
        for (const name in chips) {
            if (!name.startsWith("coretemp") && !name.startsWith("k10temp"))
                continue;
            const sensor = chips[name]["Package id 0"] ?? chips[name]["Tctl"];
            for (const key in sensor ?? {}) {
                if (key.endsWith("_input")) {
                    cpuTemp = sensor[key];
                    return;
                }
            }
        }
    }

    Process {
        id: nvidia
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,power.draw", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: root.parseNvidia(text)
        }
    }

    // "12, 48, 512, 8188, 7.31"
    function parseNvidia(text) {
        const fields = text.trim().split(",").map(field => parseFloat(field));
        if (fields.length < 5 || isNaN(fields[0]))
            return;
        gpu = fields[0] / 100;
        gpuTemp = fields[1];
        gpuMemoryUsed = fields[2] * 1048576;
        gpuMemoryTotal = fields[3] * 1048576;
        gpuPower = isNaN(fields[4]) ? -1 : fields[4];
    }

    Process {
        id: disk
        command: ["df", "-B1", "--output=size,used", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split("\n").pop().trim().split(/\s+/);
                root.diskTotal = parseFloat(fields[0]);
                root.diskUsed = parseFloat(fields[1]);
            }
        }
    }

    Process {
        id: net
        command: ["cat", "/proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: root.parseNet(text)
        }
    }

    // Bytes received/sent by every interface but loopback, compared with the
    // previous reading.
    function parseNet(text) {
        let received = 0;
        let sent = 0;
        for (const line of text.split("\n").slice(2)) {
            const [name, rest] = line.split(":");
            if (!rest || name.trim() === "lo")
                continue;
            const fields = rest.trim().split(/\s+/);
            received += parseFloat(fields[0]);
            sent += parseFloat(fields[8]);
        }
        const now = Date.now();
        if (lastNet) {
            const seconds = (now - lastNet.time) / 1000;
            download = Math.max(0, (received - lastNet.received) / seconds);
            upload = Math.max(0, (sent - lastNet.sent) / seconds);
        }
        lastNet = { time: now, received: received, sent: sent };
    }

    onActiveChanged: if (!active) lastNet = null
}
