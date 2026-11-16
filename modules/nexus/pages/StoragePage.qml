pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Storage")
    isSubPage: false

    Component.onCompleted: Storage.refresh()

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Disks")
        }

        Repeater {
            model: Storage.volumes

            VolumeRow {
                required property var modelData
                required property int index
            }
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            visible: !Storage.volumesReady
            implicitHeight: disksLoading.implicitHeight + Tokens.padding.large * 2

            RowLayout {
                id: disksLoading

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                LoadingIndicator {
                    implicitSize: 28
                }

                StyledText {
                    text: Tr.tr("Reading disks…")
                    font: Tokens.font.body.small
                }
            }
        }

        SectionHeader {
            text: Tr.tr("Where space goes")
            visible: Storage.measuring || Storage.homeDirs.length > 0
        }

        Repeater {
            model: Storage.homeDirs

            UsageRow {
                required property var modelData
                required property int index
            }
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            visible: Storage.measuring && Storage.homeDirs.length === 0
            implicitHeight: measuring.implicitHeight + Tokens.padding.large * 2

            RowLayout {
                id: measuring

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                LoadingIndicator {
                    implicitSize: 28
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("Measuring disk usage…")
                    font: Tokens.font.body.small
                }

                StyledProgressBar {
                    Layout.preferredWidth: 160
                    implicitHeight: Tokens.padding.small
                    indeterminate: true
                }
            }
        }

        SectionHeader {
            text: Tr.tr("Free up space")
            visible: Storage.cleanups.length > 0
        }

        Repeater {
            model: Storage.cleanups

            CleanRow {
                required property var modelData
                required property int index
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large

            StyledText {
                Layout.fillWidth: true
                visible: Storage.lastError !== ""
                text: Storage.lastError
                color: Colours.palette.m3error
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }

            TextButton {
                text: Storage.measuring ? Tr.tr("Measuring…") : Tr.tr("Rescan")
                enabled: !Storage.measuring && Storage.cleaning === ""
                onClicked: Storage.refresh(true)
            }
        }
    }

    component VolumeRow: ConnectedRect {
        id: volumeRow

        required property var modelData
        required property int index

        first: volumeRow.index === 0
        last: volumeRow.index === Storage.volumes.length - 1
        Layout.fillWidth: true
        implicitHeight: volumeLayout.implicitHeight + Tokens.padding.large * 2

        ColumnLayout {
            id: volumeLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.small

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "hard_drive"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    RowLayout {
                        spacing: Tokens.spacing.small

                        StyledText {
                            text: volumeRow.modelData.mount === "/" ? Tr.tr("Root") : volumeRow.modelData.mount
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            visible: volumeRow.modelData.mount === Storage.homeMount
                            text: Tr.tr("Home")
                            color: Colours.palette.m3primary
                            font: Tokens.font.label.small
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: `${volumeRow.modelData.fs} · ${volumeRow.modelData.type}`
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideMiddle
                    }
                }

                StyledText {
                    text: `${volumeRow.modelData.percent}%`
                    color: volumeRow.modelData.percent >= 90 ? Colours.palette.m3error : Colours.palette.m3primary
                    font: Tokens.font.body.small
                }
            }

            StyledProgressBar {
                Layout.fillWidth: true
                implicitHeight: Tokens.padding.small
                value: volumeRow.modelData.size > 0 ? volumeRow.modelData.used / volumeRow.modelData.size : 0
                fgColour: volumeRow.modelData.percent >= 90 ? Colours.palette.m3error : Colours.palette.m3primary
            }

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: Tr.tr("%1 of %2 used").arg(Storage.formatSize(volumeRow.modelData.used)).arg(Storage.formatSize(volumeRow.modelData.size))
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: Tr.tr("%1 free").arg(Storage.formatSize(volumeRow.modelData.avail))
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                }
            }
        }
    }

    component UsageRow: ConnectedRect {
        id: usageRow

        required property var modelData
        required property int index

        first: usageRow.index === 0
        last: usageRow.index === Storage.homeDirs.length - 1
        Layout.fillWidth: true
        implicitHeight: usageLayout.implicitHeight + Tokens.padding.medium * 2

        RowLayout {
            id: usageLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: usageRow.modelData.icon
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.small
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    StyledText {
                        Layout.fillWidth: true
                        text: usageRow.modelData.label
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: Storage.formatSize(usageRow.modelData.size)
                        font: Tokens.font.body.small
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Storage.shortPath(usageRow.modelData.path)
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    elide: Text.ElideMiddle
                }

                StyledProgressBar {
                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.spacing.extraSmall
                    implicitHeight: 3
                    value: Storage.homeTotal > 0 ? Math.min(1, usageRow.modelData.size / Storage.homeTotal) : 0
                    fgColour: Colours.palette.m3tertiary
                    bgColour: Colours.tPalette.m3surfaceContainerHighest
                }
            }

            TextButton {
                text: Tr.tr("Show")
                onClicked: Storage.openFolder(usageRow.modelData.path)
            }
        }
    }

    component CleanRow: ConnectedRect {
        id: cleanRow

        required property var modelData
        required property int index

        property bool confirming: false

        first: cleanRow.index === 0
        last: cleanRow.index === Storage.cleanups.length - 1
        Layout.fillWidth: true
        implicitHeight: cleanLayout.implicitHeight + Tokens.padding.medium * 2

        RowLayout {
            id: cleanLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: cleanRow.modelData.icon
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.small
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                RowLayout {
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: cleanRow.modelData.title
                        font: Tokens.font.body.small
                    }

                    MaterialIcon {
                        visible: cleanRow.modelData.root === true
                        text: "lock"
                        color: Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.small
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: cleanRow.confirming ? cleanRow.modelData.confirm : cleanRow.modelData.description
                    color: cleanRow.confirming ? Colours.palette.m3error : Colours.palette.m3outline
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }
            }

            StyledText {
                text: Storage.formatSize(cleanRow.modelData.size)
                font: Tokens.font.body.small
            }

            RowLayout {
                visible: !cleanRow.confirming && Storage.cleaning !== cleanRow.modelData.id
                spacing: Tokens.spacing.small

                TextButton {
                    text: cleanRow.modelData.action
                    enabled: Storage.cleaning === "" && cleanRow.modelData.size > 0
                    onClicked: cleanRow.confirming = true
                }
            }

            RowLayout {
                visible: cleanRow.confirming
                spacing: Tokens.spacing.small

                TextButton {
                    text: Tr.tr("Cancel")
                    onClicked: cleanRow.confirming = false
                }

                TextButton {
                    text: cleanRow.modelData.action
                    type: TextButton.Filled
                    enabled: Storage.cleaning === ""
                    onClicked: {
                        cleanRow.confirming = false;
                        Storage.clean(cleanRow.modelData.id);
                    }
                }
            }

            LoadingIndicator {
                visible: Storage.cleaning === cleanRow.modelData.id
                implicitSize: 28
            }
        }
    }
}
