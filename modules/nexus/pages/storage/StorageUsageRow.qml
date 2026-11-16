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
    last: root.index === Storage.homeDirs.length - 1
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
            text: root.modelData.icon
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
                    text: root.modelData.label
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                StyledText {
                    text: Storage.formatSize(root.modelData.size)
                    font: Tokens.font.body.small
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: Storage.shortPath(root.modelData.path)
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideMiddle
            }

            StyledProgressBar {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.extraSmall
                implicitHeight: 3
                value: Storage.homeTotal > 0 ? Math.min(1, root.modelData.size / Storage.homeTotal) : 0
                fgColour: Colours.palette.m3tertiary
                bgColour: Colours.tPalette.m3surfaceContainerHighest
            }
        }

        TextButton {
            text: Tr.tr("Show")
            onClicked: Storage.openFolder(root.modelData.path)
        }
    }
}
