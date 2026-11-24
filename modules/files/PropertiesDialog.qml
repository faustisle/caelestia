pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Models
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    property bool opened
    property var entries: []

    readonly property var singleEntry: entries.length === 1 ? entries[0] : null
    readonly property real totalSize: entries.reduce((sum, entry) => sum + (entry.isDir ? 0 : entry.size), 0)
    readonly property string location: entries.length > 0 ? entries[0].parentDir : ""

    function open(items: var): void {
        root.entries = items ?? [];
        Qt.callLater(() => root.opened = true);
    }

    function close(): void {
        root.opened = false;
    }

    function formatSize(bytes: real): string {
        if (bytes < 1024)
            return Tr.tr("%1 B").arg(Math.round(bytes));
        if (bytes < 1024 * 1024)
            return Tr.tr("%1 KiB").arg((bytes / 1024).toFixed(1));
        if (bytes < 1024 * 1024 * 1024)
            return Tr.tr("%1 MiB").arg((bytes / (1024 * 1024)).toFixed(1));
        return Tr.tr("%1 GiB").arg((bytes / (1024 * 1024 * 1024)).toFixed(1));
    }

    function typeText(entry: FileSystemEntry): string {
        if (!entry)
            return "";
        if (entry.isDir)
            return Tr.tr("Folder");
        return entry.mimeType || entry.suffix.toUpperCase();
    }

    anchors.fill: parent
    visible: opened
    z: 5000

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha("black", 0.45)
    }

    MouseArea {
        anchors.fill: parent
        onPressed: root.close()
    }

    StyledRect {
        anchors.centerIn: parent
        width: 480
        implicitHeight: propertiesContent.implicitHeight + Tokens.padding.large * 2

        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerLow
        border.width: 1
        border.color: Colours.palette.m3primary

        ColumnLayout {
            id: propertiesContent

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Properties")
                color: Colours.palette.m3onSurface
                font: Tokens.font.title.medium
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.large

                MaterialIcon {
                    Layout.alignment: Qt.AlignTop
                    visible: root.singleEntry !== null
                    text: root.singleEntry?.isDir ? "folder" : "description"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.builders.extraLarge.build()
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        Layout.fillWidth: true
                        text: root.singleEntry ? root.singleEntry.name : Tr.tr("%1 items").arg(root.entries.length)
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.body.builders.large.weight(Font.Bold).build()
                        elide: Text.ElideMiddle
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.singleEntry ? root.typeText(root.singleEntry) : Tr.tr("%1 selected").arg(root.entries.length)
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Qt.alpha(Colours.palette.m3outlineVariant, 0.6)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.preferredWidth: 110
                    text: Tr.tr("Size")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.formatSize(root.totalSize)
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.small
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.preferredWidth: 110
                    text: Tr.tr("Location")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.location
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.small
                    elide: Text.ElideMiddle
                }
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: Tokens.padding.small
            }

            RowLayout {
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                TextButton {
                    text: Tr.tr("Close")
                    type: TextButton.Filled
                    onClicked: root.close()
                }
            }
        }
    }
}
