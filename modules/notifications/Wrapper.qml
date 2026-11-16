import QtQuick
import Caelestia.Config
import qs.components

Item {
    id: root

    required property ScreenState screenState
    required property Item sidebarPanel
    required property Item popoutsPanel
    property alias osdPanel: content.osdPanel
    property alias sessionPanel: content.sessionPanel

    // Shift notifications left when an open popout would overlap their column.
    // Popouts are anchored to their bar entry, so moving the notifications keeps
    // both usable instead of stacking one behind the other.
    readonly property real popoutShift: {
        const p = popoutsPanel;
        if (!p || !p.visible || !p.content.hasCurrent || p.content.isDetached) // qmllint disable missing-property
            return 0;

        const notifWidth = content.implicitWidth;
        const notifHeight = content.implicitHeight;
        if (notifWidth <= 0 || notifHeight <= 0)
            return 0;

        const notifLeft = parent.width - notifWidth;
        if (p.y >= notifHeight || p.y + p.height <= 0)
            return 0;
        if (p.x >= parent.width || p.x + p.width <= notifLeft)
            return 0;

        return Math.max(0, Math.min(parent.width - p.x + Tokens.spacing.small, parent.width - notifWidth));
    }

    property real rightMargin: popoutShift

    visible: height > 0
    anchors.topMargin: -5
    anchors.rightMargin: rightMargin
    implicitWidth: Math.max(sidebarPanel.width, content.implicitWidth)
    implicitHeight: content.implicitHeight

    Behavior on rightMargin {
        Anim {}
    }

    Content {
        id: content

        anchors.topMargin: -root.anchors.topMargin
        screenState: root.screenState
    }
}
