pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Blobs
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.bar
import qs.daemons

StyledWindow {
    id: root

    readonly property alias bar: bar
    readonly property alias interactionWrapper: interactions
    readonly property alias geometry: geometry

    readonly property ScreenState screenState: ShellState.forScreen(screen)

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property bool hasSpecialWorkspace: (monitor?.lastIpcObject.specialWorkspace?.name.length ?? 0) > 0
    readonly property bool hasFullscreenOnNormalWs: monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false
    readonly property bool hasFullscreen: {
        if (hasSpecialWorkspace) {
            const specialName = monitor?.lastIpcObject.specialWorkspace?.name;
            if (!specialName)
                return false;
            const specialWs = Hypr.workspaces.values.find(ws => ws.name === specialName);
            return specialWs?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
        }
        return hasFullscreenOnNormalWs;
    }

    property real fsTransitionProg: hasFullscreen ? 1 : 0
    readonly property real sdfBorderOffset: 2 * fsTransitionProg // SDFs joins are not exact, so offset by 2px to ensure nothing shows
    readonly property real borderThickness: contentItem.Config.border.thickness * (1 - fsTransitionProg)
    readonly property real borderRounding: (GameMode.enabled && GlobalConfig.utilities.gameMode.options["decoration:rounding"] === 0 ? 0 : contentItem.Config.border.rounding) * (1 - fsTransitionProg)
    readonly property real shadowOpacity: 0.7 * (1 - fsTransitionProg)
    readonly property real borderLayoutThickness: hasFullscreen ? 0 : contentItem.Config.border.thickness
    // Shared screen dim opacity for the session menu and the launcher
    readonly property real dimOpacity: 0.5

    property color surfaceColour: Colours.tPalette.m3surface

    readonly property int dragMaskPadding: {
        if (focusGrab.active || panels.popouts.isDetached)
            return 0;

        if (monitor?.lastIpcObject.specialWorkspace?.name || monitor?.activeWorkspace?.toplevels.values.length > 0)
            return 0;

        return contentItem.Config.launcher.enabled ? contentItem.Config.launcher.dragThreshold : 0;
    }

    onHasFullscreenChanged: {
        screenState.launcher = false;
        screenState.session = false;
        panels.popouts.close();
    }

    name: "drawers"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: (fsTransitionProg > 0 && contentItem.Config.general.showOverFullscreen) || (hasSpecialWorkspace && hasFullscreenOnNormalWs) ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: screenState.launcher || screenState.session ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: hasFullscreen ? emptyRegion : regions

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    Behavior on fsTransitionProg {
        Anim {}
    }

    Behavior on surfaceColour {
        CAnim {}
    }

    EdgeGeometry {
        id: geometry

        bar: bar
        win: root
        configPosition: root.contentItem.Config.bar.position
    }

    Region {
        id: emptyRegion

        x: panels.notifications.x + geometry.insetLeft(root.borderThickness)
        y: panels.notifications.y + geometry.insetTop(root.borderThickness)
        width: panels.notifications.width
        height: panels.notifications.height

        Region {
            x: root.width - width
            y: panels.osdWrapper.y + root.borderThickness
            width: panels.osdWrapper.width * (1 - panels.osd.offsetScale) + root.borderThickness
            height: panels.osd.height
        }
    }

    Regions {
        id: regions

        geometry: geometry
        panels: panels
        win: root
    }

    HyprlandFocusGrab {
        id: focusGrab

        active: {
            const s = root.screenState;
            const conf = root.contentItem.Config;
            if ((s.launcher && conf.launcher.enabled) || (s.session && conf.session.enabled))
                return true;
            if (panels.popouts.currentName.startsWith("traymenu") && (panels.popouts.current as StackView)?.depth > 1)
                return true;
            return false;
        }
        windows: [root]
        onCleared: {
            root.screenState.launcher = false;
            root.screenState.session = false;
            panels.popouts.hasCurrent = false;
            bar.closeTray();
        }
    }

    StyledRect {
        anchors.fill: parent
        opacity: {
            const s = root.screenState;
            const dimSession = s.session && Config.session.enabled;
            const dimLauncher = s.launcher && Config.launcher.enabled && Config.launcher.dim;
            return dimSession || dimLauncher || panels.popouts.detachedMode !== "" ? root.dimOpacity : 0;
        }
        color: Colours.palette.m3scrim

        Behavior on opacity {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }

    Item {
        anchors.fill: parent
        opacity: root.surfaceColour.a
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 15
            shadowColor: Qt.alpha(Colours.palette.m3shadow, Math.max(0, root.shadowOpacity))
        }

        BlobGroup {
            id: blobGroup

            color: root.surfaceColour
            smoothing: root.contentItem.Config.border.smoothing
        }

        BlobInvertedRect {
            anchors.fill: parent
            anchors.margins: -50 // Make border thicker to smooth out bulge from closed drawers
            group: blobGroup
            radius: root.borderRounding
            borderLeft: geometry.insetLeft(root.borderThickness) - anchors.margins - root.sdfBorderOffset
            borderRight: geometry.insetRight(root.borderThickness) - anchors.margins - root.sdfBorderOffset
            borderTop: geometry.insetTop(root.borderThickness) - anchors.margins - root.sdfBorderOffset
            borderBottom: geometry.insetBottom(root.borderThickness) - anchors.margins - root.sdfBorderOffset
        }

        PanelBg {
            id: launcherBg

            readonly property bool spotlight: panels.launcher.spotlight

            panel: panels.launcher
            deformAmount: 0.1
            // Spotlight mode draws its own background inside the launcher wrapper
            // so it can be group-faded together with the search pill.
            visible: panel.visible && !spotlight
        }

        Item {
            id: osdClip

            // The OSD slides off to the right when it closes. Without clipping,
            // the moving capsule shows through the screen frame. Clip it to the
            // inner frame area without changing the widget's animation.
            width: root.width - geometry.insetRight(root.borderThickness) + 1
            height: root.height
            clip: true
            visible: panels.osd.visible

            PanelBg {
                id: osdBg

                panel: panels.osdWrapper
                deformAmount: 0.25
                x: panels.osdWrapper.x + panels.osd.x + geometry.insetLeft(root.borderThickness)
                implicitWidth: panels.osd.width + 1
                // Keep the OSD capsule independent from the screen frame. Merging
                // lets the blob smoothing bulge a section of the panel past the
                // frame while the OSD is moving.
                mergeWithInverted: false
            }
        }

        PanelBg {
            id: notifsBg

            panel: panels.notifications
        }

        PanelBg {
            id: utilsBg

            panel: panels.utilities
            deformAmount: 0.15
            implicitHeight: panel.height
            // Keep this panel independent from the screen frame. Letting the
            // blob smooth-merge into the frame deforms its inner edge and
            // leaves a dent where the panel ends. A standalone rounded card is
            // the original utilities panel look.
            mergeWithInverted: false
            // The background is drawn by this separate blob, not by the
            // wrapper, so it must follow the wrapper's visibility explicitly.
            visible: panel.visible
        }

        PanelBg {
            id: popoutBg

            // Extra extent to prevent axis movement deformation partially detaching panel from bar
            property real extraExtent: panels.popouts.isDetached ? 0 : 0.2
            // Once fully closed, stop merging with the bar so blob smoothing cannot leave a residual bump.
            // Keep merging while the spring is still settling so the bounce is preserved.
            readonly property bool fullyClosed: !panels.popouts.hasCurrent && !panels.popouts.isDetached && panels.popoutsWrapper.offsetScale >= 0.999

            panel: panels.popoutsWrapper
            deformAmount: panels.popouts.isDetached ? 0.05 : panels.popouts.hasCurrent ? 0.15 : 0.1
            mergeWithInverted: !fullyClosed || physicsActive
            visible: !fullyClosed || physicsActive
            x: panels.popoutsWrapper.x + panels.popouts.x + geometry.insetLeft(root.borderThickness) - (geometry.horizontal ? 0 : panels.popouts.width * extraExtent)
            y: panels.popoutsWrapper.y + panels.popouts.y + geometry.insetTop(root.borderThickness) - (geometry.barOnTop ? panels.popouts.height * extraExtent : 0)
            implicitWidth: panels.popouts.width * (geometry.horizontal ? 1 : 1 + extraExtent)
            implicitHeight: panels.popouts.height * (geometry.horizontal ? 1 + extraExtent : 1)

            Behavior on extraExtent {
                Anim {}
            }
        }
    }

    Interactions {
        id: interactions

        screen: root.screen
        popouts: panels.popouts
        screenState: root.screenState
        panels: panels
        bar: bar
        geometry: geometry
        borderThickness: root.borderLayoutThickness
        fullscreen: root.hasFullscreen

        Panels {
            id: panels

            screen: root.screen
            screenState: root.screenState
            bar: bar
            geometry: geometry
            borderThickness: root.borderThickness

            launcher.transform: Matrix4x4 {
                // The hidden launcher blob still tracks the wrapper and feeds
                // its velocity deformation matrix back into the transform,
                // which makes the spotlight visibly shear/rotate. The spotlight
                // draws its own background, so only apply the blob transform in
                // regular panel mode.
                matrix: panels.launcher.spotlight ? Qt.matrix4x4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) : launcherBg.deformMatrix
            }
            osd.transform: Matrix4x4 {
                matrix: osdBg.deformMatrix
            }
            notifications.transform: Matrix4x4 {
                matrix: notifsBg.deformMatrix
            }
            utilities.transform: Matrix4x4 {
                matrix: utilsBg.deformMatrix
            }
            popouts.transform: Matrix4x4 {
                matrix: popoutBg.deformMatrix
            }
        }

        BarWrapper {
            id: bar

            // Anchored on one corner and sized by binding: an opposing pair of anchors sizes the
            // item instead, and keeps that size once the pair is dropped
            anchors.left: parent.left
            anchors.top: geometry.barOnBottom ? undefined : parent.top
            anchors.bottom: geometry.barOnBottom ? parent.bottom : undefined

            width: geometry.horizontal ? parent.width : implicitWidth
            height: geometry.horizontal ? implicitHeight : parent.height

            screen: root.screen
            screenState: root.screenState
            popouts: panels.popouts
            position: geometry.position

            fullscreen: root.hasFullscreen
        }
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "rootWindow"
        component: root
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "interactionWrapper"
        component: interactions
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "bar"
        component: bar
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "panels"
        component: panels
    }

    component PanelBg: BlobRect {
        required property Item panel
        property real deformAmount: 0.15

        group: blobGroup
        x: panel.x + geometry.insetLeft(root.borderThickness)
        y: panel.y + geometry.insetTop(root.borderThickness)
        implicitWidth: panel.width
        implicitHeight: panel.height
        radius: Tokens.rounding.extraLarge
        deformScale: (deformAmount * Config.appearance.deformScale) / 10000
    }
}
