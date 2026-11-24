pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Models
import qs.components
import qs.components.effects
import qs.services

Item {
    id: root

    property bool opened
    property real clickX
    property real clickY
    property string currentPath
    property var entries: []

    readonly property var singleEntry: entries.length === 1 ? entries[0] : null
    readonly property bool background: entries.length === 0

    signal openRequested(var entry)
    signal promptRequested(string mode, var entries, string initial)
    signal propertiesRequested(var entries)
    signal openWithRequested(var entry)
    signal confirmDeleteRequested(var entries, bool permanent)
    signal selectAllRequested()
    signal toggleHiddenRequested()
    signal closed

    function open(x: real, y: real, items: var): void {
        root.clickX = x;
        root.clickY = y;
        root.entries = items ?? [];
        root.opened = true;
    }

    function close(): void {
        if (!root.opened)
            return;
        root.opened = false;
        root.closed();
    }

    function paths(): list<string> {
        return root.entries.map(entry => entry.path);
    }

    function copy(cut: bool): void {
        Files.copy(root.paths(), cut);
        root.close();
    }

    function paste(): void {
        Files.paste(root.currentPath);
        root.close();
    }

    function copyLocation(): void {
        const paths = root.paths();
        if (paths.length === 0)
            paths.push(root.currentPath);
        Quickshell.clipboardText = paths.join("\n");
        root.close();
    }

    anchors.fill: parent
    visible: opened
    z: 4000

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Elevation {
        id: panel

        readonly property real padding: Tokens.padding.extraSmall

        width: 246
        height: menuContent.implicitHeight + padding * 2
        x: Math.max(Tokens.padding.large, Math.min(root.clickX, root.width - width - Tokens.padding.large))
        y: Math.max(Tokens.padding.large, Math.min(root.clickY, root.height - height - Tokens.padding.large))
        radius: Tokens.rounding.large
        level: 2

        StyledRect {
            anchors.fill: parent
            radius: parent.radius
            color: Colours.palette.m3surfaceContainerLow
            border.width: 1
            border.color: Colours.palette.m3primary
        }

        ColumnLayout {
            id: menuContent

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: panel.padding
            spacing: 0

            MenuRow {
                visible: root.singleEntry !== null
                icon: "open_in_new"
                label: Tr.tr("Open")
                onClicked: {
                    const entry = root.singleEntry;
                    root.close();
                    root.openRequested(entry);
                }
            }

            MenuRow {
                visible: root.singleEntry?.isDir ?? false
                icon: "open_in_new"
                label: Tr.tr("Open in New Window")
                onClicked: {
                    const path = root.singleEntry.path;
                    root.close();
                    Files.open(path);
                }
            }

            MenuRow {
                visible: root.background || (root.singleEntry?.isDir ?? false)
                icon: "terminal"
                label: Tr.tr("Open in Terminal")
                onClicked: {
                    const path = root.singleEntry?.path ?? root.currentPath;
                    root.close();
                    Files.openTerminal(path);
                }
            }

            MenuRow {
                visible: root.singleEntry !== null && !root.singleEntry.isDir
                icon: "apps"
                label: Tr.tr("Open With…")
                onClicked: {
                    const entry = root.singleEntry;
                    root.close();
                    root.openWithRequested(entry);
                }
            }

            MenuSeparator {
                visible: !root.background
            }

            MenuRow {
                visible: !root.background
                icon: "content_cut"
                label: Tr.tr("Cut")
                onClicked: root.copy(true)
            }

            MenuRow {
                visible: !root.background
                icon: "content_copy"
                label: Tr.tr("Copy")
                onClicked: root.copy(false)
            }

            MenuRow {
                visible: root.background && Files.hasClipboard
                icon: "content_paste"
                label: Tr.tr("Paste")
                onClicked: root.paste()
            }

            MenuRow {
                visible: root.singleEntry !== null && !root.background
                icon: "drive_file_rename_outline"
                label: Tr.tr("Rename")
                onClicked: {
                    const entry = root.singleEntry;
                    root.close();
                    root.promptRequested("rename", root.entries, entry.name);
                }
            }

            MenuRow {
                visible: !root.background
                icon: "delete"
                label: Tr.tr("Move to Trash")
                destructive: true
                onClicked: {
                    const items = root.entries;
                    root.close();
                    root.confirmDeleteRequested(items, false);
                }
            }

            MenuRow {
                visible: !root.background
                icon: "delete_forever"
                label: Tr.tr("Delete Permanently")
                destructive: true
                onClicked: {
                    const items = root.entries;
                    root.close();
                    root.confirmDeleteRequested(items, true);
                }
            }

            MenuSeparator {
                visible: !root.background
            }

            MenuRow {
                visible: !root.background
                icon: "archive"
                label: Tr.tr("Compress to ZIP…")
                onClicked: {
                    const base = root.singleEntry ? root.singleEntry.baseName : root.currentPath.slice(root.currentPath.lastIndexOf("/") + 1);
                    root.close();
                    root.promptRequested("compress", root.entries, `${base || "Archive"}.zip`);
                }
            }

            MenuRow {
                visible: root.singleEntry !== null && Files.isArchive(root.singleEntry)
                icon: "unarchive"
                label: Tr.tr("Extract Here")
                onClicked: {
                    const entry = root.singleEntry;
                    root.close();
                    Files.extract(entry.path, root.currentPath, "");
                }
            }

            MenuRow {
                visible: root.singleEntry !== null && Files.isArchive(root.singleEntry)
                icon: "unarchive"
                label: Tr.tr("Extract to Folder…")
                onClicked: {
                    const entry = root.singleEntry;
                    const name = Files.archiveBaseName(entry);
                    root.close();
                    root.promptRequested("extract", root.entries, name);
                }
            }

            MenuSeparator {
                visible: root.background || root.singleEntry !== null
            }

            MenuRow {
                visible: root.background || root.singleEntry !== null
                icon: "content_copy"
                label: Tr.tr("Copy Location")
                onClicked: root.copyLocation()
            }

            MenuRow {
                visible: root.background || root.singleEntry !== null || root.entries.length > 1
                icon: "info"
                label: Tr.tr("Properties")
                onClicked: {
                    const items = root.entries;
                    root.close();
                    root.propertiesRequested(items);
                }
            }

            MenuRow {
                visible: root.background
                icon: "create_new_folder"
                label: Tr.tr("New Folder")
                onClicked: {
                    root.close();
                    root.promptRequested("newFolder", [], Tr.tr("New Folder"));
                }
            }

            MenuRow {
                visible: root.background
                icon: "note_add"
                label: Tr.tr("New File")
                onClicked: {
                    root.close();
                    root.promptRequested("newFile", [], Tr.tr("New File"));
                }
            }

            MenuRow {
                visible: root.background
                icon: "select_all"
                label: Tr.tr("Select All")
                onClicked: {
                    root.close();
                    root.selectAllRequested();
                }
            }

            MenuRow {
                visible: root.background
                icon: "visibility"
                label: Tr.tr("Show Hidden Files")
                onClicked: {
                    root.close();
                    root.toggleHiddenRequested();
                }
            }
        }
    }

    component MenuRow: StyledRect {
        id: row

        required property string icon
        required property string label
        property bool destructive

        signal clicked

        Layout.fillWidth: true
        implicitHeight: Math.max(36, rowLayout.implicitHeight + Tokens.padding.small * 2)
        radius: Tokens.rounding.medium
        color: "transparent"

        RowLayout {
            id: rowLayout

            anchors.fill: parent
            anchors.leftMargin: Tokens.padding.small
            anchors.rightMargin: Tokens.padding.small
            spacing: Tokens.spacing.small

            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter
                text: row.icon
                color: row.destructive ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: row.label
                color: row.destructive ? Colours.palette.m3error : Colours.palette.m3onSurface
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }

        StateLayer {
            color: Colours.palette.m3onSurface
            onClicked: row.clicked()
        }
    }

    component MenuSeparator: Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.small
        Layout.rightMargin: Tokens.padding.small
        Layout.topMargin: Tokens.padding.extraSmall
        Layout.bottomMargin: Tokens.padding.extraSmall
        implicitHeight: 1
        color: Qt.alpha(Colours.palette.m3outlineVariant, 0.6)
    }
}
