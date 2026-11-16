pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

Item {
    id: root

    readonly property real margin: Tokens.padding.large
    readonly property real minX: {
        const monitors = HyprDisplay.monitors;
        let value = 0;
        for (let i = 0; i < monitors.length; i++)
            value = i === 0 ? monitors[i].x : Math.min(value, monitors[i].x);
        return value;
    }
    readonly property real minY: {
        const monitors = HyprDisplay.monitors;
        let value = 0;
        for (let i = 0; i < monitors.length; i++)
            value = i === 0 ? monitors[i].y : Math.min(value, monitors[i].y);
        return value;
    }
    readonly property real spanX: {
        const monitors = HyprDisplay.monitors;
        let min = 0;
        let max = 1;
        for (let i = 0; i < monitors.length; i++) {
            const monitor = monitors[i];
            if (i === 0) {
                min = monitor.x;
                max = monitor.x + HyprDisplay.logicalWidth(monitor);
            } else {
                min = Math.min(min, monitor.x);
                max = Math.max(max, monitor.x + HyprDisplay.logicalWidth(monitor));
            }
        }
        return Math.max(1, max - min);
    }
    readonly property real spanY: {
        const monitors = HyprDisplay.monitors;
        let min = 0;
        let max = 1;
        for (let i = 0; i < monitors.length; i++) {
            const monitor = monitors[i];
            if (i === 0) {
                min = monitor.y;
                max = monitor.y + HyprDisplay.logicalHeight(monitor);
            } else {
                min = Math.min(min, monitor.y);
                max = Math.max(max, monitor.y + HyprDisplay.logicalHeight(monitor));
            }
        }
        return Math.max(1, max - min);
    }
    readonly property real scaleFactor: {
        const sx = (width - root.margin * 2) / root.spanX;
        const sy = (height - root.margin * 2) / root.spanY;
        return Math.max(0.02, Math.min(sx, sy));
    }
    readonly property real offsetX: root.margin - root.minX * root.scaleFactor
    readonly property real offsetY: root.margin - root.minY * root.scaleFactor

    property string dragName: ""
    property bool dragActive: false
    property real dragStartX: 0
    property real dragStartY: 0
    property real dragX: 0
    property real dragY: 0
    property real dragWidth: 0
    property real dragHeight: 0

    function tileX(monitor: var): real {
        return root.offsetX + monitor.x * root.scaleFactor;
    }

    function tileY(monitor: var): real {
        return root.offsetY + monitor.y * root.scaleFactor;
    }

    function tileWidth(monitor: var): real {
        return HyprDisplay.logicalWidth(monitor) * root.scaleFactor;
    }

    function tileHeight(monitor: var): real {
        return HyprDisplay.logicalHeight(monitor) * root.scaleFactor;
    }

    clip: true

    Repeater {
        model: HyprDisplay.monitors

        Item {
            id: tile

            required property var modelData
            required property int index

            readonly property bool selected: HyprDisplay.selectedName === tile.modelData.name
            readonly property bool dragging: root.dragActive && root.dragName === tile.modelData.name

            x: root.tileX(tile.modelData)
            y: root.tileY(tile.modelData)
            width: root.tileWidth(tile.modelData)
            height: root.tileHeight(tile.modelData)
            z: tile.selected ? 2 : 1
            opacity: tile.modelData.disabled ? 0.55 : 1

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.medium
                color: tile.selected ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh
                border.width: tile.selected ? 2 : 1
                border.color: tile.selected ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
            }

            Column {
                anchors.centerIn: parent
                width: parent.width - Tokens.padding.large
                spacing: 2

                StyledText {
                    width: parent.width
                    text: tile.modelData.name
                    color: tile.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    font: Tokens.font.label.medium
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                StyledText {
                    width: parent.width
                    text: `${tile.modelData.width}×${tile.modelData.height}`
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                StyledText {
                    width: parent.width
                    text: tile.modelData.disabled ? Tr.tr("Disabled") : `${tile.modelData.scale}×`
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: dragArea

                property real pressX: 0
                property real pressY: 0

                anchors.fill: parent
                cursorShape: tile.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                onPressed: mouse => {
                    dragArea.pressX = mouse.x;
                    dragArea.pressY = mouse.y;
                    root.dragName = tile.modelData.name;
                    root.dragStartX = tile.x;
                    root.dragStartY = tile.y;
                    root.dragWidth = tile.width;
                    root.dragHeight = tile.height;
                    root.dragX = 0;
                    root.dragY = 0;
                    root.dragActive = false;
                    HyprDisplay.select(tile.modelData.name);
                }
                onPositionChanged: mouse => {
                    if (!pressed)
                        return;

                    const dx = mouse.x - dragArea.pressX;
                    const dy = mouse.y - dragArea.pressY;
                    if (Math.abs(dx) + Math.abs(dy) < 5)
                        return;

                    root.dragActive = true;
                    root.dragX = dx;
                    root.dragY = dy;
                }
                onReleased: mouse => {
                    if (root.dragActive)
                        HyprDisplay.move(tile.modelData.name, tile.modelData.x + root.dragX / root.scaleFactor, tile.modelData.y + root.dragY / root.scaleFactor);

                    root.dragActive = false;
                    root.dragName = "";
                }
                onCanceled: {
                    root.dragActive = false;
                    root.dragName = "";
                }
            }
        }
    }

    StyledRect {
        visible: root.dragActive
        x: root.dragStartX + root.dragX
        y: root.dragStartY + root.dragY
        width: root.dragWidth
        height: root.dragHeight
        radius: Tokens.rounding.medium
        color: Qt.alpha(Colours.palette.m3primary, 0.2)
        border.width: 2
        border.color: Colours.palette.m3primary
        z: 10
    }

    StyledText {
        anchors.centerIn: parent
        visible: HyprDisplay.monitors.length === 0
        text: Tr.tr("No displays found")
        color: Colours.palette.m3outline
        font: Tokens.font.body.small
    }
}
