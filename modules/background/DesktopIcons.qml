pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.services
import qs.utils

// Application shortcuts, folders and files from the user's desktop folder,
// laid out in columns from the configured corner. Purely pointer driven: the
// background layer never takes keyboard focus, so using the desktop cannot pull
// focus from a window.
Item {
    id: root

    required property ShellScreen screen

    readonly property var iconsConfig: Config.background.desktopIcons

    // Height of the desktop clock, used to keep the icons off it when both sit
    // on the same side of the screen.
    property real clockHeight: 0

    readonly property string position: ["top-left", "top-right", "bottom-left", "bottom-right"].includes(root.iconsConfig.position) ? root.iconsConfig.position : "top-right"
    readonly property bool showLabels: root.iconsConfig.showLabels
    readonly property int iconSize: root.iconsConfig.iconSize

    readonly property bool alignRight: root.position.endsWith("right")
    readonly property bool alignBottom: root.position.startsWith("bottom")

    // The bar floats over the wallpaper, so leave room for it on whichever edge
    // it occupies. These mirror BarWrapper's content thickness.
    readonly property var barRef: ShellState.componentsFor(root.screen)?.bar
    readonly property bool barHorizontal: Config.bar.position === "top" || Config.bar.position === "bottom"
    // Prefer the bar's real size; the fallback mirrors BarWrapper's formula.
    readonly property real barThickness: root.barRef?.contentThickness ?? (root.barHorizontal ? Tokens.sizes.bar.horizontalInnerWidth + Tokens.padding.extraSmall * 2 : Tokens.sizes.bar.innerWidth + Math.max(Tokens.padding.small, Config.border.thickness) * 2)
    readonly property real edgeMargin: Tokens.padding.largeIncreased
    readonly property bool clockOnSameSide: {
        const icons = root.position;
        const clock = Config.background.desktopClock.position;
        return (icons.endsWith("right") && clock.endsWith("right")) || (icons.endsWith("left") && clock.endsWith("left"));
    }
    readonly property real clockReserve: Config.background.desktopClock.enabled && root.clockOnSameSide && root.clockHeight > 0 ? root.clockHeight + Tokens.padding.extraLargeIncreased + Tokens.padding.large : 0
    readonly property real topReserve: root.clockReserve > 0 && Config.background.desktopClock.position.startsWith("top") ? root.clockReserve : 0
    readonly property real bottomReserve: root.clockReserve > 0 && Config.background.desktopClock.position.startsWith("bottom") ? root.clockReserve : 0
    readonly property real marginLeft: root.edgeMargin + (Config.bar.position === "left" ? root.barThickness : 0)
    readonly property real marginRight: root.edgeMargin + (Config.bar.position === "right" ? root.barThickness : 0)
    // The icon glyph carries a little transparent padding above it, which makes
    // the optical gap under a top bar look larger than the side gaps.
    readonly property real topOpticalInset: 4
    readonly property real topInset: root.edgeMargin + (Config.bar.position === "top" ? Math.max(0, root.barThickness - root.topOpticalInset) : 0)
    readonly property real bottomInset: root.edgeMargin + (Config.bar.position === "bottom" ? root.barThickness : 0)
    // The clock reserve already contains the screen-edge gap; take whichever
    // inset is larger instead of stacking the bar and clock padding.
    readonly property real marginTop: Math.max(root.topInset, root.topReserve)
    readonly property real marginBottom: Math.max(root.bottomInset, root.bottomReserve)

    readonly property real spacing: Tokens.spacing.small
    readonly property int tilePadding: Tokens.padding.small
    readonly property real labelHeight: root.showLabels ? Math.ceil(labelMetrics.height) : 0
    readonly property real tileWidth: Math.max(root.iconSize + root.tilePadding * 2, 112)
    readonly property real tileHeight: root.iconSize + (root.showLabels ? root.spacing + root.labelHeight : 0) + root.tilePadding * 2
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

    // Paths in display order. A drag overrides the saved order until it is dropped.
    readonly property var orderPaths: {
        if (root.dragging && root.dragOrder.length > 0)
            return root.dragOrder;

        const configured = root.iconsConfig.order ?? [];
        const entries = icons.entries;
        const list = [];
        for (let i = 0; i < entries.length; ++i)
            list.push(entries[i]);

        list.sort((a, b) => {
            const ai = configured.indexOf(a.path);
            const bi = configured.indexOf(b.path);
            const ar = ai < 0 ? Number.MAX_SAFE_INTEGER : ai;
            const br = bi < 0 ? Number.MAX_SAFE_INTEGER : bi;
            if (ar !== br)
                return ar - br;

            const af = a.kind === "folder" ? 0 : 1;
            const bf = b.kind === "folder" ? 0 : 1;
            if (af !== bf)
                return af - bf;

            const an = a.name.toLowerCase();
            const bn = b.name.toLowerCase();
            return an < bn ? -1 : an > bn ? 1 : 0;
        });

        return list.map(entry => entry.path);
    }

    readonly property var orderMap: {
        const map = {};
        const paths = root.orderPaths;
        for (let i = 0; i < paths.length; ++i)
            map[paths[i]] = i;
        return map;
    }

    // Drag state
    property bool dragging: false
    property string dragPath: ""
    property var dragOrder: []
    property real dragStartX: 0
    property real dragStartY: 0
    property real dragX: 0
    property real dragY: 0
    property bool dragMoved: false

    // Emitted for a right click on an icon. The desktop context menu can connect
    // to this without the icon grid needing to know about it.
    signal contextMenuRequested(entry: var, x: real, y: real)

    function displayIndex(path: string): int {
        const index = root.orderMap[path];
        return index === undefined ? 0 : index;
    }

    function targetIndexAt(x: real, y: real): int {
        if (root.count === 0)
            return -1;

        const column = Math.max(0, Math.min(root.columns - 1, Math.floor((x - root.gridX) / root.cellWidth)));
        const row = Math.max(0, Math.min(root.rows - 1, Math.floor((y - root.gridY) / root.cellHeight)));
        const logicalColumn = root.alignRight ? root.columns - 1 - column : column;
        return Math.max(0, Math.min(root.count - 1, logicalColumn * root.rows + row));
    }

    function beginDrag(path: string, x: real, y: real): void {
        if (root.count < 2)
            return;

        root.dragMoved = false;
        root.dragPath = path;
        root.dragStartX = x;
        root.dragStartY = y;
        root.dragX = x;
        root.dragY = y;
        root.dragging = false;
        root.dragOrder = root.orderPaths.slice();
    }

    function updateDrag(x: real, y: real): void {
        if (root.dragPath === "")
            return;

        root.dragX = x;
        root.dragY = y;

        if (!root.dragging) {
            const dx = x - root.dragStartX;
            const dy = y - root.dragStartY;
            if (dx * dx + dy * dy < 36)
                return;

            root.dragging = true;
        }

        const target = root.targetIndexAt(x, y);
        const current = root.dragOrder.indexOf(root.dragPath);
        if (current < 0 || target < 0 || target === current)
            return;

        const next = root.dragOrder.slice();
        const moved = next.splice(current, 1)[0];
        next.splice(target, 0, moved);
        root.dragOrder = next;
    }

    function finishDrag(): void {
        const wasDragging = root.dragging;
        if (wasDragging && root.dragPath !== "")
            GlobalConfig.background.desktopIcons.order = root.dragOrder.slice();

        root.dragMoved = wasDragging;
        root.dragging = false;
        root.dragPath = "";
        root.dragOrder = [];
    }

    function cancelDrag(): void {
        root.dragMoved = root.dragging;
        root.dragging = false;
        root.dragPath = "";
        root.dragOrder = [];
    }

    function acceptDrop(drop: var): void {
        if (!drop.hasUrls)
            return;

        const paths = [];
        for (const url of drop.urls) {
            const path = Paths.toLocalFile(url);
            if (path !== "" && paths.indexOf(path) < 0)
                paths.push(path);
        }

        if (paths.length === 0)
            return;

        // Symlink instead of copying, so dropping a large file or directory is
        // instant and the original is never touched. Existing names get a
        // numbered link rather than replacing anything.
        Quickshell.execDetached(["sh", "-c", `dir=$1
shift
for src in "$@"; do
    [ -e "$src" ] || [ -L "$src" ] || continue
    [ "$(dirname -- "$src")" = "$dir" ] && continue
    base=$(basename -- "$src")
    dest="$dir/$base"
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        n=2
        while [ -e "$dir/$base ($n)" ] || [ -L "$dir/$base ($n)" ]; do
            n=$((n + 1))
        done
        dest="$dir/$base ($n)"
    fi
    ln -s -- "$src" "$dest"
done`, "sh", Paths.desktop, ...paths]);
    }

    anchors.fill: parent

    TextMetrics {
        id: labelMetrics

        font: Tokens.font.label.medium
        text: "Ag"
    }

    DesktopFileModel {
        id: icons

        path: Paths.desktop
        showFiles: root.iconsConfig.showFiles
        watchChanges: true
    }

    DropArea {
        anchors.fill: parent
        keys: ["text/uri-list"]

        onEntered: drag => drag.accept(Qt.CopyAction)
        onDropped: drop => root.acceptDrop(drop)
    }

    Repeater {
        model: icons.entries

        StyledRect {
            id: tile

            required property DesktopFile modelData
            required property int index

            readonly property int placedIndex: root.displayIndex(tile.modelData.path)
            readonly property bool isDragged: root.dragging && root.dragPath === tile.modelData.path
            readonly property int row: tile.placedIndex % root.rows
            readonly property int column: Math.floor(tile.placedIndex / root.rows)
            readonly property real layoutX: root.gridX + (root.alignRight ? root.columns - 1 - tile.column : tile.column) * root.cellWidth
            readonly property real layoutY: root.gridY + tile.row * root.cellHeight

            x: tile.isDragged ? root.dragX - tile.width / 2 : tile.layoutX
            y: tile.isDragged ? root.dragY - tile.height / 2 : tile.layoutY
            z: tile.isDragged ? 100 : 0
            width: root.tileWidth
            height: root.tileHeight
            radius: Tokens.rounding.medium
            scale: tile.isDragged ? 1.05 : 1
            opacity: tile.isDragged ? 0.9 : 1
            color: hover.containsMouse || tile.isDragged ? Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.55) : "transparent"

            Behavior on x {
                enabled: !tile.isDragged

                Anim {
                    type: Anim.FastEffects
                }
            }

            Behavior on y {
                enabled: !tile.isDragged

                Anim {
                    type: Anim.FastEffects
                }
            }

            Behavior on scale {
                Anim {
                    type: Anim.FastEffects
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.FastEffects
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: root.spacing

                IconImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    asynchronous: true
                    implicitSize: root.iconSize
                    source: Quickshell.iconPath(tile.modelData.icon, tile.modelData.kind === "folder" ? "folder" : "text-x-generic")
                }

                Item {
                    width: root.tileWidth - root.tilePadding * 2
                    height: root.showLabels ? root.labelHeight : 0
                    visible: root.showLabels

                    StyledText {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 2
                        width: parent.width
                        height: parent.height
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        wrapMode: Text.NoWrap
                        text: tile.modelData.name
                        renderType: Text.QtRendering
                        color: Qt.alpha(Colours.palette.m3shadow, 0.45)
                        font: Tokens.font.label.medium
                    }

                    StyledText {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 1
                        width: parent.width
                        height: parent.height
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        wrapMode: Text.NoWrap
                        text: tile.modelData.name
                        renderType: Text.QtRendering
                        color: Qt.alpha(Colours.palette.m3shadow, 0.9)
                        font: Tokens.font.label.medium
                    }

                    StyledText {
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        wrapMode: Text.NoWrap
                        text: tile.modelData.name
                        renderType: Text.QtRendering
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.label.medium
                    }
                }
            }

            MouseArea {
                id: hover

                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor

                onPressed: mouse => {
                    if (mouse.button !== Qt.LeftButton)
                        return;

                    const point = hover.mapToItem(root, mouse.x, mouse.y);
                    root.beginDrag(tile.modelData.path, point.x, point.y);
                }
                onPositionChanged: mouse => {
                    if (root.dragPath !== tile.modelData.path || !(mouse.buttons & Qt.LeftButton))
                        return;

                    const point = hover.mapToItem(root, mouse.x, mouse.y);
                    root.updateDrag(point.x, point.y);
                }
                onReleased: mouse => {
                    if (mouse.button === Qt.LeftButton && root.dragPath === tile.modelData.path)
                        root.finishDrag();
                }
                onCanceled: {
                    if (root.dragPath === tile.modelData.path)
                        root.cancelDrag();
                }
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        root.contextMenuRequested(tile.modelData, mouse.x + tile.x, mouse.y + tile.y);
                        return;
                    }

                    if (root.dragMoved) {
                        root.dragMoved = false;
                        return;
                    }

                    Desktop.launch(tile.modelData);
                }
            }
        }
    }
}
