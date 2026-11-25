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

    title: Tr.tr("Style")
    isSubPage: false

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        StyledText {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.medium
            text: Tr.tr("Choose a style. Changes apply immediately.")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        Repeater {
            model: Theme.themes

            StyledRect {
                id: card

                required property var modelData
                required property int index

                readonly property bool selected: Theme.current === card.modelData.id

                Layout.fillWidth: true
                implicitHeight: cardContent.implicitHeight + Tokens.padding.large * 2

                radius: Tokens.rounding.large
                color: card.selected ? Qt.alpha(Colours.palette.m3primaryContainer, 0.8) : Colours.tPalette.m3surfaceContainerHigh
                border.width: Theme.borderWidth
                border.color: card.selected ? Colours.palette.m3primary : Theme.borderColour

                StateLayer {
                    radius: card.radius
                    color: card.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    onClicked: Theme.apply(card.modelData.id)
                }

                RowLayout {
                    id: cardContent

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        Layout.alignment: Qt.AlignVCenter
                        text: card.selected ? "check_circle" : "palette"
                        color: card.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.large
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall / 2

                        StyledText {
                            Layout.fillWidth: true
                            text: card.modelData.name
                            color: card.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                            font: Tokens.font.title.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: card.modelData.description
                            color: card.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
}
