pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils

StyledRect {
    id: root

    required property string currentPath
    property var bookmarks: []

    readonly property var places: [
        {
            name: Tr.tr("Home"),
            path: Paths.home,
            icon: "home"
        },
        {
            name: Tr.tr("Desktop"),
            path: Paths.desktop,
            icon: "desktop_windows"
        },
        {
            name: Tr.tr("Documents"),
            path: Quickshell.env("XDG_DOCUMENTS_DIR") || `${Paths.home}/Documents`,
            icon: "description"
        },
        {
            name: Tr.tr("Downloads"),
            path: Quickshell.env("XDG_DOWNLOAD_DIR") || `${Paths.home}/Downloads`,
            icon: "file_download"
        },
        {
            name: Tr.tr("Music"),
            path: Quickshell.env("XDG_MUSIC_DIR") || `${Paths.home}/Music`,
            icon: "music_note"
        },
        {
            name: Tr.tr("Pictures"),
            path: Paths.pictures,
            icon: "image"
        },
        {
            name: Tr.tr("Videos"),
            path: Quickshell.env("XDG_VIDEOS_DIR") || `${Paths.home}/Videos`,
            icon: "video_library"
        },
        {
            name: Tr.tr("Trash"),
            path: Files.trashPath,
            icon: "delete"
        },
        {
            name: Tr.tr("File System"),
            path: "/",
            icon: "computer"
        }
    ]

    signal navigate(path: string)

    function isSelected(path: string): bool {
        return root.currentPath === path;
    }

    function parseBookmarks(text: string): void {
        const result = [];
        for (const line of text.split("\n")) {
            const trimmed = line.trim();
            if (!trimmed || trimmed.startsWith("#"))
                continue;

            const space = trimmed.indexOf(" ");
            const uri = space === -1 ? trimmed : trimmed.slice(0, space);
            const label = space === -1 ? "" : trimmed.slice(space + 1).trim();
            const path = Paths.toLocalFile(uri);
            if (!path)
                continue;

            result.push({
                name: label || path.slice(path.lastIndexOf("/") + 1) || path,
                path: path,
                icon: "bookmark"
            });
        }
        root.bookmarks = result;
    }

    implicitWidth: 230

    color: Colours.tPalette.m3surfaceContainer

    FileView {
        id: bookmarksFile

        printErrors: false
        path: `${Quickshell.env("XDG_CONFIG_HOME") || `${Paths.home}/.config`}/gtk-3.0/bookmarks`

        onLoaded: root.parseBookmarks(text())
    }

    Flickable {
        anchors.fill: parent
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        ColumnLayout {
            id: content

            width: parent.width
            spacing: Tokens.spacing.extraSmall

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Tokens.padding.large
                Layout.bottomMargin: Tokens.spacing.medium
                text: Tr.tr("Files")
                color: Colours.palette.m3onSurface
                font: Tokens.font.body.builders.large.weight(Font.Bold).build()
            }

            Repeater {
                model: root.places

                StyledRect {
                    id: place

                    required property var modelData

                    readonly property bool selected: root.isSelected(place.modelData.path)

                    Layout.fillWidth: true
                    Layout.leftMargin: Tokens.padding.medium
                    Layout.rightMargin: Tokens.padding.medium
                    implicitHeight: placeRow.implicitHeight + Tokens.padding.medium * 2

                    radius: Tokens.rounding.full
                    color: Qt.alpha(Colours.palette.m3secondaryContainer, place.selected ? 1 : 0)

                    StateLayer {
                        color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        onClicked: root.navigate(place.modelData.path)
                    }

                    RowLayout {
                        id: placeRow

                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.large
                        anchors.rightMargin: Tokens.padding.large
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: place.modelData.icon
                            color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            fontStyle: Tokens.font.icon.medium
                            fill: place.selected ? 1 : 0
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: place.modelData.name
                            color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.large
                Layout.rightMargin: Tokens.padding.large
                Layout.topMargin: Tokens.spacing.medium
                Layout.bottomMargin: Tokens.spacing.extraSmall
                visible: root.bookmarks.length > 0
                text: Tr.tr("Bookmarks")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.medium
            }

            Repeater {
                model: root.bookmarks

                StyledRect {
                    id: bookmark

                    required property var modelData

                    readonly property bool selected: root.isSelected(bookmark.modelData.path)

                    Layout.fillWidth: true
                    Layout.leftMargin: Tokens.padding.medium
                    Layout.rightMargin: Tokens.padding.medium
                    implicitHeight: bookmarkRow.implicitHeight + Tokens.padding.medium * 2

                    radius: Tokens.rounding.full
                    color: Qt.alpha(Colours.palette.m3secondaryContainer, bookmark.selected ? 1 : 0)

                    StateLayer {
                        color: bookmark.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        onClicked: root.navigate(bookmark.modelData.path)
                    }

                    RowLayout {
                        id: bookmarkRow

                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.large
                        anchors.rightMargin: Tokens.padding.large
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: bookmark.modelData.icon
                            color: bookmark.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            fontStyle: Tokens.font.icon.medium
                            fill: bookmark.selected ? 1 : 0
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: bookmark.modelData.name
                            color: bookmark.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
