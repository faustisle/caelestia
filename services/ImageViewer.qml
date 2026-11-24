pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils
import qs.modules.viewer

Singleton {
    id: root

    function resolvePath(path: string): string {
        let resolved = path.trim();
        if (!resolved)
            return "";

        if (resolved.startsWith("file://"))
            return Paths.toLocalFile(resolved);

        if (!resolved.startsWith("/") && !resolved.startsWith("~") && !resolved.startsWith("$"))
            resolved = `${Paths.home}/${resolved}`;

        return Paths.absolutePath(resolved);
    }

    function open(path: string): void {
        if (!path)
            return;

        const localPath = root.resolvePath(path);
        if (!localPath)
            return;

        const window = windowComp.createObject(windowHolder, {
            sourcePath: localPath
        });
        if (!window)
            return;

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
