pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.effects
import qs.services
import qs.modules.nexus

Item {
    id: root

    required property ShellScreen screen

    property bool opened
    property real clickX
    property real clickY
    property var entry: null
    property bool confirmingDelete
    property bool sortMenuVisible

    readonly property real baseMargin: Math.max(16, Tokens.padding.large)
    readonly property real menuWidth: 232
    readonly property real menuPadding: Tokens.padding.extraSmall
    readonly property real submenuWidth: 164
    readonly property var barRef: ShellState.componentsFor(root.screen)?.bar
    readonly property bool barHorizontal: Config.bar.position === "top" || Config.bar.position === "bottom"
    readonly property real barThickness: root.barRef?.contentThickness ?? (root.barHorizontal ? Tokens.sizes.bar.horizontalInnerWidth + Tokens.padding.extraSmall * 2 : Tokens.sizes.bar.innerWidth + Math.max(Tokens.padding.small, Config.border.thickness) * 2)
    readonly property real marginLeft: root.baseMargin + (Config.bar.position === "left" ? root.barThickness + root.baseMargin : 0)
    readonly property real marginRight: root.baseMargin + (Config.bar.position === "right" ? root.barThickness + root.baseMargin : 0)
    readonly property real marginTop: root.baseMargin + (Config.bar.position === "top" ? root.barThickness + root.baseMargin : 0)
    readonly property real marginBottom: root.baseMargin + (Config.bar.position === "bottom" ? root.barThickness + root.baseMargin : 0)
    readonly property string sortBy: GlobalConfig.background.desktopIcons.sortBy || "custom"

    signal renameRequested(entry: var)

    function openAt(x: real, y: real, item = null): void {
        root.clickX = x;
        root.clickY = y;
        root.entry = item;
        root.opened = true;
        root.confirmingDelete = false;
        root.sortMenuVisible = false;
    }

    function close(): void {
        root.opened = false;
        root.confirmingDelete = false;
        root.sortMenuVisible = false;
        root.entry = null;
        sortCloseTimer.stop();
    }

    function openSortMenu(): void {
        root.sortMenuVisible = true;
        sortCloseTimer.stop();
    }

    function scheduleSortMenuClose(): void {
        if (root.sortMenuVisible)
            sortCloseTimer.restart();
    }

    function setSort(value: string): void {
        GlobalConfig.background.desktopIcons.sortBy = value;
        root.close();
    }

    function openNexus(page: int, subPages: var): void {
        root.close();
        WindowFactory.openPage(page, subPages);
    }

    function requestRename(): void {
        const target = root.entry;
        root.close();
        if (target)
            root.renameRequested(target);
    }

    function confirmDelete(): void {
        const target = root.entry;
        root.close();
        if (target)
            Desktop.deleteEntry(target);
    }

    visible: root.opened
    z: 1000

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: root.close()
    }

    Elevation {
        id: panel

        visible: !root.confirmingDelete
        level: 2
        radius: Tokens.rounding.large
        width: root.menuWidth
        height: mainColumn.implicitHeight + root.menuPadding * 2
        implicitWidth: width
        implicitHeight: height
        x: Math.max(root.marginLeft, Math.min(root.clickX, root.width - width - root.marginRight))
        y: Math.max(root.marginTop, Math.min(root.clickY, root.height - height - root.marginBottom))

        StyledRect {
            anchors.fill: parent
            radius: parent.radius
            color: Colours.palette.m3surfaceContainerLow
            border.width: 1
            border.color: Colours.palette.m3primary
        }

        ColumnLayout {
            id: mainColumn

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: root.menuPadding
            spacing: 0

            MenuRow {
                visible: root.entry !== null
                icon: "open_in_new"
                label: Tr.tr("Open")
                onClicked: {
                    const target = root.entry;
                    root.close();
                    if (target)
                        Desktop.launch(target);
                }
            }

            MenuRow {
                visible: root.entry !== null && root.entry.kind !== "application"
                icon: "drive_file_rename_outline"
                label: Tr.tr("Rename")
                onClicked: root.requestRename()
            }

            MenuRow {
                visible: root.entry !== null
                icon: "folder_open"
                label: Tr.tr("Open file location")
                onClicked: {
                    const target = root.entry;
                    root.close();
                    if (target)
                        Desktop.openLocation(target.path);
                }
            }

            MenuSeparator {
                visible: root.entry !== null
            }

            MenuRow {
                visible: root.entry !== null
                icon: "delete"
                label: Tr.tr("Delete")
                destructive: true
                onClicked: root.confirmingDelete = true
            }

            MenuRow {
                visible: root.entry === null
                icon: "create_new_folder"
                label: Tr.tr("New folder")
                onClicked: {
                    Desktop.createFolder();
                    root.close();
                }
            }

            MenuRow {
                visible: root.entry === null
                icon: "note_add"
                label: Tr.tr("New file")
                onClicked: {
                    Desktop.createFile();
                    root.close();
                }
            }

            MenuSeparator {
                visible: root.entry === null
            }

            MenuRow {
                id: sortRow

                visible: root.entry === null
                icon: "sort"
                label: Tr.tr("Sort by")
                trailingIcon: "chevron_right"
                onClicked: root.openSortMenu()
                onHovered: {
                    root.openSortMenu();
                }
            }

            MenuRow {
                visible: root.entry === null
                icon: GlobalConfig.background.desktopIcons.enabled ? "visibility_off" : "visibility"
                label: GlobalConfig.background.desktopIcons.enabled ? Tr.tr("Hide desktop icons") : Tr.tr("Show desktop icons")
                onClicked: {
                    GlobalConfig.background.desktopIcons.enabled = !GlobalConfig.background.desktopIcons.enabled;
                    root.close();
                }
            }

            MenuSeparator {
                visible: root.entry === null
            }

            MenuRow {
                visible: root.entry === null
                icon: "settings"
                label: Tr.tr("Open settings")
                onClicked: {
                    root.close();
                    WindowFactory.create();
                }
            }

            MenuRow {
                visible: root.entry === null
                icon: "wallpaper"
                label: Tr.tr("Wallpaper settings")
                onClicked: root.openNexus(PageRegistry.wallpaperAndStylePage, [PageRegistry.wallpaperSubPage])
            }

            MenuRow {
                visible: root.entry === null
                icon: "palette"
                label: Tr.tr("Colour scheme")
                onClicked: root.openNexus(PageRegistry.wallpaperAndStylePage, [PageRegistry.coloursSubPage])
            }

            MenuRow {
                visible: root.entry === null
                icon: "monitor"
                label: Tr.tr("Display settings")
                onClicked: root.openNexus(PageRegistry.displaysPage, [])
            }
        }
    }

    Elevation {
        id: confirmPanel

        visible: root.confirmingDelete
        level: 2
        radius: Tokens.rounding.large
        width: root.menuWidth
        height: confirmColumn.implicitHeight + root.menuPadding * 2
        implicitWidth: width
        implicitHeight: height
        x: Math.max(root.marginLeft, Math.min(root.clickX, root.width - width - root.marginRight))
        y: Math.max(root.marginTop, Math.min(root.clickY, root.height - height - root.marginBottom))

        StyledRect {
            anchors.fill: parent
            radius: parent.radius
            color: Colours.palette.m3surfaceContainerLow
            border.width: 1
            border.color: Colours.palette.m3primary
        }

        ColumnLayout {
            id: confirmColumn

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: root.menuPadding
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.medium
                Layout.rightMargin: Tokens.padding.medium
                Layout.topMargin: Tokens.padding.medium
                Layout.bottomMargin: Tokens.padding.small
                text: Tr.tr("Move \"%1\" to the trash?").arg(root.entry?.name ?? "")
                color: Colours.palette.m3onSurface
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
            }

            MenuRow {
                icon: "cancel"
                label: Tr.tr("Cancel")
                onClicked: root.confirmingDelete = false
            }

            MenuRow {
                icon: "delete"
                label: Tr.tr("Delete")
                destructive: true
                onClicked: root.confirmDelete()
            }
        }
    }

    Elevation {
        id: sortPanel

        visible: root.sortMenuVisible && !root.confirmingDelete && root.entry === null
        level: 2
        radius: Tokens.rounding.large
        width: root.submenuWidth
        height: sortColumn.implicitHeight + root.menuPadding * 2
        implicitWidth: width
        implicitHeight: height
        x: {
            const right = panel.x + panel.width + Tokens.spacing.small;
            if (right + width <= root.width - root.marginRight)
                return right;
            return Math.max(root.marginLeft, panel.x - width - Tokens.spacing.small);
        }
        y: Math.max(root.marginTop, Math.min(panel.y + root.menuPadding + sortRow.y, root.height - height - root.marginBottom))

        StyledRect {
            anchors.fill: parent
            radius: parent.radius
            color: Colours.palette.m3surfaceContainerLow
            border.width: 1
            border.color: Colours.palette.m3primary
        }

        ColumnLayout {
            id: sortColumn

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: root.menuPadding
            spacing: 0

            MenuRow {
                icon: "sort_by_alpha"
                label: Tr.tr("Name")
                trailingIcon: root.sortBy === "name" ? "check" : ""
                onClicked: root.setSort("name")
            }

            MenuRow {
                icon: "data_usage"
                label: Tr.tr("Size")
                trailingIcon: root.sortBy === "size" ? "check" : ""
                onClicked: root.setSort("size")
            }

            MenuRow {
                icon: "category"
                label: Tr.tr("Type")
                trailingIcon: root.sortBy === "type" ? "check" : ""
                onClicked: root.setSort("type")
            }

            MenuRow {
                icon: "schedule"
                label: Tr.tr("Modified")
                trailingIcon: root.sortBy === "modified" ? "check" : ""
                onClicked: root.setSort("modified")
            }
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    sortCloseTimer.stop();
                else
                    root.scheduleSortMenuClose();
            }
        }
    }

    Timer {
        id: sortCloseTimer

        interval: 180
        onTriggered: root.sortMenuVisible = false
    }

    component MenuRow: StyledRect {
        id: row

        required property string icon
        required property string label
        property string trailingIcon
        property bool destructive

        signal clicked
        signal hovered
        signal unhovered

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
                visible: row.icon !== ""
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

            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter
                visible: row.trailingIcon !== ""
                text: row.trailingIcon
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.small
            }
        }

        StateLayer {
            anchors.fill: parent
            radius: row.radius
            color: Colours.palette.m3onSurface
            onClicked: row.clicked()
            onEntered: row.hovered()
            onExited: row.unhovered()
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
