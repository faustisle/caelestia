pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

LazyLoader {
    id: loader

    property var entry: null

    function open(item): void {
        loader.entry = item;
        activeAsync = true;
    }

    FloatingWindow {
        id: win

        readonly property string newName: field.text.trim()
        readonly property bool valid: loader.entry !== null && newName !== "" && newName !== loader.entry.name && !newName.includes("/")

        function commit(): void {
            if (!valid)
                return;

            Desktop.renameEntry(loader.entry, newName);
            visible = false;
        }

        visible: true
        implicitWidth: 380
        implicitHeight: 220
        color: "transparent"
        surfaceFormat.opaque: false
        title: Tr.tr("Rename")

        onVisibleChanged: {
            if (!visible)
                loader.activeAsync = false;
        }

        Component.onCompleted: Qt.callLater(() => {
            field.forceActiveFocus();
            field.select(0, field.length);
        })

        StyledRect {
            anchors.fill: parent
            radius: Tokens.rounding.large
            color: Colours.palette.m3surfaceContainerLow
            border.width: 1
            border.color: Colours.palette.m3primary

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.large

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("Rename")
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.title.medium
                }

                StyledTextField {
                    id: field

                    Layout.fillWidth: true
                    text: loader.entry?.name ?? ""
                    placeholderText: Tr.tr("Name")
                    onAccepted: win.commit()
                }

                Item {
                    Layout.fillHeight: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: Tr.tr("Cancel")
                        onClicked: win.visible = false
                    }

                    TextButton {
                        text: Tr.tr("Rename")
                        type: TextButton.Filled
                        enabled: win.valid
                        onClicked: win.commit()
                    }
                }
            }
        }
    }
}
