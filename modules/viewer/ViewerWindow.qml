pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Models
import qs.components
import qs.components.controls
import qs.services

FloatingWindow {
    id: root

    property string sourcePath: ""
    property var images: []
    property int currentIndex: -1
    property real zoom: 1
    property bool fitMode: true
    property bool pendingFit: true
    property real panX: 0
    property real panY: 0
    property real naturalWidth: 0
    property real naturalHeight: 0
    property string errorText: ""

    readonly property string directoryPath: {
        const slash = root.sourcePath.lastIndexOf("/");
        if (slash > 0)
            return root.sourcePath.slice(0, slash);
        return slash === 0 ? "/" : "";
    }
    readonly property string fileName: {
        const slash = root.sourcePath.lastIndexOf("/");
        return slash >= 0 ? root.sourcePath.slice(slash + 1) : root.sourcePath;
    }

    signal imageViewerClosed

    function syncImages(): void {
        const list = [];
        const entries = directory.entries;
        for (let i = 0; i < entries.length; ++i) {
            const entry = entries[i];
            if (entry && !entry.isDir)
                list.push(entry);
        }

        list.sort((a, b) => a.name.localeCompare(b.name, undefined, {
            numeric: true,
            sensitivity: "base"
        }));

        root.images = list;
        root.currentIndex = list.findIndex(entry => entry.path === root.sourcePath);
    }

    function fitToWindow(): void {
        if (photo.status !== Image.Ready || root.naturalWidth <= 0 || root.naturalHeight <= 0 || viewport.width <= 0 || viewport.height <= 0) {
            root.pendingFit = true;
            return;
        }

        root.zoom = Math.min(1, viewport.width / root.naturalWidth, viewport.height / root.naturalHeight);
        root.panX = 0;
        root.panY = 0;
        root.fitMode = true;
        root.pendingFit = false;
    }

    function setZoom(value: real): void {
        root.zoom = Math.max(0.01, Math.min(8, value));
        root.fitMode = false;
        root.pendingFit = false;
        Qt.callLater(root.clampPan);
    }

    function changeZoom(factor: real): void {
        root.setZoom(root.zoom * factor);
    }

    function clampPan(): void {
        const maxX = Math.max(0, (photo.width - viewport.width) / 2);
        const maxY = Math.max(0, (photo.height - viewport.height) / 2);
        root.panX = Math.max(-maxX, Math.min(maxX, root.panX));
        root.panY = Math.max(-maxY, Math.min(maxY, root.panY));
    }

    function handlePhotoStatus(status: int, width: real, height: real): void {
        if (status === Image.Ready) {
            root.naturalWidth = width;
            root.naturalHeight = height;
            root.errorText = "";
            if (root.pendingFit)
                root.fitToWindow();
            else
                root.clampPan();
        } else if (status === Image.Error) {
            root.naturalWidth = 0;
            root.naturalHeight = 0;
            root.errorText = Tr.tr("Unable to open image");
        }
    }

    function fileUrl(path: string): string {
        if (!path)
            return "";
        return `file://${path.split("/").map(encodeURIComponent).join("/")}`;
    }

    function openPath(path: string): void {
        const changed = path !== root.sourcePath;
        root.sourcePath = path;
        root.errorText = "";
        root.fitMode = true;
        root.pendingFit = true;
        root.panX = 0;
        root.panY = 0;
        root.zoom = 1;
        if (changed) {
            root.naturalWidth = 0;
            root.naturalHeight = 0;
        }
        Qt.callLater(() => {
            root.syncImages();
            if (photo.status === Image.Ready)
                root.fitToWindow();
        });
    }

    function previous(): void {
        if (root.images.length < 2)
            return;
        const index = root.images.findIndex(entry => entry.path === root.sourcePath);
        root.openPath(root.images[(index - 1 + root.images.length) % root.images.length].path);
    }

    function next(): void {
        if (root.images.length < 2)
            return;
        const index = root.images.findIndex(entry => entry.path === root.sourcePath);
        root.openPath(root.images[(index + 1) % root.images.length].path);
    }

    visible: true
    implicitWidth: 1100
    implicitHeight: 760
    minimumSize.width: 480
    minimumSize.height: 360
    color: Colours.tPalette.m3surface
    surfaceFormat.opaque: true
    title: root.fileName.length > 0 ? root.fileName : Tr.tr("Image Viewer")

    onVisibleChanged: {
        if (!visible) {
            root.imageViewerClosed();
            destroy();
        }
    }
    onWidthChanged: {
        if (root.fitMode)
            Qt.callLater(root.fitToWindow);
    }
    onHeightChanged: {
        if (root.fitMode)
            Qt.callLater(root.fitToWindow);
    }
    Component.onCompleted: {
        if (root.sourcePath.length > 0)
            root.openPath(root.sourcePath);
        Qt.callLater(() => contentRoot.forceActiveFocus());
    }

    FileSystemModel {
        id: directory

        path: root.directoryPath
        recursive: false
        watchChanges: true
        filter: FileSystemModel.Images

        onEntriesChanged: root.syncImages()
    }

    FocusScope {
        id: contentRoot

        readonly property real topPadding: toolbarRect.implicitHeight + Tokens.padding.medium * 2

        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Escape:
                if (root.fullscreen)
                    root.fullscreen = false;
                else
                    root.visible = false;
                break;
            case Qt.Key_F11:
            case Qt.Key_F:
                root.fullscreen = !root.fullscreen;
                break;
            case Qt.Key_Left:
                root.previous();
                break;
            case Qt.Key_Right:
                root.next();
                break;
            case Qt.Key_Plus:
            case Qt.Key_Equal:
                root.changeZoom(1.2);
                break;
            case Qt.Key_Minus:
                root.changeZoom(1 / 1.2);
                break;
            case Qt.Key_0:
                root.fitToWindow();
                break;
            case Qt.Key_1:
                root.setZoom(1);
                break;
            default:
                return;
            }
            event.accepted = true;
        }

        Item {
            id: viewport

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: contentRoot.topPadding
            clip: true

            AnimatedImage {
                id: photo

                source: root.fileUrl(root.sourcePath)
                asynchronous: true
                cache: false
                mipmap: true
                playing: true
                fillMode: Image.PreserveAspectFit
                width: root.naturalWidth * root.zoom
                height: root.naturalHeight * root.zoom
                x: (viewport.width - width) / 2 + root.panX
                y: (viewport.height - height) / 2 + root.panY
                opacity: status === Image.Ready ? 1 : 0

                onStatusChanged: root.handlePhotoStatus(status, implicitWidth, implicitHeight)
            }

            StyledText {
                anchors.centerIn: parent
                visible: photo.status === Image.Error
                text: root.errorText
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.large
            }

            MouseArea {
                id: mouseArea

                property real pressX: 0
                property real pressY: 0
                property real startPanX: 0
                property real startPanY: 0

                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                cursorShape: root.zoom > 1 ? Qt.OpenHandCursor : Qt.ArrowCursor

                onPressed: mouse => {
                    pressX = mouse.x;
                    pressY = mouse.y;
                    startPanX = root.panX;
                    startPanY = root.panY;
                    cursorShape = Qt.ClosedHandCursor;
                }
                onReleased: cursorShape = root.zoom > 1 ? Qt.OpenHandCursor : Qt.ArrowCursor
                onPositionChanged: mouse => {
                    if (!(mouse.buttons & Qt.LeftButton))
                        return;
                    root.panX = startPanX + mouse.x - pressX;
                    root.panY = startPanY + mouse.y - pressY;
                    root.clampPan();
                }
                onWheel: wheel => {
                    root.changeZoom(wheel.angleDelta.y > 0 ? 1.2 : 1 / 1.2);
                    wheel.accepted = true;
                }
                onDoubleClicked: root.fullscreen = !root.fullscreen
            }
        }

        StyledRect {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Tokens.padding.medium

            implicitHeight: toolbar.implicitHeight + Tokens.padding.small * 2
            radius: Tokens.rounding.large
            color: Qt.alpha(Colours.tPalette.m3surfaceContainer, 0.92)

            RowLayout {
                id: toolbar

                anchors.fill: parent
                anchors.margins: Tokens.padding.small
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    Layout.leftMargin: Tokens.padding.small
                    text: root.fileName
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.medium
                    elide: Text.ElideMiddle
                }

                StyledText {
                    visible: root.images.length > 0
                    text: `${root.currentIndex + 1} / ${root.images.length}`
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                }

                IconButton {
                    icon: "chevron_left"
                    type: IconButton.Text
                    enabled: root.images.length > 1
                    onClicked: root.previous()
                }

                IconButton {
                    icon: "chevron_right"
                    type: IconButton.Text
                    enabled: root.images.length > 1
                    onClicked: root.next()
                }

                IconButton {
                    icon: "zoom_out"
                    type: IconButton.Text
                    onClicked: root.changeZoom(1 / 1.2)
                }

                IconButton {
                    icon: "zoom_in"
                    type: IconButton.Text
                    onClicked: root.changeZoom(1.2)
                }

                IconButton {
                    icon: "fit_screen"
                    type: IconButton.Text
                    onClicked: root.fitToWindow()
                }

                IconButton {
                    icon: root.fullscreen ? "fullscreen_exit" : "fullscreen"
                    type: IconButton.Text
                    onClicked: root.fullscreen = !root.fullscreen
                }

                IconButton {
                    icon: "close"
                    type: IconButton.Text
                    onClicked: root.visible = false
                }
            }
        }
    }
}
