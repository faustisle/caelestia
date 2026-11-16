import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

ConnectedRect {
    id: root

    required property var modelData
    required property int index

    first: root.index === 0
    last: root.index === Storage.volumes.length - 1
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
                        text: root.modelData.mount === "/" ? Tr.tr("Root") : root.modelData.mount
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        visible: root.modelData.mount === Storage.homeMount
                        text: Tr.tr("Home")
                        color: Colours.palette.m3primary
                        font: Tokens.font.label.small
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: `${root.modelData.fs} · ${root.modelData.type}`
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    elide: Text.ElideMiddle
                }
            }

            StyledText {
                text: `${root.modelData.percent}%`
                color: root.modelData.percent >= 90 ? Colours.palette.m3error : Colours.palette.m3primary
                font: Tokens.font.body.small
            }
        }

        StyledProgressBar {
            Layout.fillWidth: true
            implicitHeight: Tokens.padding.small
            value: root.modelData.size > 0 ? root.modelData.used / root.modelData.size : 0
            fgColour: root.modelData.percent >= 90 ? Colours.palette.m3error : Colours.palette.m3primary
        }

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: Tr.tr("%1 of %2 used").arg(Storage.formatSize(root.modelData.used)).arg(Storage.formatSize(root.modelData.size))
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: Tr.tr("%1 free").arg(Storage.formatSize(root.modelData.avail))
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
            }
        }
    }
}
