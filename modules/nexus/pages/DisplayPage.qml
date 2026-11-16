pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import "display"

PageBase {
    id: root

    readonly property var sel: HyprDisplay.selected

    readonly property list<MenuItem> rotationItems: [
        MenuItem {
            text: Tr.trCtx("Normal", "display rotation")
            value: 0
        },
        MenuItem {
            text: Tr.trCtx("90°", "display rotation")
            value: 1
        },
        MenuItem {
            text: Tr.trCtx("180°", "display rotation")
            value: 2
        },
        MenuItem {
            text: Tr.trCtx("270°", "display rotation")
            value: 3
        }
    ]

    function rotationItem(value: int): MenuItem {
        return root.rotationItems.find(item => item.value === value) ?? root.rotationItems[0];
    }

    title: Tr.tr("Displays")
    isSubPage: false

    Component.onCompleted: HyprDisplay.enter()

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Arrangement")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: 280

            MonitorCanvas {
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            text: Tr.tr("Drag a display to move it, then press Apply.")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        SectionHeader {
            text: Tr.tr("Monitor")
            visible: root.sel !== null
        }

        ToggleRow {
            first: true
            visible: root.sel !== null
            text: Tr.tr("Enabled")
            checked: root.sel ? !root.sel.disabled : true
            onToggled: {
                if (root.sel)
                    HyprDisplay.setDisabled(root.sel.name, !checked);
            }
        }

        DialogSelectButton {
            id: modeSelect

            rootParent: root.flickable
            icon: "monitor"
            label: Tr.tr("Resolution")
            header: Tr.tr("Display mode")
            acceptLabel: Tr.tr("Select")
            model: root.sel ? root.sel.availableModes.map(mode => ({
                        id: String(mode).replace(/Hz$/, ""),
                        label: String(mode)
                    })) : []
            selectedItem: root.sel ? root.sel.mode : ""
            visible: root.sel !== null
            onAccepted: {
                if (root.sel && modeSelect.selectedItem)
                    HyprDisplay.setMode(root.sel.name, modeSelect.selectedItem);
            }
        }

        StepperRow {
            visible: root.sel !== null
            label: Tr.tr("Scale")
            subtext: Tr.tr("Logical size of the display")
            value: root.sel ? root.sel.scale : 1
            from: 0.5
            to: 3
            stepSize: 0.1
            onMoved: value => {
                if (root.sel)
                    HyprDisplay.setScale(root.sel.name, value);
            }
        }

        SelectRow {
            visible: root.sel !== null
            label: Tr.tr("Rotation")
            menuItems: root.rotationItems
            active: root.sel ? root.rotationItem(root.sel.transform) : root.rotationItems[0]
            onSelected: item => {
                if (root.sel)
                    HyprDisplay.setTransform(root.sel.name, item.value);
            }
        }

        StepperRow {
            visible: root.sel !== null
            label: Tr.tr("Horizontal position")
            value: root.sel ? root.sel.x : 0
            from: -10000
            to: 10000
            stepSize: 10
            onMoved: value => {
                if (root.sel)
                    HyprDisplay.setPosition(root.sel.name, value, root.sel.y);
            }
        }

        StepperRow {
            last: true
            visible: root.sel !== null
            label: Tr.tr("Vertical position")
            value: root.sel ? root.sel.y : 0
            from: -10000
            to: 10000
            stepSize: 10
            onMoved: value => {
                if (root.sel)
                    HyprDisplay.setPosition(root.sel.name, root.sel.x, value);
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Saved by Caelestia and reapplied when the shell starts.")
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
            }

            TextButton {
                text: Tr.tr("Reset")
                onClicked: HyprDisplay.reset()
            }

            TextButton {
                text: Tr.tr("Apply")
                type: TextButton.Filled
                enabled: HyprDisplay.dirty
                onClicked: HyprDisplay.apply()
            }
        }
    }
}
