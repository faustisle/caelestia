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
import qs.modules.nexus.common

PageBase {
    id: root

    property var schemes: []
    property var bundledSchemes: []
    property var customSchemes: []
    property string customActiveId: ""
    property string bundledActiveId: ""
    property bool loading: true
    property bool failed: false

    readonly property string helper: Quickshell.shellPath("assets/scheme-creator.py")
    readonly property var availableSchemes: {
        const cli = root.schemes.map(scheme => Object.assign({}, scheme, {
                bundled: false
            }));
        const installed = new Set(cli.map(scheme => `${scheme.name}/${scheme.flavour}`.toLowerCase()));
        const bundled = root.bundledSchemes.filter(scheme => !installed.has(`${scheme.name}/${scheme.flavour}`.toLowerCase()));
        const all = cli.concat(bundled);
        all.sort((a, b) => (a.label ?? "").localeCompare(b.label ?? "") || (a.flavourLabel ?? "").localeCompare(b.flavourLabel ?? ""));
        return all;
    }

    property Process listProc: Process {
        running: true
        command: ["caelestia", "scheme", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                root.failed = !root.loadSchemes(text);
            }
        }
        onExited: code => {
            if (code !== 0) {
                root.loading = false;
                root.failed = true;
            }
        }
    }

    property FileView bundledFile: FileView {
        path: Quickshell.shellPath("assets/schemes/index.json")
        watchChanges: true
        printErrors: false
        onLoaded: root.loadBundledSchemes(text())
        onLoadFailed: root.bundledSchemes = []
    }

    property FileView presetsFile: FileView {
        path: `${Paths.state}/custom-schemes.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.loadCustomSchemes(text())
        onLoadFailed: root.customSchemes = []
    }

    property FileView schemeFile: FileView {
        path: `${Paths.state}/scheme.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.customActiveId = data.customId ?? "";
                root.bundledActiveId = data.bundledId ?? "";
            } catch (e) {
                root.customActiveId = "";
                root.bundledActiveId = "";
            }
        }
        onLoadFailed: {
            root.customActiveId = "";
            root.bundledActiveId = "";
        }
    }

    function pretty(s: string): string {
        const names = {
            shadotheme: "Shado Theme",
            tokyonight: "Tokyo Night",
            darkgreen: "Dark Green",
            everblush: "Everblush",
            everforest: "Everforest",
            oldworld: "Old World",
            onedark: "One Dark",
            rosepine: "Rose Pine",
            frappe: "Frappé",
            tonalspot: "Tonal spot",
            fruitsalad: "Fruit salad"
        };
        return names[s] ?? (s.length > 0 ? s.charAt(0).toUpperCase() + s.slice(1) : s);
    }

    function colour(value: var): string {
        return value ? `#${value}` : "transparent";
    }

    function loadSchemes(data: string): bool {
        try {
            const parsed = JSON.parse(data);
            const list = [];
            for (const name in parsed) {
                for (const flavour in parsed[name]) {
                    const colours = parsed[name][flavour];
                    list.push({
                        name: name,
                        flavour: flavour,
                        label: pretty(name),
                        flavourLabel: pretty(flavour),
                        primary: colour(colours.primary),
                        secondary: colour(colours.secondary),
                        tertiary: colour(colours.tertiary),
                        surface: colour(colours.surface)
                    });
                }
            }
            list.sort((a, b) => a.name.localeCompare(b.name) || a.flavour.localeCompare(b.flavour));
            root.schemes = list;
            return list.length > 0;
        } catch (e) {
            console.warn("Failed to parse colour schemes:", e);
            return false;
        }
    }

    function loadCustomSchemes(data: string): void {
        try {
            const presets = JSON.parse(data);
            root.customSchemes = presets.map(preset => ({
                        id: preset.id,
                        name: preset.name,
                        seed: preset.seed,
                        mode: preset.mode,
                        variant: preset.variant,
                        label: preset.name,
                        flavourLabel: `${pretty(preset.variant)} · ${pretty(preset.mode)}`,
                        primary: colour(preset.colours.primary),
                        secondary: colour(preset.colours.secondary),
                        tertiary: colour(preset.colours.tertiary),
                        surface: colour(preset.colours.surface)
                    }));
        } catch (e) {
            root.customSchemes = [];
        }
    }

    function loadBundledSchemes(data: string): void {
        try {
            root.bundledSchemes = JSON.parse(data).map(entry => ({
                        id: entry.id,
                        bundled: true,
                        name: entry.name,
                        flavour: entry.flavour,
                        label: entry.name,
                        flavourLabel: pretty(entry.flavour),
                        primary: colour(entry.primary),
                        secondary: colour(entry.secondary),
                        tertiary: colour(entry.tertiary),
                        surface: colour(entry.surface)
                    }));
        } catch (e) {
            root.bundledSchemes = [];
        }
    }

    function applyScheme(scheme: var): void {
        root.customActiveId = "";
        root.bundledActiveId = "";
        Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-n", scheme.name, "-f", scheme.flavour]);
    }

    function applyCustom(scheme: var): void {
        root.customActiveId = scheme.id;
        root.bundledActiveId = "";
        Quickshell.execDetached(["python3", root.helper, "apply", "--id", scheme.id]);
    }

    function applyBundled(scheme: var): void {
        root.customActiveId = "";
        root.bundledActiveId = scheme.id;
        Quickshell.execDetached(["python3", root.helper, "apply-bundled", "--id", scheme.id]);
    }

    function editCustom(scheme: var): void {
        root.nState.editingScheme = scheme;
        root.nState.openSubPage(4);
    }

    function deleteCustom(scheme: var): void {
        root.customSchemes = root.customSchemes.filter(item => item.id !== scheme.id);
        deleteProc.command = ["python3", root.helper, "delete", "--id", scheme.id];
        deleteProc.running = true;
    }

    title: Tr.tr("Colours")
    isSubPage: true

    onVisibleChanged: {
        if (visible) {
            presetsFile.reload();
            schemeFile.reload();
            bundledFile.reload();
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.medium

        IconTextButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Tokens.spacing.small
            icon: "add"
            text: Tr.tr("Create scheme")
            type: IconTextButton.Tonal
            isRound: true
            shapeMorph: true
            horizontalPadding: Tokens.padding.extraLarge
            verticalPadding: Tokens.padding.medium
            onClicked: {
                root.nState.editingScheme = null;
                root.nState.openSubPage(4);
            }
        }

        SectionHeader {
            first: true
            text: Tr.tr("Available schemes")
        }

        StyledText {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.small
            text: Tr.tr("Colour schemes bundled with Caelestia")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        GridLayout {
            Layout.fillWidth: true
            visible: root.availableSchemes.length > 0
            columns: 2
            rowSpacing: Tokens.spacing.medium
            columnSpacing: Tokens.spacing.medium

            Repeater {
                model: root.availableSchemes

                SchemeItem {
                    required property var modelData

                    label: modelData.label
                    flavourLabel: modelData.flavourLabel
                    primary: modelData.primary
                    secondary: modelData.secondary
                    tertiary: modelData.tertiary
                    surface: modelData.surface
                    active: modelData.bundled ? root.bundledActiveId === modelData.id : !root.customActiveId && !root.bundledActiveId && Colours.scheme === modelData.name && Colours.flavour === modelData.flavour
                    onClicked: modelData.bundled ? root.applyBundled(modelData) : root.applyScheme(modelData)
                }
            }
        }

        SectionHeader {
            text: Tr.tr("Custom schemes")
            visible: root.customSchemes.length > 0
        }

        GridLayout {
            Layout.fillWidth: true
            visible: root.customSchemes.length > 0
            columns: 2
            rowSpacing: Tokens.spacing.medium
            columnSpacing: Tokens.spacing.medium

            Repeater {
                model: root.customSchemes

                SchemeItem {
                    required property var modelData

                    label: modelData.label
                    flavourLabel: modelData.flavourLabel
                    primary: modelData.primary
                    secondary: modelData.secondary
                    tertiary: modelData.tertiary
                    surface: modelData.surface
                    active: root.customActiveId === modelData.id
                    manageable: true
                    onClicked: root.applyCustom(modelData)
                    onEditRequested: root.editCustom(modelData)
                    onDeleteRequested: root.deleteCustom(modelData)
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large
            visible: root.loading
            text: Tr.tr("Loading schemes…")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.medium
            horizontalAlignment: Text.AlignHCenter
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large
            visible: !root.loading && root.failed
            text: Tr.tr("Could not load colour schemes.")
            color: Colours.palette.m3error
            font: Tokens.font.body.medium
            horizontalAlignment: Text.AlignHCenter
        }

        Process {
            id: deleteProc

            onExited: code => {
                root.presetsFile.reload();
                root.schemeFile.reload();
                if (code !== 0)
                    console.warn("Failed to delete colour scheme:", deleteErr.text.trim());
            }
            stderr: StdioCollector {
                id: deleteErr
            }
        }

        Connections {
            function onSubPageClosed(): void {
                root.presetsFile.reload();
                root.schemeFile.reload();
                root.bundledFile.reload();
            }

            target: root.nState
        }
    }
}
