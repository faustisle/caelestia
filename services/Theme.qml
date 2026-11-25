pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.services
import qs.utils

Singleton {
    id: root

    property string current: "material"
    property var material: null

    readonly property var themes: [
        {
            id: "material",
            name: "Material",
            description: "The current Material-inspired surfaces and motion",
            rounding: 1,
            padding: 1,
            spacing: 1,
            anim: 1,
            deform: 1,
            waves: true,
            tintBase: 0,
            tintLayers: 1
        },
        {
            id: "fluent",
            name: "Fluent 2",
            description: "Windows 11-inspired tighter surfaces and quieter motion",
            rounding: 0.55,
            padding: 0.88,
            spacing: 0.92,
            anim: 0.65,
            deform: 0,
            waves: false,
            tintBase: 0.04,
            tintLayers: 0.8
        }
    ]

    readonly property var active: root.themes.find(theme => theme.id === root.current) ?? root.themes[0]

    function captureMaterial(): void {
        if (root.material)
            return;

        root.material = {
            rounding: GlobalConfig.appearance.rounding.scale,
            padding: GlobalConfig.appearance.padding.scale,
            spacing: GlobalConfig.appearance.spacing.scale,
            anim: GlobalConfig.appearance.anim.durations.scale,
            deform: GlobalConfig.appearance.deformScale,
            tintBase: GlobalConfig.appearance.transparency.base,
            tintLayers: GlobalConfig.appearance.transparency.layers
        };
    }

    function clamp(value: real, min: real, max: real): real {
        return Math.max(min, Math.min(max, value));
    }

    function apply(id: string): void {
        root.captureMaterial();

        const theme = root.themes.find(item => item.id === id) ?? root.themes[0];
        const base = root.material;
        const shellRoot = ShellState.shellRoot;
        const wasWatching = shellRoot?.settings.watchFiles ?? false;

        if (shellRoot)
            shellRoot.settings.watchFiles = false;

        root.current = theme.id;
        GlobalConfig.appearance.rounding.scale = base.rounding * theme.rounding;
        GlobalConfig.appearance.padding.scale = base.padding * theme.padding;
        GlobalConfig.appearance.spacing.scale = base.spacing * theme.spacing;
        GlobalConfig.appearance.anim.durations.scale = base.anim * theme.anim;
        GlobalConfig.appearance.deformScale = base.deform * theme.deform;
        GlobalConfig.appearance.transparency.base = root.clamp(base.tintBase + theme.tintBase, 0, 1);
        GlobalConfig.appearance.transparency.layers = root.clamp(base.tintLayers * theme.tintLayers, 0, 1);
        root.saveState();

        if (shellRoot)
            Qt.callLater(() => shellRoot.settings.watchFiles = wasWatching);
    }

    function saveState(): void {
        if (!root.material)
            return;

        stateFile.setText(JSON.stringify({
            current: root.current,
            material: root.material
        }));
    }

    function loadState(text: string): void {
        try {
            const data = JSON.parse(text);
            if (data.material)
                root.material = data.material;
            if (typeof data.current === "string" && root.themes.some(theme => theme.id === data.current))
                root.apply(data.current);
            else
                root.apply("material");
        } catch (e) {
            root.apply("material");
        }
    }

    Component.onCompleted: {
        root.captureMaterial();
    }

    IpcHandler {
        function set(id: string): void {
            root.apply(id);
        }

        target: "theme"
    }

    FileView {
        id: stateFile

        printErrors: false
        path: `${Paths.state}/theme.json`
        watchChanges: false

        onLoaded: root.loadState(text())
        onLoadFailed: root.apply("material")
    }
}
