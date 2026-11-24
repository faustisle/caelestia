pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils
import qs.modules.viewer

Singleton {
    id: root

    property var currentWindow: null

    function resolvePath(path: string): string {
        let resolved = path.trim();
        if (!resolved)
            return "";

        if (resolved.startsWith("file://"))
            return Paths.toLocalFile(resolved);

        if (!resolved.startsWith("/") && !resolved.startsWith("~") && !resolved.startsWith("$"))
            resolved = `${Quickshell.env("PWD") || Paths.home}/${resolved}`;

        return Paths.absolutePath(resolved);
    }

    function open(path: string): void {
        if (!path)
            return;

        const localPath = root.resolvePath(path);
        if (!localPath)
            return;

        if (root.currentWindow) {
            root.currentWindow.openPath(localPath);
            root.currentWindow.visible = true;
            if (root.currentWindow.requestActivate)
                root.currentWindow.requestActivate();
            return;
        }

        const window = windowComp.createObject(windowHolder, {
            sourcePath: localPath
        });
        if (!window)
            return;

        root.currentWindow = window;
        window.imageViewerClosed.connect(() => {
            if (root.currentWindow === window)
                root.currentWindow = null;
        });
        window.visible = true;
        if (window.requestActivate)
            window.requestActivate();
    }

    IpcHandler {
        function open(path: string): void {
            root.open(path);
        }

        target: "imageViewer"
    }

    QtObject {
        id: windowHolder
    }

    Component {
        id: windowComp

        ViewerWindow {}
    }
}
