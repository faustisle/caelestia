pragma ComponentBehavior: Bound

import "components"
import "components/workspaces"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.bar.popouts as BarPopouts

GridLayout {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property bool fullscreen
    required property bool horizontal
    readonly property int axisPadding: Tokens.padding.large
    property bool autoCompactTray: false
    property bool autoCompactSysmon: false

    function closeTray(): void {
        if (!Config.bar.tray.compact)
            return;

        for (let i = 0; i < repeater.count; i++) {
            const tray = (repeater.itemAt(i) as EntryWrapper)?.item as Tray;
            if (tray)
                tray.expanded = false;
        }
    }

    function axisCenterOf(item: Item): real {
        const c = item.mapToItem(root, item.implicitWidth / 2, item.implicitHeight / 2);
        return horizontal ? c.x : c.y;
    }

    function entryAt(pos: real): string {
        const ch = (horizontal ? childAt(pos, height / 2) : childAt(width / 2, pos)) as EntryWrapper;
        return ch?.entryId ?? "";
    }

    function checkPopout(pos: real): void {
        const ch = (horizontal ? childAt(pos, height / 2) : childAt(width / 2, pos)) as EntryWrapper;

        if (ch?.entryId !== "tray")
            closeTray();

        if (!ch) {
            popouts.hasCurrent = false;
            return;
        }

        const id = ch.entryId;
        const start = horizontal ? ch.x : ch.y;

        if (id === "statusIcons" && Config.bar.popouts.statusIcons) {
            const items = (ch.item as StatusIcons).items;
            const icon = horizontal ? items.childAt(mapToItem(items, pos, 0).x, items.height / 2) : items.childAt(items.width / 2, mapToItem(items, 0, pos).y);
            if (icon) {
                popouts.currentName = icon.name;
                popouts.currentCenter = Qt.binding(() => axisCenterOf(icon));
                popouts.hasCurrent = true;
            }
        } else if (id === "tray" && Config.bar.popouts.tray) {
            const tray = ch.item as Tray;
            if (!Config.bar.tray.compact || (tray.expanded && !tray.expandIcon.contains(horizontal ? mapToItem(tray.expandIcon, pos, tray.implicitHeight / 2) : mapToItem(tray.expandIcon, tray.implicitWidth / 2, pos)))) {
                const index = Math.floor(((pos - start - tray.padding * 2 + tray.spacing) / (horizontal ? tray.layout.implicitWidth : tray.layout.implicitHeight)) * tray.items.count);
                const trayItem = tray.items.itemAt(index);
                if (trayItem) {
                    popouts.currentName = `traymenu${index}`;
                    popouts.currentCenter = Qt.binding(() => axisCenterOf(trayItem));
                    popouts.hasCurrent = true;
                } else {
                    popouts.hasCurrent = false;
                }
            } else {
                popouts.hasCurrent = false;
                tray.expanded = true;
            }
        } else if (id === "power" && horizontal) {
            popouts.hasCurrent = false;
        }
    }

    // Clock and system monitor popouts are click-only so hovering the bar for
    // scrolling volume/brightness does not keep opening them.
    function togglePopout(pos: real): void {
        const ch = (horizontal ? childAt(pos, height / 2) : childAt(width / 2, pos)) as EntryWrapper;
        if (!ch)
            return;

        let name = "";
        if (ch.entryId === "clock" && Config.bar.popouts.clock)
            name = "calendar";
        else if (ch.entryId === "sysmon" && Config.bar.popouts.sysMonitor)
            name = "sysMonitor";
        else
            return;

        if (popouts.hasCurrent && popouts.currentName === name) {
            popouts.hasCurrent = false;
            return;
        }

        popouts.currentName = name;
        popouts.currentCenter = Qt.binding(() => axisCenterOf(ch));
        popouts.hasCurrent = true;
    }

    function handleWheel(pos: real, angleDelta: point): void {
        const ch = (horizontal ? childAt(pos, height / 2) : childAt(width / 2, pos)) as EntryWrapper;
        if (ch?.entryId === "workspaces" && Config.bar.scrollActions.workspaces) {
            // Workspace scroll
            const mon = Hypr.monitorFor(screen);
            const specialWs = mon?.lastIpcObject.specialWorkspace.name;
            if (specialWs?.length > 0)
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.workspace.toggle_special("${specialWs.slice(8)}")` : `togglespecialworkspace ${specialWs.slice(8)}`);
            else if (angleDelta.y < 0 || mon.activeWorkspace?.id > 1)
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ workspace = "r${angleDelta.y > 0 ? "-" : "+"}1" })` : `workspace r${angleDelta.y > 0 ? "-" : "+"}1`);
        } else if (pos < (horizontal ? screen.width : screen.height) / 2 && Config.bar.scrollActions.volume) {
            // Volume scroll on top/left half
            if (angleDelta.y > 0)
                Audio.incrementVolume();
            else if (angleDelta.y < 0)
                Audio.decrementVolume();
        } else if (Config.bar.scrollActions.brightness) {
            // Brightness scroll on bottom/right half
            const monitor = Brightness.getMonitorForScreen(screen);
            if (angleDelta.y > 0)
                monitor.setBrightness(monitor.brightness + GlobalConfig.services.brightnessIncrement);
            else if (angleDelta.y < 0)
                monitor.setBrightness(monitor.brightness - GlobalConfig.services.brightnessIncrement);
        }
    }

    function entryItem(id: string): Item {
        for (let i = 0; i < repeater.count; i++) {
            const entry = repeater.itemAt(i) as EntryWrapper;
            if (entry?.entryId === id)
                return entry.item;
        }
        return null;
    }

    function refreshAutoCompact(): void {
        if (!GlobalConfig.bar.adaptiveCompact) {
            autoCompactTray = false;
            autoCompactSysmon = false;
            return;
        }

        const available = horizontal ? width : height;
        if (available <= 0)
            return;

        const tray = entryItem("tray") as Tray;
        const sysmon = entryItem("sysmon") as SysMonitor;

        let traySaving = 0;
        if (tray && !GlobalConfig.bar.tray.compact)
            traySaving = Math.max(0, tray.expandedLength - tray.compactLength);

        let sysmonSaving = 0;
        if (sysmon && !GlobalConfig.bar.sysMonitor.compact && sysmon.compactLength > 0)
            sysmonSaving = Math.max(0, sysmon.expandedLength - sysmon.compactLength);

        let expanded = horizontal ? implicitWidth : implicitHeight;
        if (autoCompactTray)
            expanded += traySaving;
        if (autoCompactSysmon)
            expanded += sysmonSaving;

        if (expanded < available - Tokens.spacing.large) {
            autoCompactTray = false;
            autoCompactSysmon = false;
            return;
        }

        if (expanded <= available)
            return;

        const candidates = [];
        if (sysmonSaving > 0)
            candidates.push({
                sysmon: true,
                saving: sysmonSaving
            });
        if (traySaving > 0)
            candidates.push({
                sysmon: false,
                saving: traySaving
            });
        candidates.sort((a, b) => b.saving - a.saving);

        let overflow = expanded - available;
        autoCompactTray = false;
        autoCompactSysmon = false;

        for (const candidate of candidates) {
            if (overflow <= 0)
                break;
            if (candidate.sysmon)
                autoCompactSysmon = true;
            else
                autoCompactTray = true;
            overflow -= candidate.saving;
        }
    }

    onImplicitWidthChanged: compactTimer.restart()
    onImplicitHeightChanged: compactTimer.restart()
    onWidthChanged: compactTimer.restart()
    onHeightChanged: compactTimer.restart()
    Component.onCompleted: compactTimer.restart()

    columns: horizontal ? -1 : 1
    rowSpacing: Tokens.spacing.medium
    columnSpacing: Tokens.spacing.medium

    Timer {
        id: compactTimer

        interval: 80
        onTriggered: root.refreshAutoCompact()
    }

    Connections {
        function onAdaptiveCompactChanged(): void {
            compactTimer.restart();
        }

        target: GlobalConfig.bar
    }

    Repeater {
        id: repeater

        model: ScriptModel {
            values: root.Config.bar.entries.values.filter(e => e.enabled)
        }

        DelegateChooser {
            role: "id"

            DelegateChoice {
                roleValue: "spacer"
                delegate: EntryWrapper {
                    Layout.fillHeight: !root.horizontal
                    Layout.fillWidth: root.horizontal
                }
            }
            DelegateChoice {
                roleValue: "logo"
                delegate: EntryWrapper {
                    OsIcon {
                        objectName: "taskbarLogo"
                    }
                }
            }
            DelegateChoice {
                roleValue: "workspaces"
                delegate: EntryWrapper {
                    Workspaces {
                        objectName: "taskbarWorkspaces"
                        screen: root.screen
                        fullscreen: root.fullscreen
                        horizontal: root.horizontal
                    }
                }
            }
            DelegateChoice {
                roleValue: "tray"
                delegate: EntryWrapper {
                    Tray {
                        objectName: "taskbarTray"
                        horizontal: root.horizontal
                        autoCompact: root.autoCompactTray
                    }
                }
            }
            DelegateChoice {
                roleValue: "sysmon"
                delegate: EntryWrapper {
                    SysMonitor {
                        objectName: "taskbarSysMonitor"
                        horizontal: root.horizontal
                        compact: GlobalConfig.bar.sysMonitor.compact || root.autoCompactSysmon
                    }
                }
            }
            DelegateChoice {
                roleValue: "clock"
                delegate: EntryWrapper {
                    Clock {
                        objectName: "taskbarClock"
                        horizontal: root.horizontal
                    }
                }
            }
            DelegateChoice {
                roleValue: "statusIcons"
                delegate: EntryWrapper {
                    StatusIcons {
                        objectName: "taskbarStatusIcons"
                        horizontal: root.horizontal
                    }
                }
            }
            DelegateChoice {
                roleValue: "power"
                delegate: EntryWrapper {
                    Power {
                        objectName: "taskbarPowerButton"
                        screenState: root.screenState
                    }
                }
            }
        }
    }

    component EntryWrapper: Item {
        required property var modelData
        required property int index
        default property Item item
        readonly property string entryId: modelData.id

        Layout.topMargin: !root.horizontal && index === 0 ? root.axisPadding : 0
        Layout.bottomMargin: !root.horizontal && index === repeater.count - 1 ? root.axisPadding : 0
        Layout.leftMargin: root.horizontal && index === 0 ? root.axisPadding : 0
        Layout.rightMargin: root.horizontal && index === repeater.count - 1 ? root.axisPadding : 0
        Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignHCenter

        implicitWidth: item?.implicitWidth ?? 0
        implicitHeight: item?.implicitHeight ?? 0

        children: item
    }
}
