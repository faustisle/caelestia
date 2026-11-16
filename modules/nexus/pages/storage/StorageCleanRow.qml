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

    property int count
    property bool confirming: false

    readonly property bool review: root.modelData.kind === "review"

    first: root.index === 0
    last: root.index === root.count - 1
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
            text: root.modelData.icon
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
                    text: root.modelData.title
                    font: Tokens.font.body.small
                }

                MaterialIcon {
                    visible: root.modelData.root === true
                    text: "lock"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.small
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.confirming ? root.modelData.confirm : root.modelData.description
                color: root.confirming ? Colours.palette.m3error : Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.confirming && root.modelData.details !== undefined && root.modelData.details !== ""
                text: root.modelData.details ?? ""
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.Wrap
            }
        }

        StyledText {
            text: Storage.formatSize(root.modelData.size)
            font: Tokens.font.body.small
        }

        RowLayout {
            visible: root.review
            spacing: Tokens.spacing.small

            TextButton {
                text: root.modelData.action
                onClicked: Storage.openFolder(root.modelData.path)
            }
        }

        RowLayout {
            visible: !root.review && !root.confirming && Storage.cleaning !== root.modelData.id
            spacing: Tokens.spacing.small

            TextButton {
                text: root.modelData.action
                enabled: Storage.cleaning === "" && (root.modelData.size > 0 || root.modelData.removable === true)
                onClicked: root.confirming = true
            }
        }

        RowLayout {
            visible: !root.review && root.confirming
            spacing: Tokens.spacing.small

            TextButton {
                text: Tr.tr("Cancel")
                onClicked: root.confirming = false
            }

            TextButton {
                text: root.modelData.action
                type: TextButton.Filled
                enabled: Storage.cleaning === ""
                onClicked: {
                    root.confirming = false;
                    Storage.clean(root.modelData);
                }
            }
        }

        LoadingIndicator {
            visible: Storage.cleaning === root.modelData.id
            implicitSize: 28
        }
    }
}
