pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.utils

// Input settings Caelestia keeps in its own state and applies to Hyprland.
// Storing them here means the shell can restore them after Hyprland or the
// shell restarts without editing the user's Hyprland config.
Singleton {
    id: root

    readonly property string statePath: `${Paths.state}/hypr-input.json`

    property real sensitivity: 0
    property string accelProfile: "adaptive"
    property bool tapToClick: true
    property bool naturalScroll: false
    property string scrollMethod: "2fg"
    property bool tapAndDrag: true
    property bool disableWhileTyping: true

    property bool initialized: false
    property bool applying: false

    function option(key: string, fallback: var): var {
        const value = Hypr.options[key];
        if (value === undefined || value === null || value === "" || value === "[[EMPTY]]")
            return fallback;

        return value;
    }

    function booleanOption(key: string, fallback: bool): bool {
        const value = root.option(key, fallback);
        return value === true || value === 1 || value === "true" || value === "1";
    }

    function useCurrent(): void {
        if (root.initialized || Object.keys(Hypr.options).length === 0)
            return;

        root.sensitivity = Number(root.option("input:sensitivity", 0));
        root.accelProfile = String(root.option("input:accel_profile", "adaptive"));
        root.scrollMethod = String(root.option("input:scroll_method", "2fg"));
        root.tapToClick = root.booleanOption("input:touchpad:tap-to-click", true);
        root.naturalScroll = root.booleanOption("input:touchpad:natural_scroll", false);
        root.tapAndDrag = root.booleanOption("input:touchpad:tap-and-drag", true);
        root.disableWhileTyping = root.booleanOption("input:touchpad:disable_while_typing", true);
        root.initialized = true;
    }

    function loadState(text: string): void {
        try {
            const data = JSON.parse(text);
            root.sensitivity = Number(data.sensitivity ?? 0);
            root.accelProfile = String(data.accelProfile ?? "adaptive");
            root.tapToClick = data.tapToClick !== false;
            root.naturalScroll = data.naturalScroll === true;
            root.scrollMethod = String(data.scrollMethod ?? "2fg");
            root.tapAndDrag = data.tapAndDrag !== false;
            root.disableWhileTyping = data.disableWhileTyping !== false;
            root.initialized = true;
            root.apply();
        } catch (e) {
            root.useCurrent();
        }
    }

    function save(): void {
        const data = JSON.stringify({
            sensitivity: root.sensitivity,
            accelProfile: root.accelProfile,
            tapToClick: root.tapToClick,
            naturalScroll: root.naturalScroll,
            scrollMethod: root.scrollMethod,
            tapAndDrag: root.tapAndDrag,
            disableWhileTyping: root.disableWhileTyping
        }, null, 4);

        Quickshell.execDetached(["sh", "-c", `mkdir -p "$(dirname "$1")" && printf '%s' "$2" > "$1"`, "sh", root.statePath, data]);
    }

    function apply(): void {
        if (!root.initialized || root.applying)
            return;

        root.applying = true;

        if (Hypr.usingLua) {
            Hypr.extras.batchMessage([`eval hl.config({ input = { sensitivity = ${root.sensitivity}, accel_profile = "${root.accelProfile}", scroll_method = "${root.scrollMethod}", touchpad = { tap_to_click = ${root.tapToClick}, natural_scroll = ${root.naturalScroll}, tap_and_drag = ${root.tapAndDrag}, disable_while_typing = ${root.disableWhileTyping} } } })`]);
        } else {
            Hypr.extras.batchMessage([`keyword input:sensitivity ${root.sensitivity}`, `keyword input:accel_profile ${root.accelProfile}`, `keyword input:scroll_method ${root.scrollMethod}`, `keyword input:touchpad:tap-to-click ${root.tapToClick}`, `keyword input:touchpad:natural_scroll ${root.naturalScroll}`, `keyword input:touchpad:tap-and-drag ${root.tapAndDrag}`, `keyword input:touchpad:disable_while_typing ${root.disableWhileTyping}`]);
        }

        root.save();
        root.applying = false;
    }

    function applySoon(): void {
        applyTimer.restart();
    }

    function setSensitivity(value: real): void {
        root.sensitivity = value;
        root.applySoon();
    }

    function setAccelProfile(value: string): void {
        root.accelProfile = value;
        root.applySoon();
    }

    function setTapToClick(value: bool): void {
        root.tapToClick = value;
        root.applySoon();
    }

    function setNaturalScroll(value: bool): void {
        root.naturalScroll = value;
        root.applySoon();
    }

    function setScrollMethod(value: string): void {
        root.scrollMethod = value;
        root.applySoon();
    }

    function setTapAndDrag(value: bool): void {
        root.tapAndDrag = value;
        root.applySoon();
    }

    function setDisableWhileTyping(value: bool): void {
        root.disableWhileTyping = value;
        root.applySoon();
    }

    FileView {
        path: root.statePath
        onLoaded: root.loadState(text())
        onLoadFailed: root.useCurrent()
    }

    Connections {
        function onOptionsChanged() {
            root.useCurrent();
        }

        target: Hypr.extras
    }

    Timer {
        id: applyTimer

        interval: 150
        onTriggered: root.apply()
    }
}
