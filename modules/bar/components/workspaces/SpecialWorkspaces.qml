pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Caelestia
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

Item {
    id: root

    required property HyprlandMonitor monitor
    required property bool horizontal

    readonly property string activeSpecialName: monitor?.lastIpcObject.specialWorkspace?.name ?? ""
    readonly property var wsNames: {
        const allMonitors = !Config.bar.workspaces.perMonitor;
        return Hypr.workspaces.values.filter(w => w.name.startsWith("special:") && (allMonitors || w.monitor === root.monitor)).map(w => w.name);
    }
    readonly property int activeIdx: wsNames.indexOf(activeSpecialName)
    readonly property real maxViewOffset: Math.max(0, (horizontal ? view.contentWidth - width : view.contentHeight - height))

    readonly property Workspace activeWs: {
        CUtils.dependency(view.itemsDirty);
        return view.itemAtIndex(activeIdx) as Workspace;
    }
    readonly property real activeWidth: activeWs?.LazyListView.preferredWidth ?? 0
    readonly property real activeHeight: activeWs?.LazyListView.preferredHeight ?? 0

    function ensureVisible(animate = true): void {
        if (!activeWs)
            return;

        const start = horizontal ? activeWs.LazyListView.layoutX : activeWs.LazyListView.layoutY;
        const end = start + (horizontal ? activeWs.LazyListView.preferredWidth : activeWs.LazyListView.preferredHeight);
        const viewPos = horizontal ? view.x : view.y;
        const viewExtent = horizontal ? width : height;

        let target = viewPos;
        if (start < -target)
            target = -start;
        else if (end > -target + viewExtent)
            target = -(end - viewExtent);

        target = CUtils.clamp(target, -maxViewOffset, 0);
        if (target !== viewPos) {
            if (animate) {
                const type = viewOffsetAnim.type;
                viewOffsetAnim.type = Anim.DefaultSpatial;
                setViewOffset(target);
                viewOffsetAnim.type = type;
            } else {
                viewOffsetBehavior.enabled = false;
                setViewOffset(target);
                viewOffsetBehavior.enabled = true;
            }
        }
    }

    function setViewOffset(offset: real): void {
        if (horizontal)
            view.x = offset;
        else
            view.y = offset;
    }

    onActiveWsChanged: ensureVisible()
    onHeightChanged: ensureVisible(false)
    onWidthChanged: ensureVisible(false)
    Component.onCompleted: ensureVisible(false)
    onMaxViewOffsetChanged: ensureVisible()

    layer.enabled: true
    layer.effect: Mask {
        maskSource: mask
    }

    Connections {
        function onLayoutYChanged(): void {
            if (!root.horizontal)
                root.ensureVisible();
        }

        function onLayoutXChanged(): void {
            if (root.horizontal)
                root.ensureVisible();
        }

        function onPreferredHeightChanged(): void {
            if (!root.horizontal)
                root.ensureVisible();
        }

        function onPreferredWidthChanged(): void {
            if (root.horizontal)
                root.ensureVisible();
        }

        target: root.activeWs?.LazyListView ?? null
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: Tokens.rounding.full

            gradient: Gradient {
                orientation: root.horizontal ? Gradient.Horizontal : Gradient.Vertical

                GradientStop {
                    position: 0
                    color: Qt.rgba(0, 0, 0, 0)
                }
                GradientStop {
                    position: 0.2
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 0.8
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(0, 0, 0, 0)
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: root.horizontal ? undefined : parent.right
            anchors.top: parent.top
            anchors.bottom: root.horizontal ? parent.bottom : undefined

            radius: Tokens.rounding.full
            implicitWidth: root.horizontal ? parent.width / 2 : -1
            implicitHeight: root.horizontal ? -1 : parent.height / 2
            opacity: (root.horizontal ? view.x : view.y) < -Tokens.padding.extraSmall ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Rectangle {
            anchors.left: root.horizontal ? undefined : parent.left
            anchors.right: parent.right
            anchors.top: root.horizontal ? parent.top : undefined
            anchors.bottom: parent.bottom

            radius: Tokens.rounding.full
            implicitWidth: root.horizontal ? parent.width / 2 : -1
            implicitHeight: root.horizontal ? -1 : parent.height / 2
            opacity: (root.horizontal ? view.x : view.y) > -root.maxViewOffset + Tokens.padding.extraSmall ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    LazyListView {
        id: view

        horizontal: root.horizontal
        anchors.left: parent.left
        anchors.right: root.horizontal ? undefined : parent.right
        anchors.top: root.horizontal ? parent.top : undefined
        anchors.bottom: root.horizontal ? parent.bottom : undefined
        implicitWidth: root.horizontal ? contentWidth : -1
        implicitHeight: root.horizontal ? -1 : contentHeight

        cullDelegates: false
        spacing: Tokens.spacing.small
        removeDuration: Tokens.anim.durations.expressiveDefaultEffects

        onContentHeightChanged: root.ensureVisible()
        onContentWidthChanged: root.ensureVisible()

        model: ScriptModel {
            values: root.wsNames
        }

        delegate: Workspace {
            horizontal: root.horizontal
            activeWsId: 0
            activeWsName: root.activeSpecialName
            ws: 0
            wsName: modelData
            monitor: root.monitor
            offMonitorColour: Colours.palette.m3outline
            displayType: Config.bar.workspaces.specialDisplayType
            showWindows: Config.bar.workspaces.showWindowsOnSpecialWorkspaces
            iconRules: GlobalConfig.bar.workspaces.specialWorkspaceIcons
        }

        Behavior on y {
            id: viewOffsetBehavior

            enabled: !root.horizontal

            Anim {
                id: viewOffsetAnim

                type: Anim.FastEffects
            }
        }

        Behavior on x {
            enabled: root.horizontal

            Anim {
                type: viewOffsetAnim.type
                duration: viewOffsetAnim.duration
                easing: viewOffsetAnim.easing
            }
        }
    }

    Loader {
        asynchronous: true
        anchors.left: root.horizontal ? undefined : view.left
        anchors.right: root.horizontal ? undefined : view.right
        anchors.top: root.horizontal ? view.top : undefined
        anchors.bottom: root.horizontal ? view.bottom : undefined
        active: Config.bar.workspaces.activeIndicator

        sourceComponent: ActiveIndicator {
            horizontal: root.horizontal
            activeWs: root.activeWs
            mask: view
            color: Colours.palette.m3tertiary
            contentColour: Colours.palette.m3onTertiary
        }
    }

    MouseArea {
        property real startPos
        property real startViewPos
        property bool dragging

        anchors.fill: parent

        onPressed: event => {
            startPos = root.horizontal ? event.x : event.y;
            startViewPos = root.horizontal ? view.x : view.y;
            dragging = false;
        }

        onPositionChanged: event => {
            const pos = root.horizontal ? event.x : event.y;
            if (!dragging && Math.abs(pos - startPos) > drag.threshold)
                dragging = true;

            if (dragging)
                root.setViewOffset(CUtils.clamp(startViewPos + (pos - startPos), -root.maxViewOffset, 0));
        }

        onClicked: event => {
            if (dragging)
                return;

            const ws = view.itemAt(event.x - view.x, event.y - view.y) as Workspace;
            if (ws?.wsName)
                Hypr.toggleSpecial(Hypr.trimWsName(ws.wsName));
            else
                Hypr.toggleSpecial("special");
        }
    }
}
