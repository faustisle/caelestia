pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.utils

// Monitor layout editor state. The saved layout is applied to Hyprland when the
// shell starts, and changes from Nexus are applied with hyprctl's monitor
// keyword (or Hyprland's Lua equivalent).
Singleton {
    id: root

    readonly property string statePath: `${Paths.state}/hypr-display.json`

    readonly property var current: Hypr.monitors.values.map(monitor => root.fromMonitor(monitor))
    property var monitors: []
    property var saved: ({})
    property bool stateLoaded: false
    property bool applied: false
    property bool dirty: false
    property string selectedName: ""

    readonly property var selected: root.monitors.find(monitor => monitor.name === root.selectedName) ?? null

    function fromMonitor(monitor: var): var {
        const ipc = monitor.lastIpcObject ?? {};
        const modes = ipc.availableModes ?? [];
        return {
            name: monitor.name,
            description: ipc.description ?? monitor.description ?? "",
            width: ipc.width ?? monitor.width,
            height: ipc.height ?? monitor.height,
            refreshRate: ipc.refreshRate ?? 60,
            x: ipc.x ?? monitor.x,
            y: ipc.y ?? monitor.y,
            scale: ipc.scale ?? monitor.scale ?? 1,
            transform: ipc.transform ?? 0,
            disabled: ipc.disabled ?? false,
            availableModes: modes,
            mode: root.currentMode(ipc, modes),
            focused: monitor.focused ?? false
        };
    }

    function currentMode(ipc: var, modes: var): string {
        let best = "";
        let bestDiff = Number.MAX_VALUE;
        for (const mode of modes) {
            const clean = String(mode).replace(/Hz$/, "");
            const parts = clean.split("@");
            const size = parts[0].split("x").map(Number);
            if (size[0] !== ipc.width || size[1] !== ipc.height)
                continue;

            const diff = Math.abs(Number(parts[1]) - ipc.refreshRate);
            if (diff < bestDiff) {
                best = clean;
                bestDiff = diff;
            }
        }

        return best !== "" ? best : `${ipc.width}x${ipc.height}@${Number(ipc.refreshRate).toFixed(2)}`;
    }

    function modeSize(mode: string): var {
        const size = String(mode).split("@")[0].split("x").map(Number);
        return {
            width: size[0],
            height: size[1]
        };
    }

    function logicalWidth(monitor: var): real {
        return (monitor.transform % 2 === 1 ? monitor.height : monitor.width) / Math.max(0.1, monitor.scale);
    }

    function logicalHeight(monitor: var): real {
        return (monitor.transform % 2 === 1 ? monitor.width : monitor.height) / Math.max(0.1, monitor.scale);
    }

    function refreshFromCurrent(): void {
        const next = root.current.map(monitor => Object.assign({}, monitor));
        if (next.length === 0)
            return;

        root.monitors = next;
        if (!next.some(monitor => monitor.name === root.selectedName))
            root.selectedName = next[0].name;
    }

    function enter(): void {
        if (!root.dirty)
            root.refreshFromCurrent();
    }

    function loadState(text: string): void {
        try {
            root.saved = JSON.parse(text) ?? {};
        } catch (e) {
            root.saved = {};
        }

        root.stateLoaded = true;
        root.maybeApply();
    }

    function maybeApply(): void {
        if (root.applied || !root.stateLoaded || root.current.length === 0)
            return;

        const commands = [];
        const next = root.current.map(monitor => {
            const stored = root.saved[monitor.name];
            if (!stored)
                return monitor;

            const merged = Object.assign({}, monitor, stored);
            commands.push(root.commandFor(merged));
            return merged;
        });

        if (commands.length > 0)
            Hypr.extras.batchMessage(commands);

        root.applied = true;
        root.dirty = false;
        root.monitors = next;
        if (!next.some(monitor => monitor.name === root.selectedName))
            root.selectedName = next[0].name;
    }

    function save(): void {
        const data = {};
        for (const monitor of root.monitors) {
            data[monitor.name] = {
                mode: monitor.mode,
                x: monitor.x,
                y: monitor.y,
                scale: monitor.scale,
                transform: monitor.transform,
                disabled: monitor.disabled
            };
        }

        const text = JSON.stringify(data, null, 4);
        Quickshell.execDetached(["sh", "-c", `mkdir -p "$(dirname "$1")" && printf '%s' "$2" > "$1"`, "sh", root.statePath, text]);
    }

    function apply(): void {
        if (root.monitors.length === 0)
            return;

        Hypr.extras.batchMessage(root.monitors.map(monitor => root.commandFor(monitor)));
        root.save();
        root.dirty = false;
        root.applied = true;
    }

    function reset(): void {
        root.dirty = false;
        root.refreshFromCurrent();
    }

    function select(name: string): void {
        root.selectedName = name;
    }

    function update(name: string, changes: var): void {
        root.monitors = root.monitors.map(monitor => monitor.name === name ? Object.assign({}, monitor, changes) : monitor);
        root.dirty = true;
    }

    function setMode(name: string, mode: string): void {
        const size = root.modeSize(mode);
        root.update(name, {
            mode,
            width: size.width,
            height: size.height
        });
    }

    function setScale(name: string, scale: real): void {
        root.update(name, {
            scale
        });
    }

    function setTransform(name: string, transform: int): void {
        root.update(name, {
            transform
        });
    }

    function setDisabled(name: string, disabled: bool): void {
        root.update(name, {
            disabled
        });
    }

    function setPosition(name: string, x: real, y: real): void {
        root.update(name, {
            x: Math.round(x),
            y: Math.round(y)
        });
    }

    function move(name: string, x: real, y: real): void {
        root.update(name, {
            x: Math.round(x / 10) * 10,
            y: Math.round(y / 10) * 10
        });
    }

    function commandFor(monitor: var): string {
        const quote = value => JSON.stringify(String(value));
        if (monitor.disabled) {
            return Hypr.usingLua ? `eval hl.monitor({ output = ${quote(monitor.name)}, disabled = true })` : `keyword monitor ${quote(`${monitor.name},disable`)}`;
        }

        const mode = monitor.mode || "preferred";
        const position = `${Math.round(monitor.x)}x${Math.round(monitor.y)}`;
        if (Hypr.usingLua) {
            return `eval hl.monitor({ output = ${quote(monitor.name)}, mode = ${quote(mode)}, position = ${quote(position)}, scale = ${monitor.scale}, transform = ${monitor.transform} })`;
        }

        return `keyword monitor ${quote(`${monitor.name},${mode},${position},${monitor.scale},${monitor.transform}`)}`;
    }

    onCurrentChanged: {
        if (!root.applied)
            root.maybeApply();
        else if (!root.dirty)
            root.refreshFromCurrent();
    }

    FileView {
        path: root.statePath
        onLoaded: root.loadState(text())
        onLoadFailed: {
            root.stateLoaded = true;
            root.applied = true;
            root.refreshFromCurrent();
        }
    }
}
