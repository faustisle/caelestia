pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    property bool opened
    property string targetPath: ""

    readonly property var apps: {
        return [...DesktopEntries.applications.values]
            .filter(app => !app.noDisplay)
            .sort((a, b) => a.name.localeCompare(b.name));
    }
    readonly property var filteredApps: {
        const query = searchField.text.trim().toLowerCase();
        if (!query)
            return root.apps;
        return root.apps.filter(app => app.name.toLowerCase().includes(query) || app.comment.toLowerCase().includes(query));
    }

    function open(path: string): void {
        root.targetPath = path;
        Qt.callLater(() => {
            root.opened = true;
            Qt.callLater(() => {
                searchField.text = "";
                searchField.forceActiveFocus();
            });
        });
    }

    function close(): void {
        root.opened = false;
    }

    function launch(app: var): void {
        if (!app)
            return;
        Files.launchWith(app, root.targetPath);
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
        onPressed: root.close()
    }

    StyledRect {
        anchors.centerIn: parent
        width: 520
        implicitHeight: 560

        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerLow
        border.width: 1
        border.color: Colours.palette.m3primary

        ColumnLayout {
            id: content

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Open with")
                color: Colours.palette.m3onSurface
                font: Tokens.font.title.medium
            }

            StyledTextField {
                id: searchField

                Layout.fillWidth: true
                placeholderText: Tr.tr("Search applications")
                leadingIcon: "search"
                onAccepted: {
                    if (root.filteredApps.length > 0)
                        root.launch(root.filteredApps[0]);
                }
                Keys.onEscapePressed: root.close()
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.fillHeight: true

                radius: Tokens.rounding.medium
                color: Colours.tPalette.m3surfaceContainer

                ListView {
                    id: appList

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.extraSmall
                    clip: true
                    model: root.filteredApps

                    StyledScrollBar.vertical: StyledScrollBar {
                        flickable: appList
                    }

                    delegate: StyledRect {
                        id: appRow

                        required property var modelData

                        width: appList.width
                        implicitHeight: appRowContent.implicitHeight + Tokens.padding.small * 2

                        radius: Tokens.rounding.medium
                        color: "transparent"

                        StateLayer {
                            onClicked: root.launch(appRow.modelData)
                        }

                        RowLayout {
                            id: appRowContent

                            anchors.fill: parent
                            anchors.leftMargin: Tokens.padding.medium
                            anchors.rightMargin: Tokens.padding.medium
                            spacing: Tokens.spacing.medium

                            Image {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: Tokens.font.icon.medium.pointSize * 1.6
                                Layout.preferredHeight: Layout.preferredWidth
                                source: Quickshell.iconPath(appRow.modelData.icon, "application-x-executable")
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    Layout.fillWidth: true
                                    text: appRow.modelData.name
                                    color: Colours.palette.m3onSurface
                                    font: Tokens.font.body.small
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    visible: appRow.modelData.comment.length > 0
                                    text: appRow.modelData.comment
                                    color: Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.label.small
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                TextButton {
                    text: Tr.tr("Cancel")
                    onClicked: root.close()
                }
            }
        }
    }
}
