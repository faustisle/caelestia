pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    property bool opened
    property string title
    property string initialText
    property string acceptLabel
    property string placeholderText

    signal accepted(name: string)
    signal rejected

    function open(title: string, initialText: string, acceptLabel: string, placeholderText: string): void {
        root.title = title;
        root.initialText = initialText;
        root.acceptLabel = acceptLabel;
        root.placeholderText = placeholderText;
        Qt.callLater(() => {
            root.opened = true;
            Qt.callLater(() => {
                field.text = initialText;
                field.forceActiveFocus();
                field.select(0, field.length);
            });
        });
    }

    function close(): void {
        root.opened = false;
    }

    function submit(): void {
        const name = field.text.trim();
        if (!name || name.includes("/"))
            return;

        root.accepted(name);
        root.close();
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
        onPressed: {
            root.rejected();
            root.close();
        }
    }

    StyledRect {
        anchors.centerIn: parent
        width: 420
        implicitHeight: dialogContent.implicitHeight + Tokens.padding.large * 2

        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerLow
        border.width: 1
        border.color: Colours.palette.m3primary

        ColumnLayout {
            id: dialogContent

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.large

            StyledText {
                Layout.fillWidth: true
                text: root.title
                color: Colours.palette.m3onSurface
                font: Tokens.font.title.medium
            }

            StyledTextField {
                id: field

                Layout.fillWidth: true
                placeholderText: root.placeholderText
                onAccepted: root.submit()
                Keys.onEscapePressed: {
                    root.rejected();
                    root.close();
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Item {
                    Layout.fillWidth: true
                }

                TextButton {
                    text: Tr.tr("Cancel")
                    onClicked: {
                        root.rejected();
                        root.close();
                    }
                }

                TextButton {
                    text: root.acceptLabel
                    type: TextButton.Filled
                    enabled: field.text.trim().length > 0 && !field.text.includes("/")
                    onClicked: root.submit()
                }
            }
        }
    }
}
