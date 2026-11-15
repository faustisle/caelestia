pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config

Region {
    id: root

    required property EdgeGeometry geometry
    required property Panels panels
    required property var win

    readonly property real borderThickness: win.contentItem.Config.border.thickness
    readonly property real clampedThickness: win.contentItem.Config.border.clampedThickness

    x: geometry.insetLeft(clampedThickness, true) + win.dragMaskPadding
    y: geometry.insetTop(clampedThickness, true) + win.dragMaskPadding
    width: win.width - geometry.insetLeft(clampedThickness, true) - geometry.insetRight(clampedThickness, true) - win.dragMaskPadding * 2
    height: win.height - geometry.insetTop(clampedThickness, true) - geometry.insetBottom(clampedThickness, true) - win.dragMaskPadding * 2
    intersection: Intersection.Xor

    // Keep a small input hotspot at the top-right corner for the sidebar hover
    // trigger, even when the base region starts below the screen border.
    Region {
        x: root.win.width - 50
        y: 0
        width: 50
        height: 50
        intersection: Intersection.Combine
    }

    R {
        panel: root.panels.launcher
        // A closed launcher must not contribute any clickable area, otherwise
        // its last size leaves an invisible strip that steals clicks.
        height: panel.visible ? panel.height : 0
    }

    R {
        panel: root.panels.sessionWrapper
        x: panel.x + root.geometry.insetLeft(root.borderThickness) + (panel.width - width) / 2
        width: panel.width * (1 - root.panels.session.offsetScale)
    }

    R {
        id: sidebarRegion

        panel: root.panels.sidebar
        x: root.win.width - width
        width: panel.width * (1 - root.panels.sidebar.offsetScale) + root.borderThickness
    }

    R {
        panel: root.panels.osdWrapper
        x: root.win.width - width
        width: panel.width * (1 - root.panels.osd.offsetScale) + root.borderThickness
    }

    R {
        panel: root.panels.notifications
        y: 0
        height: panel.height + root.geometry.insetTop(root.borderThickness)
    }

    R {
        panel: root.panels.utilities
        x: root.win.width - width
        width: panel.width * (1 - root.panels.utilities.offsetScale) + root.borderThickness
    }

    R {
        panel: root.panels.popoutsWrapper
        width: root.geometry.horizontal ? panel.width : panel.width * (1 - root.panels.popoutsWrapper.offsetScale)
        height: root.geometry.horizontal ? panel.height * (1 - root.panels.popoutsWrapper.offsetScale) : panel.height
    }

    component R: Region {
        required property Item panel

        x: panel.x + root.geometry.insetLeft(root.borderThickness)
        y: panel.y + root.geometry.insetTop(root.borderThickness)
        width: panel.width
        height: panel.height
        intersection: Intersection.Subtract
    }
}
