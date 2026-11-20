import QtQuick
import QtQuick.Controls
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.bar as Bar
import qs.modules.bar.popouts as BarPopouts

CustomMouseArea {
    id: root

    required property ShellScreen screen
    required property BarPopouts.Wrapper popouts
    required property ScreenState screenState
    required property Panels panels
    required property Bar.BarWrapper bar
    required property EdgeGeometry geometry
    required property real borderThickness
    required property bool fullscreen

    property point dragStart
    property bool osdShortcutActive
    property bool utilitiesShortcutActive

    function withinPanelHeight(panel: Item, x: real, y: real): bool {
        const panelY = geometry.insetTop(borderThickness) + panel.y;
        return y >= panelY - Config.border.rounding && y <= panelY + panel.height + Config.border.rounding;
    }

    function withinPanelWidth(panel: Item, x: real, y: real): bool {
        const panelX = geometry.insetLeft(borderThickness) + panel.x;
        return x >= panelX - Config.border.rounding && x <= panelX + panel.width + Config.border.rounding;
    }

    function inLeftPanel(panel: Item, x: real, y: real): bool {
        return x < geometry.insetLeft(borderThickness) + panel.x + panel.width && withinPanelHeight(panel, x, y);
    }

    // A vertical bar's popout starts at the screen edge, so a one-sided bound is enough for it.
    // A horizontal bar's is centred on the hovered entry, so it needs bounding on both sides.
    function inPopoutArea(x: real, y: real): bool {
        const panel = panels.popoutsWrapper;
        if (!geometry.horizontal)
            return inLeftPanel(panel, x, y);
        return withinPanelWidth(panel, x, y) && withinPanelHeight(panel, x, y);
    }

    function inRightPanel(panel: Item, x: real, y: real): bool {
        return x > Math.min(width - Config.border.minThickness, geometry.insetLeft(borderThickness) + panel.x) && withinPanelHeight(panel, x, y);
    }

    function inOsdArea(x: real, y: real): bool {
        return inRightPanel(panels.osdWrapper, x, y);
    }

    function inBottomPanel(panel: Item, x: real, y: real): bool {
        const panelHeight = panel.height * (1 - (panel.offsetScale ?? 0)); // qmllint disable missing-property
        return y > height - Math.max(Config.border.minThickness, geometry.insetBottom(Config.border.thickness) + panelHeight) && withinPanelWidth(panel, x, y);
    }

    function inUtilitiesHoverTrigger(x: real, y: real): bool {
        const size = 25;
        return x > width - size && y <= size;
    }

    function onWheel(event: WheelEvent): void {
        if (fullscreen)
            return;
        if (geometry.barContains(event.x, event.y)) {
            bar.handleWheel(geometry.axisPos(event.x, event.y), event.angleDelta);
        }
    }

    anchors.fill: parent
    acceptedButtons: fullscreen ? Qt.NoButton : Qt.AllButtons
    hoverEnabled: true

    onPressed: event => dragStart = Qt.point(event.x, event.y)
    onClicked: event => {
        if (geometry.barContains(event.x, event.y)) {
            bar.togglePopout(geometry.axisPos(event.x, event.y));
            return;
        }

        if (event.button === Qt.RightButton) {
            const background = ShellState.componentsFor(root.screen)?.background;
            if (background)
                background.openDesktopMenu(event.x, event.y);
        }
    }
    onContainsMouseChanged: {
        if (!containsMouse) {
            // Only hide if not activated by shortcut
            if (!osdShortcutActive) {
                screenState.osd = false;
                root.panels.osd.hovered = false;
            }

            if (!utilitiesShortcutActive)
                screenState.utilities = false;

            if (!popouts.currentName.startsWith("traymenu") || ((popouts.current as StackView)?.depth ?? 0) <= 1) {
                popouts.hasCurrent = false;
                bar.closeTray();
            }

            if (Config.bar.showOnHover)
                bar.isHovered = false;
        }
    }

    onPositionChanged: event => {
        if (popouts.isDetached)
            return;

        const x = event.x;
        const y = event.y;
        const dragX = x - dragStart.x;
        const dragY = y - dragStart.y;

        if (fullscreen) {
            root.panels.osd.hovered = inOsdArea(x, y);
            return;
        }

        // Show bar in non-exclusive mode on hover
        if (!screenState.bar && Config.bar.showOnHover && geometry.barContains(x, y, true))
            bar.isHovered = true;

        // Show/hide bar on drag
        if (pressed && geometry.barContains(dragStart.x, dragStart.y, true)) {
            const barDrag = geometry.inwardDrag(dragX, dragY);
            if (barDrag > Config.bar.dragThreshold)
                screenState.bar = true;
            else if (barDrag < -Config.bar.dragThreshold)
                screenState.bar = false;
        }

        // The OSD is independent of quick settings. It stays up for its normal
        // timeout instead of retracting when the quick settings panel opens.
        const showOsd = inOsdArea(x, y);

        // Always update visibility based on hover if not in shortcut mode
        if (!osdShortcutActive) {
            screenState.osd = showOsd;
            root.panels.osd.hovered = showOsd;
        } else if (showOsd) {
            // If hovering over OSD area while in shortcut mode, transition to hover control
            osdShortcutActive = false;
            root.panels.osd.hovered = true;
        }

        // Show quick settings on hover at the top-right corner. The panel is
        // anchored there and expands downwards out of the corner.
        if (Config.utilities.showOnHover && Config.utilities.enabled && !pressed && !popouts.hasCurrent && !popouts.isDetached && !(panels.notifications.visible && inRightPanel(panels.notifications, x, y))) {
            const showUtilitiesHover = inUtilitiesHoverTrigger(x, y);
            if (showUtilitiesHover) {
                if (!screenState.utilities)
                    screenState.utilities = true;
                else if (utilitiesShortcutActive)
                    utilitiesShortcutActive = false; // Transition from shortcut to hover control
            } else if (!utilitiesShortcutActive) {
                const inUtilitiesArea = inRightPanel(panels.utilities, x, y) || inRightPanel(panels.notifications, x, y);
                if (!inUtilitiesArea)
                    screenState.utilities = false;
            }
        }

        // Show launcher on hover, or show/hide on drag if hover is disabled
        if (Config.launcher.showOnHover) {
            if (!screenState.launcher && inBottomPanel(panels.launcher, x, y) && !(geometry.barOnBottom && geometry.barContains(x, y)))
                screenState.launcher = true;
        } else if (pressed && inBottomPanel(panels.launcher, dragStart.x, dragStart.y) && !(geometry.barOnBottom && geometry.barContains(dragStart.x, dragStart.y)) && withinPanelWidth(panels.launcher, x, y)) {
            if (dragY < -Config.launcher.dragThreshold)
                screenState.launcher = true;
            else if (dragY > Config.launcher.dragThreshold)
                screenState.launcher = false;
        }

        // Show popouts on hover
        if (geometry.barContains(x, y)) {
            bar.checkPopout(geometry.axisPos(x, y));
        } else if ((!popouts.currentName.startsWith("traymenu") || ((popouts.current as StackView)?.depth ?? 0) <= 1) && !inPopoutArea(x, y)) {
            popouts.hasCurrent = false;
            bar.closeTray();
        }
    }

    // Monitor individual visibility changes
    Connections {
        function onLauncherChanged() {
            // If launcher is hidden, clear shortcut flags for OSD
            if (!root.screenState.launcher) {
                root.osdShortcutActive = false;
                root.utilitiesShortcutActive = false;

                // Also hide OSD if it's not being hovered
                const inOsdArea = root.inOsdArea(root.mouseX, root.mouseY);

                if (!inOsdArea) {
                    root.screenState.osd = false;
                    root.panels.osd.hovered = false;
                }
            }
        }

        function onOsdChanged() {
            if (root.screenState.osd) {
                // OSD became visible, immediately check if this should be shortcut mode
                const inOsdArea = root.inOsdArea(root.mouseX, root.mouseY);
                if (!inOsdArea) {
                    root.osdShortcutActive = true;
                }
            } else {
                // OSD hidden, clear shortcut flag
                root.osdShortcutActive = false;
            }
        }

        function onUtilitiesChanged() {
            if (root.screenState.utilities) {
                // Utilities became visible, immediately check if this should be shortcut mode
                const inUtilitiesArea = root.inRightPanel(root.panels.utilities, root.mouseX, root.mouseY) || root.inUtilitiesHoverTrigger(root.mouseX, root.mouseY);
                if (!inUtilitiesArea) {
                    root.utilitiesShortcutActive = true;
                }
            } else {
                // Utilities hidden, clear shortcut flag
                root.utilitiesShortcutActive = false;
            }
        }

        target: root.screenState
    }
}
