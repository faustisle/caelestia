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
            description: "Material surfaces, tonal colour and expressive motion",
            rounding: 1,
            padding: 1,
            spacing: 1,
            anim: 1,
            deform: 1,
            waves: true,
            ripple: true,
            morph: true,
            palette: "material",
            acrylic: false,
            border: 0,
            shadow: 0.7,
            shadowBlur: 15,
            taskbar: false,
            font: "",
            iconFont: ""
        },
        {
            id: "fluent",
            name: "Fluent",
            description: "Mica surfaces, fine borders and calm motion",
            rounding: 0.32,
            padding: 0.9,
            spacing: 0.95,
            anim: 0.7,
            deform: 0,
            waves: false,
            ripple: false,
            morph: false,
            palette: "fluent",
            acrylic: false,
            border: 1,
            shadow: 0.28,
            shadowBlur: 28,
            taskbar: true,
            borderThickness: 0,
            borderRounding: 0,
            borderSmoothing: 0,
            font: "Adwaita Sans",
            iconFont: "Material Symbols Outlined"
        }
    ]

    readonly property var active: root.themes.find(theme => theme.id === root.current) ?? root.themes[0]
    readonly property bool fluent: root.active.palette === "fluent"
    readonly property bool ripple: root.active.ripple ?? true
    readonly property bool morph: root.active.morph ?? true
    readonly property bool waves: root.active.waves ?? true
    readonly property real borderWidth: root.active.border ?? 0
    readonly property color borderColour: Qt.alpha(Colours.palette.m3outline, root.fluent ? 0.28 : 0)
    readonly property real shadowOpacity: root.active.shadow ?? 0.7
    readonly property real shadowBlur: root.active.shadowBlur ?? 15
    readonly property bool taskbar: root.active.taskbar ?? false

    function defaultMaterial(): var {
        return {
            rounding: 1,
            padding: 1,
            spacing: 1,
            anim: 1,
            deform: 1,
            transparencyEnabled: false,
            tintBase: 0.85,
            tintLayers: 0.4,
            borderThickness: 10,
            borderRounding: 25,
            borderSmoothing: 20,
            fontHeadline: "GoogleSansFlex",
            fontTitle: "GoogleSansFlex",
            fontBody: "GoogleSansFlex",
            fontLabel: "GoogleSansFlex",
            fontClock: "Rubik",
            fontWorkspaces: "Rubik",
            iconFamily: "Material Symbols Rounded"
        };
    }

    function captureMaterial(): void {
        if (root.material)
            return;

        root.material = {
            rounding: GlobalConfig.appearance.rounding.scale,
            padding: GlobalConfig.appearance.padding.scale,
            spacing: GlobalConfig.appearance.spacing.scale,
            anim: GlobalConfig.appearance.anim.durations.scale,
            deform: GlobalConfig.appearance.deformScale,
            transparencyEnabled: GlobalConfig.appearance.transparency.enabled,
            tintBase: GlobalConfig.appearance.transparency.base,
            tintLayers: GlobalConfig.appearance.transparency.layers,
            borderThickness: GlobalConfig.border.thickness,
            borderRounding: GlobalConfig.border.rounding,
            borderSmoothing: GlobalConfig.border.smoothing,
            fontHeadline: GlobalConfig.appearance.font.headline.family,
            fontTitle: GlobalConfig.appearance.font.title.family,
            fontBody: GlobalConfig.appearance.font.body.family,
            fontLabel: GlobalConfig.appearance.font.label.family,
            fontClock: GlobalConfig.appearance.font.clock,
            fontWorkspaces: GlobalConfig.appearance.font.workspaces,
            iconFamily: GlobalConfig.appearance.font.icon.family
        };
    }

    function normalizeMaterial(data: var): var {
        const base = root.defaultMaterial();

        return {
            rounding: data?.rounding ?? base.rounding,
            padding: data?.padding ?? base.padding,
            spacing: data?.spacing ?? base.spacing,
            anim: data?.anim ?? base.anim,
            deform: data?.deform ?? base.deform,
            transparencyEnabled: data?.transparencyEnabled ?? base.transparencyEnabled,
            tintBase: data?.tintBase ?? base.tintBase,
            tintLayers: data?.tintLayers ?? base.tintLayers,
            borderThickness: data?.borderThickness ?? base.borderThickness,
            borderRounding: data?.borderRounding ?? base.borderRounding,
            borderSmoothing: data?.borderSmoothing ?? base.borderSmoothing,
            fontHeadline: data?.fontHeadline ?? base.fontHeadline,
            fontTitle: data?.fontTitle ?? base.fontTitle,
            fontBody: data?.fontBody ?? base.fontBody,
            fontLabel: data?.fontLabel ?? base.fontLabel,
            fontClock: data?.fontClock ?? base.fontClock,
            fontWorkspaces: data?.fontWorkspaces ?? base.fontWorkspaces,
            iconFamily: data?.iconFamily ?? base.iconFamily
        };
    }

    function applyFonts(theme: var, base: var): void {
        const font = GlobalConfig.appearance.font;

        font.headline.family = theme.font || base.fontHeadline;
        font.title.family = theme.font || base.fontTitle;
        font.body.family = theme.font || base.fontBody;
        font.label.family = theme.font || base.fontLabel;
        font.clock = theme.font || base.fontClock;
        font.workspaces = theme.font || base.fontWorkspaces;
        font.icon.family = theme.iconFont || base.iconFamily;
    }

    function apply(id: string): void {
        root.captureMaterial();

        const theme = root.themes.find(item => item.id === id) ?? root.themes[0];
        const base = root.material ?? root.defaultMaterial();
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

        GlobalConfig.border.thickness = theme.borderThickness ?? base.borderThickness;
        GlobalConfig.border.rounding = theme.borderRounding ?? base.borderRounding;
        GlobalConfig.border.smoothing = theme.borderSmoothing ?? base.borderSmoothing;

        const acrylic = theme.acrylic && theme.transparency;
        GlobalConfig.appearance.transparency.enabled = acrylic ? true : base.transparencyEnabled;
        GlobalConfig.appearance.transparency.base = acrylic ? theme.transparency.base : base.tintBase;
        GlobalConfig.appearance.transparency.layers = acrylic ? theme.transparency.layers : base.tintLayers;

        root.applyFonts(theme, base);
        Colours.style = theme.palette;
        Quickshell.execDetached(["python3", Quickshell.shellPath("assets/apply-thunar-theme.py"), theme.id]);
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
                root.material = root.normalizeMaterial(data.material);
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
