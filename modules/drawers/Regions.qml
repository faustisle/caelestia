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

    x: geometry.insetLeft(clampedThickness, true)
    y: geometry.insetTop(clampedThickness, true)
    width: win.width - geometry.insetLeft(clampedThickness, true) - geometry.insetRight(clampedThickness, true)
    height: win.height - geometry.insetTop(clampedThickness, true) - geometry.insetBottom(clampedThickness, true)
    intersection: Intersection.Xor

    // Keep a small input hotspot at the top-right corner for the quick settings
    // hover trigger, even when the base region starts below the screen border.
    // The root region is XORed against the window, so subtracting the hotspot
    // from the base is what adds it to the final input mask.
    Region {
        x: root.win.width - 25
        y: 0
        width: 25
        height: 25
        intersection: Intersection.Subtract
    }

    Region {
        // The bar lives directly in the interaction window, unlike the panels,
        // which are already inset by EdgeGeometry. Adding the inset here shifts
        // the input area below the actual bar and steals clicks from window
        // controls.
        x: root.win.bar.x
        y: root.win.bar.y
        width: root.win.bar.width
        height: root.win.bar.height
        intersection: Intersection.Subtract
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
        y: 0
        width: panel.width + root.borderThickness
        height: panel.height * (1 - root.panels.utilities.offsetScale) + root.borderThickness
    }

    // The popout sits flush against the bar edge. Derive its mask from the final
    // size and the bar edge rather than from the animated geometry: while the
    // popout reveals, its position and height update on separate bindings and
    // can momentarily leave a one-pixel hole between the bar and the popout,
    // which makes the cursor leave the input region and closes the popout.
    // Detached popouts float in the center, so keep their animated geometry.
    R {
        readonly property bool detached: panel.content.isDetached // qmllint disable missing-property
        // A deactivated loader can keep its last implicit size, so gate the mask
        // on the popout actually being open or detached instead of the size alone.
        readonly property bool shown: detached || root.panels.popouts.hasCurrent

        panel: root.panels.popoutsWrapper

        x: root.geometry.horizontal || detached ? panel.x + root.geometry.insetLeft(root.borderThickness) : root.x
        y: detached ? panel.y + root.geometry.insetTop(root.borderThickness) : root.geometry.horizontal ? (root.geometry.barOnTop ? root.y : root.y + root.height - height) : panel.y + root.geometry.insetTop(root.borderThickness)
        width: shown ? (detached ? panel.width : panel.content.nonAnimWidth) : 0 // qmllint disable missing-property
        height: shown ? (detached ? panel.height : panel.content.nonAnimHeight) : 0 // qmllint disable missing-property
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
