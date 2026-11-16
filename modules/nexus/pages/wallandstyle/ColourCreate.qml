pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    property string name: ""
    property string seed: ""
    property string mode: "dark"
    property string variant: "tonalspot"
    property string editingId: ""
    property var previewColours
    property bool applyAfter: true
    property bool creating: false
    property bool previewPending: false
    property string error: ""

    readonly property string helper: Quickshell.shellPath("assets/scheme-creator.py")
    readonly property bool seedValid: /^#?[0-9a-fA-F]{6}$/.test(seed.trim())
    readonly property bool nameValid: name.trim().length > 0
    readonly property bool valid: seedValid && nameValid
    readonly property string normalisedSeed: seed.trim().replace("#", "").toLowerCase()
    readonly property bool editing: editingId.length > 0

    readonly property list<MenuItem> modeItems: [
        MenuItem {
            text: Tr.tr("Dark")
            value: "dark"
        },
        MenuItem {
            text: Tr.tr("Light")
            value: "light"
        }
    ]

    readonly property list<MenuItem> variantItems: [
        MenuItem {
            text: Tr.tr("Tonal spot")
            value: "tonalspot"
        },
        MenuItem {
            text: Tr.tr("Vibrant")
            value: "vibrant"
        },
        MenuItem {
            text: Tr.tr("Expressive")
            value: "expressive"
        },
        MenuItem {
            text: Tr.tr("Fidelity")
            value: "fidelity"
        },
        MenuItem {
            text: Tr.tr("Fruit salad")
            value: "fruitsalad"
        },
        MenuItem {
            text: Tr.tr("Monochrome")
            value: "monochrome"
        },
        MenuItem {
            text: Tr.tr("Neutral")
            value: "neutral"
        },
        MenuItem {
            text: Tr.tr("Rainbow")
            value: "rainbow"
        },
        MenuItem {
            text: Tr.tr("Content")
            value: "content"
        }
    ]

    function pretty(s: string): string {
        const names = {
            tonalspot: "Tonal spot",
            fruitsalad: "Fruit salad"
        };
        return names[s] ?? (s.length > 0 ? s.charAt(0).toUpperCase() + s.slice(1) : s);
    }

    function colour(value: var): string {
        return value ? `#${value}` : "transparent";
    }

    function schedulePreview(): void {
        previewTimer.restart();
    }

    function generatePreview(): void {
        if (!root.seedValid)
            return;
        if (previewProc.running) {
            root.previewPending = true;
            return;
        }

        root.error = "";
        previewProc.command = ["python3", root.helper, "preview", "--seed", root.normalisedSeed, "--mode", root.mode, "--variant", root.variant];
        previewProc.running = true;
    }

    function handlePreview(data: string): void {
        if (!data)
            return;
        try {
            const colours = JSON.parse(data).colours;
            root.previewColours = colours;
            Colours.load(JSON.stringify({
                name: root.name.trim() || "Preview",
                flavour: "default",
                mode: root.mode,
                colours: colours
            }), true);
            Colours.showPreview = true;
        } catch (e) {
            root.error = Tr.tr("Could not generate the scheme.");
        }
    }

    function create(): void {
        if (!root.valid || root.creating)
            return;

        root.creating = true;
        root.error = "";
        const command = ["python3", root.helper, "create", "--name", root.name.trim(), "--seed", root.normalisedSeed, "--mode", root.mode, "--variant", root.variant];
        if (root.editing)
            command.push("--id", root.editingId);
        if (root.applyAfter)
            command.push("--apply");
        createProc.command = command;
        createProc.running = true;
    }

    title: root.editing ? Tr.tr("Edit scheme") : Tr.tr("Create scheme")
    isSubPage: true

    onSeedChanged: {
        if (root.seedValid)
            root.schedulePreview();
        else {
            Colours.showPreview = false;
            root.previewColours = null;
        }
    }
    onModeChanged: root.schedulePreview()
    onVariantChanged: root.schedulePreview()
    onVisibleChanged: {
        if (visible)
            root.schedulePreview();
        else
            Colours.showPreview = false;
    }
    Component.onCompleted: {
        const scheme = root.nState.editingScheme;
        if (scheme) {
            root.editingId = scheme.id;
            root.name = scheme.name;
            root.seed = scheme.seed;
            root.mode = scheme.mode;
            root.variant = scheme.variant;
        } else {
            root.seed = "#" + Colours.palette.m3primary.toString().slice(-6);
        }
        root.schedulePreview();
    }
    Component.onDestruction: {
        Colours.showPreview = false;
        root.nState.editingScheme = null;
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.medium

        SectionHeader {
            first: true
            text: Tr.tr("Details")
        }

        TextFieldRow {
            first: true
            label: Tr.tr("Name")
            subtext: Tr.tr("Shown in the scheme list")
            value: root.name
            maximumLength: 32
            onValueEdited: value => root.name = value
        }

        TextFieldRow {
            last: true
            label: Tr.tr("Seed colour")
            subtext: root.seedValid ? Tr.tr("Hex colour used to generate the palette") : Tr.tr("Enter a hex colour such as #ff8800")
            value: root.seed
            maximumLength: 7
            onValueEdited: value => root.seed = value
        }

        SectionHeader {
            text: Tr.tr("Palette")
        }

        SelectRow {
            first: true
            label: Tr.tr("Mode")
            subtext: Tr.tr("Light or dark palette")
            menuItems: root.modeItems
            active: root.modeItems.find(i => i.value === root.mode) ?? root.modeItems[0]
            onSelected: item => root.mode = item.value
        }

        SelectRow {
            last: true
            label: Tr.tr("Variant")
            subtext: Tr.tr("Material colour generation style")
            menuItems: root.variantItems
            active: root.variantItems.find(i => i.value === root.variant) ?? root.variantItems[0]
            onSelected: item => root.variant = item.value
        }

        SectionHeader {
            text: Tr.tr("Preview")
        }

        SchemeItem {
            Layout.fillWidth: true
            interactive: false
            label: root.name.trim() || Tr.tr("New scheme")
            flavourLabel: `${root.pretty(root.variant)} · ${root.pretty(root.mode)}`
            primary: root.previewColours ? root.colour(root.previewColours.primary) : Colours.palette.m3primary
            secondary: root.previewColours ? root.colour(root.previewColours.secondary) : Colours.palette.m3secondary
            tertiary: root.previewColours ? root.colour(root.previewColours.tertiary) : Colours.palette.m3tertiary
            surface: root.previewColours ? root.colour(root.previewColours.surface) : Colours.palette.m3surface
            active: false
        }

        ToggleRow {
            first: true
            last: true
            text: Tr.tr("Apply after creating")
            checked: root.applyAfter
            onToggled: root.applyAfter = checked
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.error.length > 0
            text: root.error
            color: Colours.palette.m3error
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        ButtonRow {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.spacing.small
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "add"
                text: root.creating ? (root.editing ? Tr.tr("Saving…") : Tr.tr("Creating…")) : root.editing ? Tr.tr("Save changes") : Tr.tr("Create scheme")
                type: IconTextButton.Filled
                isRound: true
                shapeMorph: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                disabled: !root.valid || root.creating
                onClicked: root.create()
            }

            IconTextButton {
                icon: "close"
                text: Tr.tr("Cancel")
                type: IconTextButton.Tonal
                isRound: true
                shapeMorph: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                disabled: root.creating
                onClicked: root.nState.closeSubPage()
            }
        }

        Process {
            id: previewProc

            onExited: code => {
                if (root.previewPending) {
                    root.previewPending = false;
                    previewTimer.restart();
                }
                if (code !== 0 && previewErr.text.trim().length > 0)
                    root.error = previewErr.text.trim();
            }
            stdout: StdioCollector {
                onStreamFinished: root.handlePreview(text)
            }
            stderr: StdioCollector {
                id: previewErr
            }
        }

        Process {
            id: createProc

            onExited: code => {
                root.creating = false;
                if (code === 0) {
                    Colours.showPreview = false;
                    root.nState.closeSubPage();
                } else {
                    root.error = createErr.text.trim() || Tr.tr("Could not create the scheme.");
                }
            }
            stderr: StdioCollector {
                id: createErr
            }
        }

        Timer {
            id: previewTimer

            interval: 350
            onTriggered: root.generatePreview()
        }
    }
}
