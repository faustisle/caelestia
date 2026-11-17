pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.effects
import qs.services
import qs.modules.nexus

Item {
    id: root

    property bool opened
    property real clickX
    property real clickY
    property bool sortMenuVisible
    property bool sortRowHovered
    property bool sortPanelHovered

    readonly property real edgeMargin: Tokens.padding.small
    readonly property real menuWidth: 252
    readonly property real menuPadding: Tokens.padding.extraSmall
    readonly property real submenuWidth: 176
    readonly property string sortBy: GlobalConfig.background.desktopIcons.sortBy || "custom"

    function openAt(x: real, y: real): void {
        root.clickX = x;
        root.clickY = y;
        root.opened = true;
        root.sortMenuVisible = false;
        root.sortRowHovered = false;
        root.sortPanelHovered = false;
    }

    function close(): void {
        root.opened = false;
        root.sortMenuVisible = false;
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

    visible: root.opened
    z: 1000

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: root.close()
    }

    Elevation {
        id: panel

        level: 2
        radius: Tokens.rounding.large
        width: root.menuWidth
        height: mainColumn.implicitHeight + root.menuPadding * 2
        implicitWidth: width
        implicitHeight: height
        x: Math.max(root.edgeMargin, Math.min(root.clickX, root.width - width - root.edgeMargin))
        y: Math.max(root.edgeMargin, Math.min(root.clickY, root.height - height - root.edgeMargin))

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
                icon: "create_new_folder"
                label: Tr.tr("New folder")
                onClicked: {
                    Desktop.createFolder();
                    root.close();
                }
            }

            MenuRow {
                icon: "note_add"
                label: Tr.tr("New file")
                onClicked: {
                    Desktop.createFile();
                    root.close();
                }
            }

            MenuSeparator {}

            MenuRow {
                id: sortRow

                icon: "sort"
                label: Tr.tr("Sort by")
                trailingIcon: "chevron_right"
                onClicked: root.openSortMenu()
                onHovered: {
                    root.sortRowHovered = true;
                    root.openSortMenu();
                }
                onUnhovered: {
                    root.sortRowHovered = false;
                    root.scheduleSortMenuClose();
                }
            }

            MenuRow {
                icon: GlobalConfig.background.desktopIcons.enabled ? "visibility_off" : "visibility"
                label: GlobalConfig.background.desktopIcons.enabled ? Tr.tr("Hide desktop icons") : Tr.tr("Show desktop icons")
                onClicked: {
                    GlobalConfig.background.desktopIcons.enabled = !GlobalConfig.background.desktopIcons.enabled;
                    root.close();
                }
            }

            MenuSeparator {}

            MenuRow {
                icon: "settings"
                label: Tr.tr("Open settings")
                onClicked: {
                    root.close();
                    WindowFactory.create();
                }
            }

            MenuRow {
                icon: "wallpaper"
                label: Tr.tr("Wallpaper settings")
                onClicked: root.openNexus(PageRegistry.wallpaperAndStylePage, [PageRegistry.wallpaperSubPage])
            }

            MenuRow {
                icon: "palette"
                label: Tr.tr("Colour scheme settings")
                onClicked: root.openNexus(PageRegistry.wallpaperAndStylePage, [PageRegistry.coloursSubPage])
            }

            MenuRow {
                icon: "monitor"
                label: Tr.tr("Display settings")
                onClicked: root.openNexus(PageRegistry.displaysPage, [])
            }
        }
    }

    Elevation {
        id: sortPanel

        visible: root.sortMenuVisible
        level: 2
        radius: Tokens.rounding.large
        width: root.submenuWidth
        height: sortColumn.implicitHeight + root.menuPadding * 2
        implicitWidth: width
        implicitHeight: height
        x: {
            const right = panel.x + panel.width + Tokens.spacing.small;
            return right + width <= root.width - root.edgeMargin ? right : panel.x - width - Tokens.spacing.small;
        }
        y: Math.max(root.edgeMargin, Math.min(panel.y + root.menuPadding + sortRow.y, root.height - height - root.edgeMargin))

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
                root.sortPanelHovered = hovered;
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
        onTriggered: {
            if (!root.sortRowHovered && !root.sortPanelHovered)
                root.sortMenuVisible = false;
        }
    }

    component MenuRow: StyledRect {
        id: row

        required property string icon
        required property string label
        property string trailingIcon

        signal clicked
        signal hovered
        signal unhovered

        Layout.fillWidth: true
        implicitHeight: Math.max(40, rowLayout.implicitHeight + Tokens.padding.small * 2)
        radius: Tokens.rounding.medium
        color: "transparent"

        RowLayout {
            id: rowLayout

            anchors.fill: parent
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.small

            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter
                visible: row.icon !== ""
                text: row.icon
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: row.label
                color: Colours.palette.m3onSurface
                font: Tokens.font.body.medium
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
