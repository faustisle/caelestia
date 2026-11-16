pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    required property string label
    required property string flavourLabel
    required property color primary
    required property color secondary
    required property color tertiary
    required property color surface
    required property bool active
    property bool manageable: false
    property bool interactive: true

    readonly property color contentColour: active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
    readonly property color subtextColour: active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant

    signal clicked
    signal editRequested
    signal deleteRequested

    Layout.fillWidth: true
    implicitHeight: content.implicitHeight + Tokens.padding.largeIncreased * 2
    radius: Tokens.rounding.extraLarge
    color: active ? Colours.layer(Colours.palette.m3secondaryContainer, 1) : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
    border.width: active ? 2 : 0
    border.color: Colours.palette.m3primary

    StateLayer {
        anchors.fill: parent
        radius: root.radius
        enabled: root.interactive
        onClicked: root.clicked()
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: root.label
                    color: root.contentColour
                    font: Tokens.font.body.large
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.flavourLabel
                    color: root.subtextColour
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }
            }

            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter
                visible: root.active
                text: "check"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.small
            }

            IconButton {
                id: moreButton

                Layout.alignment: Qt.AlignVCenter
                visible: root.manageable
                type: IconButton.Text
                isRound: true
                icon: "more_vert"
                font: Tokens.font.icon.small
                label.fill: 0
                onClicked: actionsMenu.expanded = !actionsMenu.expanded
            }
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: Math.round(Tokens.padding.extraLarge * 1.5)
            radius: Tokens.rounding.medium
            color: root.surface
            border.width: 1
            border.color: Colours.palette.m3outlineVariant

            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                Repeater {
                    model: [root.primary, root.secondary, root.tertiary]

                    StyledRect {
                        required property color modelData

                        implicitWidth: Math.round(Tokens.padding.large)
                        implicitHeight: implicitWidth
                        radius: Tokens.rounding.full
                        color: modelData
                    }
                }
            }
        }

        Menu {
            id: actionsMenu

            attachTo: moreButton
            onItemSelected: item => {
                if (item.value === "edit")
                    root.editRequested();
                else
                    root.deleteRequested();
            }
            items: [
                MenuItem {
                    text: Tr.tr("Edit")
                    icon: "edit"
                    value: "edit"
                },
                MenuItem {
                    text: Tr.tr("Delete")
                    icon: "delete"
                    value: "delete"
                }
            ]
        }
    }
}
