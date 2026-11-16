pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.services
import qs.utils

// Application shortcuts from the user's desktop folder, laid out in columns from
// the configured corner. Purely pointer driven: the background layer never takes
// keyboard focus, so using the desktop cannot pull focus from a window.
Item {
    id: root

    readonly property var iconsConfig: Config.background.desktopIcons

    readonly property string position: ["top-left", "top-right", "bottom-left", "bottom-right"].includes(root.iconsConfig.position) ? root.iconsConfig.position : "top-right"
    readonly property bool showLabels: root.iconsConfig.showLabels
    readonly property int iconSize: root.iconsConfig.iconSize

    readonly property bool alignRight: root.position.endsWith("right")
    readonly property bool alignBottom: root.position.startsWith("bottom")

    // The bar floats over the wallpaper, so leave room for it on whichever edge
    // it occupies. These mirror BarWrapper's content thickness.
    readonly property bool barHorizontal: Config.bar.position === "top" || Config.bar.position === "bottom"
    readonly property real barThickness: root.barHorizontal ? Tokens.sizes.bar.horizontalInnerWidth + Tokens.padding.extraSmall * 2 : Tokens.sizes.bar.innerWidth + Math.max(Tokens.padding.small, Config.border.thickness) * 2
    readonly property real marginLeft: Tokens.padding.extraLargeIncreased + (Config.bar.position === "left" ? root.barThickness : 0)
    readonly property real marginRight: Tokens.padding.extraLargeIncreased + (Config.bar.position === "right" ? root.barThickness : 0)
    readonly property real marginTop: Tokens.padding.extraLargeIncreased + (Config.bar.position === "top" ? root.barThickness : 0)
    readonly property real marginBottom: Tokens.padding.extraLargeIncreased + (Config.bar.position === "bottom" ? root.barThickness : 0)

    readonly property real spacing: Tokens.spacing.small
    readonly property real labelHeight: root.showLabels ? Math.ceil(labelMetrics.height * 2 + Tokens.spacing.extraSmall) : 0
    readonly property real tileWidth: Math.max(root.iconSize + Tokens.padding.medium * 2, 96)
    readonly property real tileHeight: root.iconSize + (root.showLabels ? root.spacing + root.labelHeight : 0) + Tokens.padding.medium * 2
    readonly property real cellWidth: root.tileWidth + root.spacing
    readonly property real cellHeight: root.tileHeight + root.spacing

    readonly property int count: icons.entries.length
    readonly property real usableHeight: Math.max(root.cellHeight, root.height - root.marginTop - root.marginBottom)
    readonly property int rows: Math.max(1, Math.floor((root.usableHeight + root.spacing) / root.cellHeight))
    readonly property int columns: root.count === 0 ? 0 : Math.ceil(root.count / root.rows)
    readonly property real gridWidth: root.columns === 0 ? 0 : root.columns * root.cellWidth - root.spacing
    readonly property real gridHeight: root.count === 0 ? 0 : Math.min(root.count, root.rows) * root.cellHeight - root.spacing
    readonly property real gridX: root.alignRight ? root.width - root.marginRight - root.gridWidth : root.marginLeft
    readonly property real gridY: root.alignBottom ? root.height - root.marginBottom - root.gridHeight : root.marginTop

    // Used by the window's input mask, so the rest of the desktop keeps its
    // normal click behaviour instead of being swallowed by the background.
    readonly property rect bounds: Qt.rect(root.gridX, root.gridY, root.gridWidth, root.gridHeight)

    // Emitted for a right click on an icon. The desktop context menu can connect
    // to this without the icon grid needing to know about it.
    signal contextMenuRequested(entry: var, x: real, y: real)

    anchors.fill: parent

    TextMetrics {
        id: labelMetrics

        font: Tokens.font.label.medium
        text: "Ag"
    }

    DesktopFileModel {
        id: icons

        path: Paths.desktop
        watchChanges: true
    }

    Repeater {
        model: icons.entries

        StyledRect {
            id: tile

            required property DesktopFile modelData
            required property int index

            readonly property int row: tile.index % root.rows
            readonly property int column: Math.floor(tile.index / root.rows)

            x: root.gridX + (root.alignRight ? root.columns - 1 - tile.column : tile.column) * root.cellWidth
            y: root.gridY + tile.row * root.cellHeight
            width: root.tileWidth
            height: root.tileHeight
            radius: Tokens.rounding.medium
            color: hover.containsMouse ? Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.55) : "transparent"

            Column {
                anchors.centerIn: parent
                spacing: root.spacing

                IconImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    asynchronous: true
                    implicitSize: root.iconSize
                    source: Quickshell.iconPath(tile.modelData.icon, "application-x-executable")
                }

                StyledText {
                    visible: root.showLabels
                    width: root.tileWidth - Tokens.padding.medium * 2
                    height: root.labelHeight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignTop
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                    text: tile.modelData.name
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.label.medium
                    style: Text.Outline
                    styleColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
                }
            }

            MouseArea {
                id: hover

                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor

                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton)
                        Desktop.launch(tile.modelData);
                    else
                        root.contextMenuRequested(tile.modelData, mouse.x + tile.x, mouse.y + tile.y);
                }
            }
        }
    }
}
