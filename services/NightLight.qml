pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.I18n
import qs.components.misc
import qs.utils

// Night light state and schedule. The colour transform is done by the bundled
// caelestia-nightlight Wayland helper; this singleton only decides which
// temperature should currently be applied.
Singleton {
    id: root

    readonly property string statePath: `${Paths.state}/nightlight.json`
    readonly property string localBinary: Quickshell.shellPath("build/lib/caelestia-nightlight")
    readonly property int neutralTemperature: 6500
    readonly property int minTemperature: 2500
    readonly property int maxTemperature: 6500
    readonly property bool supported: (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ?? "") !== ""

    property bool enabled: false
    property int temperature: 4000
    property bool useSchedule: true
    property int startMinutes: 21 * 60
    property int endMinutes: 7 * 60
    property int transitionMinutes: 15

    property real timeNow: root.minutesNow()
    property bool loaded: false
    property bool loading: false

    property string binary: "caelestia-nightlight"
    property bool resolved: false
    property bool helperAvailable: false
    property bool helperReady: false
    property bool blocked: false
    property string lastSent: ""

    readonly property real scheduleAmount: {
        if (!root.enabled)
            return 0;
        if (!root.useSchedule)
            return 1;
        return root.nightAmount(root.timeNow);
    }
    readonly property int currentTemperature: {
        if (!root.enabled)
            return root.neutralTemperature;
        if (!root.useSchedule)
            return root.temperature;
        return Math.round(root.neutralTemperature + (root.temperature - root.neutralTemperature) * root.scheduleAmount);
    }
    readonly property bool active: root.enabled && (!root.useSchedule || root.scheduleAmount > 0)
    readonly property string statusText: {
        if (!root.enabled)
            return Tr.tr("Off");

        if (!root.useSchedule)
            return Tr.tr("Always on at %1K").arg(root.temperature);

        if (root.scheduleAmount > 0)
            return Tr.tr("Active: %1K").arg(root.currentTemperature);

        return Tr.tr("Waiting for %1").arg(root.formatTime(root.startMinutes));
    }

    function clampTemperature(value: real): int {
        const clamped = Math.max(root.minTemperature, Math.min(root.maxTemperature, value));
        return Math.round(clamped / 100) * 100;
    }

    function clampMinutes(value: real): int {
        const total = Math.round(value) % 1440;
        return total < 0 ? total + 1440 : total;
    }

    function minutesNow(): real {
        const date = new Date();
        return date.getHours() * 60 + date.getMinutes() + date.getSeconds() / 60;
    }

    function formatTime(minutes: real): string {
        const total = ((Math.round(minutes) % 1440) + 1440) % 1440;
        const hours = Math.floor(total / 60);
        const mins = total % 60;
        return `${hours < 10 ? "0" : ""}${hours}:${mins < 10 ? "0" : ""}${mins}`;
    }

    function intervalMinutes(): int {
        const length = (root.endMinutes - root.startMinutes + 1440) % 1440;
        return length === 0 ? 1440 : length;
    }

    function within(time: real, start: real, length: real): bool {
        if (length <= 0)
            return false;
        return ((time - start + 1440) % 1440) < length;
    }

    function progress(time: real, start: real, length: real): real {
        if (length <= 0)
            return 1;
        return Math.max(0, Math.min(1, ((time - start + 1440) % 1440) / length));
    }

    function nightAmount(time: real): real {
        if (!root.enabled)
            return 0;
        if (!root.useSchedule)
            return 1;

        const transition = Math.max(0, root.transitionMinutes);
        const start = root.startMinutes;
        const end = root.endMinutes;

        if (transition > 0 && root.within(time, end, transition))
            return 1 - root.progress(time, end, transition);

        if (root.within(time, start, root.intervalMinutes()))
            return 1;

        if (transition > 0) {
            const enterStart = (start - transition + 1440) % 1440;
            if (root.within(time, enterStart, transition))
                return root.progress(time, enterStart, transition);
        }

        return 0;
    }

    function refresh(): void {
        root.timeNow = root.minutesNow();
    }

    function queueSave(): void {
        if (root.loaded && !root.loading)
            saveTimer.restart();
    }

    function save(): void {
        if (!root.loaded || root.loading)
            return;

        const data = JSON.stringify({
            enabled: root.enabled,
            temperature: root.temperature,
            useSchedule: root.useSchedule,
            startMinutes: root.startMinutes,
            endMinutes: root.endMinutes,
            transitionMinutes: root.transitionMinutes
        }, null, 4);

        Quickshell.execDetached(["sh", "-c", `mkdir -p "$(dirname "$1")" && printf '%s' "$2" > "$1"`, "sh", root.statePath, data]);
    }

    function loadState(text: string): void {
        root.loading = true;
        try {
            const data = JSON.parse(text);
            root.enabled = data.enabled === true;
            root.temperature = root.clampTemperature(Number(data.temperature ?? 4000));
            root.useSchedule = data.useSchedule !== false;
            root.startMinutes = root.clampMinutes(Number(data.startMinutes ?? 21 * 60));
            root.endMinutes = root.clampMinutes(Number(data.endMinutes ?? 7 * 60));
            root.transitionMinutes = Math.max(0, Math.min(60, Math.round(Number(data.transitionMinutes ?? 15))));
        } catch (e) {
        }
        root.loading = false;
        root.loaded = true;
        root.refresh();
    }

    function apply(): void {
        if (!root.helperReady)
            return;

        const identity = !root.enabled || root.currentTemperature >= root.neutralTemperature;
        const command = identity ? "identity" : `temperature ${root.currentTemperature}`;
        if (command === root.lastSent)
            return;

        helper.write(`${command}\n`);
        root.lastSent = command;
    }

    onEnabledChanged: {
        root.blocked = false;
        if (root.enabled && !root.resolved && !resolveProc.running)
            resolveProc.running = true;
        root.refresh();
        root.queueSave();
    }
    onTemperatureChanged: {
        root.queueSave();
    }
    onUseScheduleChanged: {
        root.refresh();
        root.queueSave();
    }
    onStartMinutesChanged: {
        root.refresh();
        root.queueSave();
    }
    onEndMinutesChanged: {
        root.refresh();
        root.queueSave();
    }
    onTransitionMinutesChanged: {
        root.refresh();
        root.queueSave();
    }
    onCurrentTemperatureChanged: root.apply()
    onHelperReadyChanged: {
        if (root.helperReady) {
            root.lastSent = "";
            root.apply();
        }
    }
    onTimeNowChanged: root.apply()

    IpcHandler {
        function toggle(): void {
            root.enabled = !root.enabled;
        }

        function enable(): void {
            root.enabled = true;
        }

        function disable(): void {
            root.enabled = false;
        }

        function isEnabled(): bool {
            return root.enabled;
        }

        function isActive(): bool {
            return root.active;
        }

        function getTemperature(): int {
            return root.currentTemperature;
        }

        function setTemperature(value: int): void {
            root.temperature = root.clampTemperature(value);
        }

        function setUseSchedule(value: bool): void {
            root.useSchedule = value;
        }

        function setSchedule(start: int, end: int): void {
            root.startMinutes = root.clampMinutes(start);
            root.endMinutes = root.clampMinutes(end);
        }

        function setTransition(value: int): void {
            root.transitionMinutes = Math.max(0, Math.min(60, Math.round(value)));
        }

        target: "nightLight"
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "nightLight"
        description: "Toggle night light"
        onPressed: root.enabled = !root.enabled
    }

    FileView {
        path: root.statePath
        onLoaded: root.loadState(text())
        onLoadFailed: {
            root.loaded = true;
            root.refresh();
        }
    }

    Process {
        id: resolveProc

        command: ["sh", "-c", `if [ -x "$1" ]; then printf '%s' "$1"; else command -v caelestia-nightlight; fi`, "sh", root.localBinary]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                root.binary = path.length > 0 ? path : "caelestia-nightlight";
                root.helperAvailable = path.length > 0;
                root.resolved = true;
            }
        }
        onExited: root.resolved = true
    }

    Process {
        id: helper

        running: root.resolved && root.helperAvailable && root.supported && !root.blocked && root.enabled
        command: [root.binary]
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => {
                if (line.trim() === "ready")
                    root.helperReady = true;
            }
        }
        stderr: SplitParser {
            onRead: line => {
                if (line.includes("another CTM manager"))
                    root.blocked = true;
                console.warn("nightlight:", line);
            }
        }
        onExited: {
            root.helperReady = false;
            root.lastSent = "";
            if (root.helperAvailable && root.supported && !root.blocked && root.enabled)
                restartTimer.start();
        }
    }

    Timer {
        id: restartTimer

        interval: 2000
        onTriggered: {
            if (root.helperAvailable && root.supported && !root.blocked && root.enabled)
                helper.running = true;
        }
    }

    Timer {
        id: saveTimer

        interval: 250
        onTriggered: root.save()
    }

    Timer {
        interval: 60000
        running: root.enabled && root.useSchedule
        repeat: true
        onTriggered: root.refresh()
    }
}
