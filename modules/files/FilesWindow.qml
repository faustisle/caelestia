pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Models
import Caelestia.Multimedia
import qs.components
import qs.components.controls
import qs.services
import qs.utils

FloatingWindow {
    id: root

    property string startPath: ""
    property string currentPath: ""
    property var history: []
    property int historyIndex: -1
    property bool showHidden: false
    property bool editingLocation: false
    property var selectedPaths: ({})
    property int anchorIndex: -1
    property string promptMode: ""
    property var promptEntries: []
    property bool deleteDialogOpen: false
    property var deleteEntries: []
    property bool deletePermanent: false

    readonly property bool canGoBack: historyIndex > 0
    readonly property bool canGoForward: historyIndex >= 0 && historyIndex < history.length - 1
    readonly property real iconScale: Files.iconScale
    readonly property real minIconScale: Files.minIconScale
    readonly property real maxIconScale: Files.maxIconScale
    readonly property real iconSide: Math.round(64 * root.iconScale)
    readonly property real tileWidth: Math.max(96, root.iconSide + 48)
    readonly property real tileHeight: root.iconSide + 68
    readonly property string parentPath: {
        if (!currentPath || currentPath === "/")
            return "/";
        const trimmed = currentPath.endsWith("/") ? currentPath.slice(0, -1) : currentPath;
        const slash = trimmed.lastIndexOf("/");
        return slash <= 0 ? "/" : trimmed.slice(0, slash);
    }
    readonly property string folderName: {
        if (!currentPath)
            return "";
        if (currentPath === "/")
            return "/";
        const trimmed = currentPath.endsWith("/") ? currentPath.slice(0, -1) : currentPath;
        return trimmed.slice(trimmed.lastIndexOf("/") + 1);
    }

    function entryList(): var {
        const result = [];
        const entries = directory.entries;
        for (let i = 0; i < entries.length; ++i)
            result.push(entries[i]);
        return result;
    }

    function entryAt(index: int): var {
        const entries = directory.entries;
        return index >= 0 && index < entries.length ? entries[index] : null;
    }

    function isSelected(path: string): bool {
        return root.selectedPaths[path] === true;
    }

    function selectedEntries(): var {
        return root.entryList().filter(entry => root.isSelected(entry.path));
    }

    function navigate(path: string, addHistory = true): void {
        const target = Files.resolvePath(path);
        if (!target)
            return;

        if (addHistory) {
            const next = root.history.slice(0, root.historyIndex + 1);
            if (next[next.length - 1] !== target)
                next.push(target);
            root.history = next;
            root.historyIndex = next.length - 1;
        } else {
            root.history = [target];
            root.historyIndex = 0;
        }

        root.currentPath = target;
        root.clearSelection();
        root.finishLocationEdit(false);
        context.close();
    }

    function goBack(): void {
        if (!root.canGoBack)
            return;
        root.historyIndex -= 1;
        root.currentPath = root.history[root.historyIndex];
        root.clearSelection();
        root.finishLocationEdit(false);
    }

    function goForward(): void {
        if (!root.canGoForward)
            return;
        root.historyIndex += 1;
        root.currentPath = root.history[root.historyIndex];
        root.clearSelection();
        root.finishLocationEdit(false);
    }

    function goUp(): void {
        if (root.currentPath !== "/")
            root.navigate(root.parentPath);
    }

    function openEntry(entry): void {
        if (!entry)
            return;
        if (entry.isDir)
            root.navigate(entry.path);
        else
            Files.openPath(entry.path);
    }

    function activateCurrent(): void {
        const entry = root.entryAt(grid.currentIndex);
        if (entry)
            root.openEntry(entry);
    }

    function clearSelection(): void {
        root.selectedPaths = ({});
        root.anchorIndex = -1;
        grid.currentIndex = -1;
    }

    function selectOnly(index: int, path: string): void {
        const selection = {};
        selection[path] = true;
        root.selectedPaths = selection;
        root.anchorIndex = index;
        grid.currentIndex = index;
    }

    function toggleSelection(index: int, path: string): void {
        const selection = Object.assign({}, root.selectedPaths);
        if (selection[path])
            delete selection[path];
        else
            selection[path] = true;
        root.selectedPaths = selection;
        root.anchorIndex = index;
        grid.currentIndex = index;
    }

    function selectRange(index: int): void {
        if (root.anchorIndex < 0) {
            root.selectOnly(index, root.entryAt(index)?.path ?? "");
            return;
        }

        const start = Math.min(root.anchorIndex, index);
        const end = Math.max(root.anchorIndex, index);
        const selection = {};
        for (let i = start; i <= end; ++i) {
            const entry = root.entryAt(i);
            if (entry)
                selection[entry.path] = true;
        }
        root.selectedPaths = selection;
        grid.currentIndex = index;
    }

    function selectAll(): void {
        const selection = {};
        for (const entry of root.entryList())
            selection[entry.path] = true;
        root.selectedPaths = selection;
        grid.forceActiveFocus();
    }

    function pruneSelection(): void {
        const selection = {};
        for (const entry of root.entryList()) {
            if (root.selectedPaths[entry.path])
                selection[entry.path] = true;
        }
        root.selectedPaths = selection;
        if (grid.currentIndex >= directory.entries.length)
            grid.currentIndex = -1;
    }

    function copySelection(cut: bool): void {
        const entries = root.selectedEntries();
        if (entries.length === 0)
            return;
        Files.copy(entries.map(entry => entry.path), cut);
    }

    function paste(): void {
        if (Files.hasClipboard)
            Files.paste(root.currentPath);
    }

    function requestDelete(permanent: bool): void {
        const entries = root.selectedEntries();
        if (entries.length === 0)
            return;
        root.openDeleteDialog(entries, permanent);
    }

    function openDeleteDialog(entries: var, permanent: bool): void {
        root.deleteEntries = entries;
        root.deletePermanent = permanent;
        Qt.callLater(() => root.deleteDialogOpen = true);
    }

    function confirmDelete(): void {
        const paths = root.deleteEntries.map(entry => entry.path);
        if (root.deletePermanent)
            Files.deletePermanently(paths);
        else
            Files.trash(paths);
        root.deleteDialogOpen = false;
        root.deleteEntries = [];
        Qt.callLater(() => grid.forceActiveFocus());
    }

    function requestPrompt(mode: string, entries: var, initial: string): void {
        root.promptMode = mode;
        root.promptEntries = entries ?? [];

        let title = "";
        let acceptLabel = "";
        let placeholder = Tr.tr("Name");
        switch (mode) {
        case "newFolder":
            title = Tr.tr("New Folder");
            acceptLabel = Tr.tr("Create");
            break;
        case "newFile":
            title = Tr.tr("New File");
            acceptLabel = Tr.tr("Create");
            break;
        case "rename":
            title = Tr.tr("Rename");
            acceptLabel = Tr.tr("Rename");
            break;
        case "compress":
            title = Tr.tr("Compress to ZIP");
            acceptLabel = Tr.tr("Compress");
            placeholder = Tr.tr("Archive name");
            break;
        case "extract":
            title = Tr.tr("Extract to Folder");
            acceptLabel = Tr.tr("Extract");
            placeholder = Tr.tr("Folder name");
            break;
        }

        namePrompt.open(title, initial, acceptLabel, placeholder);
    }

    function handlePrompt(name: string): void {
        switch (root.promptMode) {
        case "newFolder":
            Files.createFolder(root.currentPath, name);
            break;
        case "newFile":
            Files.createFile(root.currentPath, name);
            break;
        case "rename":
            if (root.promptEntries.length > 0)
                Files.renameEntry(root.promptEntries[0].path, name);
            break;
        case "compress":
            Files.compress(root.promptEntries.map(entry => entry.path), root.currentPath, name);
            break;
        case "extract":
            if (root.promptEntries.length > 0)
                Files.extract(root.promptEntries[0].path, root.currentPath, name);
            break;
        }
        root.promptEntries = [];
        grid.forceActiveFocus();
    }

    function requestRename(): void {
        const entries = root.selectedEntries();
        if (entries.length === 1)
            root.requestPrompt("rename", entries, entries[0].name);
    }

    function focusLocation(): void {
        if (contentRoot.modalOpen)
            return;
        root.editingLocation = true;
        Qt.callLater(() => {
            locationField.text = root.currentPath;
            locationField.forceActiveFocus();
            locationField.select(0, locationField.length);
        });
    }

    function finishLocationEdit(focusGrid = true): void {
        if (!root.editingLocation)
            return;
        root.editingLocation = false;
        if (focusGrid)
            Qt.callLater(() => grid.forceActiveFocus());
    }

    function openBackgroundContext(x: real, y: real): void {
        root.clearSelection();
        context.open(x, y, []);
        grid.forceActiveFocus();
    }

    function setIconScale(value: real): void {
        Files.setIconScale(value);
    }

    function zoomIn(): void {
        root.setIconScale(root.iconScale * 1.3);
    }

    function zoomOut(): void {
        root.setIconScale(root.iconScale / 1.3);
    }

    function resetZoom(): void {
        root.setIconScale(1);
    }

    function openEntryContext(entry, index: int, x: real, y: real): void {
        if (!root.isSelected(entry.path))
            root.selectOnly(index, entry.path);
        context.open(x, y, root.selectedEntries());
    }

    function folderIcon(entry): string {
        const icons = {
            Documents: "folder-documents",
            Downloads: "folder-download",
            Music: "folder-music",
            Pictures: "folder-pictures",
            Videos: "folder-videos",
            Public: "folder-publicshare",
            Templates: "folder-templates"
        };
        return Quickshell.iconPath(entry.isDir ? (icons[entry.name] ?? "inode-directory") : "inode-directory", "inode-directory");
    }

    function folderBadge(entry): string {
        if (!entry.isDir)
            return "";
        if (entry.name === "Desktop")
            return "desktop_windows";
        return "";
    }

    function fileIcon(entry): string {
        if (entry.isDir)
            return root.folderIcon(entry);
        return Quickshell.iconPath(entry.mimeType.replace("/", "-"), "application-x-zerosize");
    }

    function currentFolderEntry(): var {
        return {
            name: root.folderName,
            path: root.currentPath,
            parentDir: root.parentPath,
            isDir: true,
            size: 0,
            suffix: "",
            baseName: root.folderName,
            mimeType: "inode/directory"
        };
    }

    function formatSize(bytes: real): string {
        if (bytes < 1024)
            return `${Math.round(bytes)} B`;
        if (bytes < 1024 * 1024)
            return `${(bytes / 1024).toFixed(1)} KiB`;
        if (bytes < 1024 * 1024 * 1024)
            return `${(bytes / (1024 * 1024)).toFixed(1)} MiB`;
        return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GiB`;
    }

    visible: true
    implicitWidth: 1120
    implicitHeight: 720
    minimumSize.width: 640
    minimumSize.height: 420
    color: Colours.tPalette.m3surfaceContainer
    surfaceFormat.opaque: true
    title: Tr.tr("Files — %1").arg(root.folderName || Tr.tr("Files"))

    onVisibleChanged: {
        if (!visible)
            destroy();
    }
    Component.onCompleted: {
        root.navigate(root.startPath || Paths.home, false);
        Qt.callLater(() => grid.forceActiveFocus());
    }

    FileSystemModel {
        id: directory

        path: root.currentPath
        showHidden: root.showHidden
        watchChanges: true

        onEntriesChanged: root.pruneSelection()
    }

    FocusScope {
        id: contentRoot

        readonly property bool modalOpen: root.deleteDialogOpen || namePrompt.opened || propertiesDialog.opened || appChooser.opened

        property bool rubberBandActive: false
        property bool rubberBandMoved: false
        property bool rubberBandAdditive: false
        property var rubberBandBase: ({})
        property real rubberBandStartX: 0
        property real rubberBandStartY: 0
        property real rubberBandEndX: 0
        property real rubberBandEndY: 0
        readonly property real rubberBandX: Math.min(contentRoot.rubberBandStartX, contentRoot.rubberBandEndX)
        readonly property real rubberBandY: Math.min(contentRoot.rubberBandStartY, contentRoot.rubberBandEndY)
        readonly property real rubberBandWidth: Math.abs(contentRoot.rubberBandEndX - contentRoot.rubberBandStartX)
        readonly property real rubberBandHeight: Math.abs(contentRoot.rubberBandEndY - contentRoot.rubberBandStartY)

        function startRubberBand(x: real, y: real, modifiers: int): void {
            contentRoot.rubberBandActive = true;
            contentRoot.rubberBandMoved = false;
            contentRoot.rubberBandAdditive = (modifiers & (Qt.ControlModifier | Qt.ShiftModifier)) !== 0;
            contentRoot.rubberBandBase = contentRoot.rubberBandAdditive ? Object.assign({}, root.selectedPaths) : ({});
            contentRoot.rubberBandStartX = x;
            contentRoot.rubberBandStartY = y;
            contentRoot.rubberBandEndX = x;
            contentRoot.rubberBandEndY = y;
            if (!contentRoot.rubberBandAdditive)
                root.clearSelection();
        }

        function updateRubberBand(x: real, y: real): void {
            if (!contentRoot.rubberBandActive)
                return;

            contentRoot.rubberBandEndX = x;
            contentRoot.rubberBandEndY = y;
            if (Math.abs(x - contentRoot.rubberBandStartX) > 4 || Math.abs(y - contentRoot.rubberBandStartY) > 4)
                contentRoot.rubberBandMoved = true;

            const left = contentRoot.rubberBandX;
            const top = contentRoot.rubberBandY;
            const right = left + contentRoot.rubberBandWidth;
            const bottom = top + contentRoot.rubberBandHeight;
            const selection = Object.assign({}, contentRoot.rubberBandAdditive ? contentRoot.rubberBandBase : {});

            for (let i = 0; i < directory.entries.length; ++i) {
                const item = grid.itemAtIndex(i);
                if (!item)
                    continue;

                const position = item.mapToItem(contentCard, 0, 0);
                if (position.x + item.width < left || position.x > right)
                    continue;
                if (position.y + item.height < top || position.y > bottom)
                    continue;

                const entry = root.entryAt(i);
                if (entry)
                    selection[entry.path] = true;
            }

            root.selectedPaths = selection;
        }

        function endRubberBand(): void {
            contentRoot.rubberBandActive = false;
            if (!contentRoot.rubberBandMoved)
                root.clearSelection();
            grid.forceActiveFocus();
        }

        function openKeyboardContext(): void {
            const entries = root.selectedEntries();
            if (entries.length === 0) {
                const current = root.entryAt(grid.currentIndex);
                if (current)
                    entries.push(current);
            }
            const position = contentCard.mapToItem(contentRoot, contentCard.width / 2, contentCard.height / 2);
            context.open(position.x, position.y, entries);
        }

        anchors.fill: parent
        focus: true

        Shortcut {
            sequence: "Ctrl+L"
            enabled: !contentRoot.modalOpen
            onActivated: root.focusLocation()
        }
        Shortcut {
            sequence: "Shift+F10"
            enabled: !contentRoot.modalOpen && !root.editingLocation
            onActivated: contentRoot.openKeyboardContext()
        }
        Shortcut {
            sequence: "Ctrl+="
            enabled: !contentRoot.modalOpen
            onActivated: root.zoomIn()
        }
        Shortcut {
            sequence: "Ctrl+-"
            enabled: !contentRoot.modalOpen
            onActivated: root.zoomOut()
        }
        Shortcut {
            sequence: "Ctrl+0"
            enabled: !contentRoot.modalOpen
            onActivated: root.resetZoom()
        }
        Shortcut {
            sequence: "Ctrl+H"
            enabled: !contentRoot.modalOpen && !root.editingLocation
            onActivated: root.showHidden = !root.showHidden
        }
        Shortcut {
            sequence: "Ctrl+A"
            enabled: !contentRoot.modalOpen && !root.editingLocation
            onActivated: root.selectAll()
        }
        Shortcut {
            sequence: "Ctrl+C"
            enabled: !contentRoot.modalOpen && !root.editingLocation
            onActivated: root.copySelection(false)
        }
        Shortcut {
            sequence: "Ctrl+X"
            enabled: !contentRoot.modalOpen && !root.editingLocation
            onActivated: root.copySelection(true)
        }
        Shortcut {
            sequence: "Ctrl+V"
            enabled: !contentRoot.modalOpen && !root.editingLocation
            onActivated: root.paste()
        }
        Shortcut {
            sequence: "Ctrl+Shift+N"
            enabled: !contentRoot.modalOpen && !root.editingLocation
            onActivated: root.requestPrompt("newFolder", [], Tr.tr("New Folder"))
        }
        Shortcut {
            sequence: "Ctrl+N"
            enabled: !contentRoot.modalOpen && !root.editingLocation
            onActivated: Files.open(root.currentPath)
        }
        Shortcut {
            sequence: "Ctrl+W"
            enabled: !contentRoot.modalOpen
            onActivated: root.visible = false
        }
        Shortcut {
            sequence: "F2"
            enabled: !contentRoot.modalOpen && !root.editingLocation
            onActivated: root.requestRename()
        }
        Shortcut {
            sequence: "Delete"
            enabled: !contentRoot.modalOpen && !root.editingLocation
            onActivated: root.requestDelete(false)
        }
        Shortcut {
            sequence: "Shift+Delete"
            enabled: !contentRoot.modalOpen && !root.editingLocation
            onActivated: root.requestDelete(true)
        }
        Shortcut {
            sequence: "Alt+Left"
            enabled: !contentRoot.modalOpen
            onActivated: root.goBack()
        }
        Shortcut {
            sequence: "Alt+Right"
            enabled: !contentRoot.modalOpen
            onActivated: root.goForward()
        }
        Shortcut {
            sequence: "Alt+Up"
            enabled: !contentRoot.modalOpen
            onActivated: root.goUp()
        }
        Shortcut {
            sequence: "Backspace"
            enabled: !contentRoot.modalOpen && !root.editingLocation
            onActivated: root.goUp()
        }
        Shortcut {
            sequence: "Escape"
            enabled: !contentRoot.modalOpen && !root.editingLocation
            onActivated: {
                if (context.opened)
                    context.close();
                else
                    root.clearSelection();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            StyledRect {
                Layout.fillWidth: true

                implicitHeight: toolbarRow.implicitHeight + Tokens.padding.medium * 2
                color: Colours.tPalette.m3surfaceContainer

                RowLayout {
                    id: toolbarRow

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    spacing: Tokens.spacing.small

                    IconButton {
                        icon: "arrow_back"
                        type: IconButton.Text
                        enabled: root.canGoBack
                        onClicked: root.goBack()
                    }

                    IconButton {
                        icon: "arrow_forward"
                        type: IconButton.Text
                        enabled: root.canGoForward
                        onClicked: root.goForward()
                    }

                    IconButton {
                        icon: "drive_folder_upload"
                        type: IconButton.Text
                        enabled: root.currentPath !== "/"
                        onClicked: root.goUp()
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        StyledRect {
                            anchors.fill: parent
                            visible: !root.editingLocation

                            radius: Tokens.rounding.medium
                            color: Colours.tPalette.m3surfaceContainerHigh

                            StateLayer {
                                onClicked: root.focusLocation()
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Tokens.padding.medium
                                anchors.rightMargin: Tokens.padding.medium
                                spacing: Tokens.spacing.small

                                MaterialIcon {
                                    text: "folder"
                                    color: Colours.palette.m3onSurfaceVariant
                                    fontStyle: Tokens.font.icon.small
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: Paths.shortenHome(root.currentPath)
                                    color: Colours.palette.m3onSurface
                                    font: Tokens.font.body.small
                                    elide: Text.ElideMiddle
                                }
                            }
                        }

                        StyledTextField {
                            id: locationField

                            anchors.fill: parent
                            visible: root.editingLocation
                            type: StyledTextField.Filled
                            verticalPadding: Tokens.padding.extraSmall
                            horizontalPadding: Tokens.padding.small
                            leadingIcon: "folder"
                            font: Tokens.font.body.small

                            onAccepted: {
                                root.navigate(locationField.text);
                                root.finishLocationEdit();
                            }
                            onActiveFocusChanged: {
                                if (!activeFocus && root.editingLocation)
                                    root.finishLocationEdit();
                            }
                            Keys.onEscapePressed: root.finishLocationEdit()
                        }
                    }

                    IconButton {
                        icon: "zoom_out"
                        type: IconButton.Text
                        enabled: root.iconScale > root.minIconScale
                        onClicked: root.zoomOut()
                    }

                    IconButton {
                        icon: "zoom_in"
                        type: IconButton.Text
                        enabled: root.iconScale < root.maxIconScale
                        onClicked: root.zoomIn()
                    }

                    IconButton {
                        icon: "create_new_folder"
                        type: IconButton.Text
                        onClicked: root.requestPrompt("newFolder", [], Tr.tr("New Folder"))
                    }

                    IconButton {
                        icon: root.showHidden ? "visibility_off" : "visibility"
                        type: IconButton.Text
                        onClicked: root.showHidden = !root.showHidden
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                FilesSidebar {
                    Layout.preferredWidth: 230
                    Layout.fillHeight: true
                    currentPath: root.currentPath
                    onNavigate: path => root.navigate(path)
                }

                Item {
                    id: viewContainer

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    StyledRect {
                        id: contentCard

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.large

                        radius: Tokens.rounding.large
                        color: Colours.tPalette.m3surface
                        clip: true
                    }

                    MouseArea {
                        anchors.fill: contentCard
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onPressed: mouse => {
                            if (mouse.button === Qt.LeftButton)
                                contentRoot.startRubberBand(mouse.x, mouse.y, mouse.modifiers);
                        }
                        onPositionChanged: mouse => {
                            if (contentRoot.rubberBandActive && (mouse.buttons & Qt.LeftButton))
                                contentRoot.updateRubberBand(mouse.x, mouse.y);
                        }
                        onReleased: mouse => {
                            if (mouse.button === Qt.LeftButton && contentRoot.rubberBandActive)
                                contentRoot.endRubberBand();
                        }
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                const pos = contentCard.mapToItem(contentRoot, mouse.x, mouse.y);
                                root.openBackgroundContext(pos.x, pos.y);
                            }
                        }
                        onWheel: wheel => {
                            if (wheel.modifiers & Qt.ControlModifier) {
                                if (wheel.angleDelta.y > 0)
                                    root.zoomIn();
                                else if (wheel.angleDelta.y < 0)
                                    root.zoomOut();
                                wheel.accepted = true;
                            }
                        }
                    }

                    GridView {
                        id: grid

                        anchors.fill: contentCard
                        anchors.margins: Tokens.padding.large

                        cellWidth: root.tileWidth
                        cellHeight: root.tileHeight
                        clip: true
                        focus: true
                        currentIndex: -1
                        interactive: false

                        model: directory
                        delegate: FileTile {}

                        StyledScrollBar.vertical: StyledScrollBar {
                            flickable: grid
                        }

                        Keys.onReturnPressed: root.activateCurrent()
                        Keys.onEnterPressed: root.activateCurrent()
                        Keys.onEscapePressed: root.clearSelection()
                        Keys.onPressed: event => {
                            const isArrow = event.key === Qt.Key_Left || event.key === Qt.Key_Right || event.key === Qt.Key_Up || event.key === Qt.Key_Down;
                            if (isArrow) {
                                Qt.callLater(() => {
                                    const entry = root.entryAt(grid.currentIndex);
                                    if (entry)
                                        root.selectOnly(grid.currentIndex, entry.path);
                                });
                            }
                        }

                        WheelHandler {
                            acceptedModifiers: Qt.ControlModifier
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: wheel => {
                                if (wheel.angleDelta.y > 0)
                                    root.zoomIn();
                                else if (wheel.angleDelta.y < 0)
                                    root.zoomOut();
                                wheel.accepted = true;
                            }
                        }

                        WheelHandler {
                            acceptedModifiers: Qt.NoModifier
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: wheel => {
                                const delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y * 3;
                                grid.contentY = Math.max(0, Math.min(grid.contentHeight - grid.height, grid.contentY - delta));
                                wheel.accepted = true;
                            }
                        }
                    }

                    Rectangle {
                        parent: contentCard
                        z: 10
                        visible: contentRoot.rubberBandActive
                        x: contentRoot.rubberBandX
                        y: contentRoot.rubberBandY
                        width: contentRoot.rubberBandWidth
                        height: contentRoot.rubberBandHeight
                        color: Qt.alpha(Colours.palette.m3primary, 0.14)
                        border.width: 1
                        border.color: Colours.palette.m3primary
                        radius: Tokens.rounding.extraSmall
                    }

                    StyledText {
                        anchors.centerIn: contentCard
                        visible: grid.count === 0
                        text: Tr.tr("This folder is empty")
                        color: Colours.palette.m3outline
                        font: Tokens.font.body.large
                    }
                }
            }
        }

        FileContextMenu {
            id: context

            currentPath: root.currentPath
            onOpenRequested: entry => root.openEntry(entry)
            onPromptRequested: (mode, entries, initial) => root.requestPrompt(mode, entries, initial)
            onPropertiesRequested: entries => propertiesDialog.open(entries.length > 0 ? entries : [root.currentFolderEntry()])
            onOpenWithRequested: entry => appChooser.open(entry.path)
            onConfirmDeleteRequested: (entries, permanent) => root.openDeleteDialog(entries, permanent)
            onSelectAllRequested: root.selectAll()
            onToggleHiddenRequested: root.showHidden = !root.showHidden
            onClosed: grid.forceActiveFocus()
        }

        NamePrompt {
            id: namePrompt

            onAccepted: name => root.handlePrompt(name)
            onRejected: grid.forceActiveFocus()
        }

        PropertiesDialog {
            id: propertiesDialog
        }

        AppChooserDialog {
            id: appChooser
        }

        Item {
            id: deleteDialog

            anchors.fill: parent
            visible: root.deleteDialogOpen
            z: 5000

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha("black", 0.45)
            }

            MouseArea {
                anchors.fill: parent
                onPressed: root.deleteDialogOpen = false
            }

            StyledRect {
                anchors.centerIn: parent
                width: 420
                implicitHeight: deleteContent.implicitHeight + Tokens.padding.large * 2

                radius: Tokens.rounding.large
                color: Colours.palette.m3surfaceContainerLow
                border.width: 1
                border.color: Colours.palette.m3primary

                ColumnLayout {
                    id: deleteContent

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.large

                    StyledText {
                        Layout.fillWidth: true
                        text: root.deletePermanent ? Tr.tr("Delete %1 item(s) permanently?").arg(root.deleteEntries.length) : Tr.tr("Move %1 item(s) to the trash?").arg(root.deleteEntries.length)
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.body.medium
                        wrapMode: Text.WordWrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        Item {
                            Layout.fillWidth: true
                        }

                        TextButton {
                            text: Tr.tr("Cancel")
                            onClicked: root.deleteDialogOpen = false
                        }

                        TextButton {
                            text: root.deletePermanent ? Tr.tr("Delete") : Tr.tr("Trash")
                            type: TextButton.Filled
                            onClicked: root.confirmDelete()
                        }
                    }
                }
            }
        }
    }

    component FileTile: StyledRect {
        id: tile

        required property int index
        required property FileSystemEntry modelData

        readonly property bool selected: root.isSelected(tile.modelData.path)
        readonly property bool current: GridView.isCurrentItem


        implicitWidth: grid.cellWidth - Tokens.spacing.small
        implicitHeight: grid.cellHeight - Tokens.spacing.small

        radius: Tokens.rounding.medium
        color: tile.selected ? Qt.alpha(Colours.tPalette.m3secondaryContainer, 0.8) : hover.containsMouse ? Qt.alpha(Colours.palette.m3onSurface, 0.06) : "transparent"
        border.width: tile.current ? 1 : 0
        border.color: Colours.palette.m3primary

        Item {
            id: icon

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Tokens.padding.small

            width: root.iconSide
            height: root.iconSide

            Visual {
                anchors.fill: parent
                visible: tile.modelData.isImage
                source: tile.modelData.isImage ? Files.fileUri(tile.modelData.path) : ""
                fillMode: VisualSource.PreserveAspectFit
            }

            Image {
                anchors.fill: parent
                visible: !tile.modelData.isImage
                source: tile.modelData.isImage ? "" : root.fileIcon(tile.modelData)
                sourceSize.width: Math.round(root.iconSide)
                sourceSize.height: Math.round(root.iconSide)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
                mipmap: true
            }

            MaterialIcon {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: root.iconSide * 0.12

                visible: root.folderBadge(tile.modelData) !== ""
                text: root.folderBadge(tile.modelData)
                color: Colours.palette.m3onPrimaryContainer
                fontStyle: Tokens.font.icon.builders.medium.scale(root.iconSide / 64).build()
            }
        }

        StyledText {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: icon.bottom
            anchors.topMargin: Tokens.spacing.small
            anchors.margins: Tokens.padding.small

            horizontalAlignment: Text.AlignHCenter
            text: tile.modelData.name
            color: Colours.palette.m3onSurface
            font: Tokens.font.label.small
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }

        MouseArea {
            id: hover

            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    if (!root.isSelected(tile.modelData.path))
                        root.selectOnly(tile.index, tile.modelData.path);
                    const pos = tile.mapToItem(contentRoot, mouse.x, mouse.y);
                    root.openEntryContext(tile.modelData, tile.index, pos.x, pos.y);
                    return;
                }

                if (mouse.modifiers & Qt.ControlModifier)
                    root.toggleSelection(tile.index, tile.modelData.path);
                else if (mouse.modifiers & Qt.ShiftModifier)
                    root.selectRange(tile.index);
                else
                    root.selectOnly(tile.index, tile.modelData.path);
            }

            onDoubleClicked: mouse => {
                if (mouse.button === Qt.LeftButton)
                    root.openEntry(tile.modelData);
            }
        }
    }
}
