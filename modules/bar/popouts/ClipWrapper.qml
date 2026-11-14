pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.modules.bar.popouts // Need to import this module so the Wrapper type is the same as others

Item {
    id: root

    required property ShellScreen screen
    required property string position
    required property real borderThickness

    readonly property alias content: content
    readonly property bool horizontal: position === "top" || position === "bottom"
    readonly property bool barOnRight: position === "right"
    property real offsetScale: content.hasCurrent || content.isDetached ? 0 : 1

    visible: width > 0 && height > 0
    clip: true

    implicitWidth: horizontal ? content.implicitWidth : content.implicitWidth * (1 - offsetScale)
    implicitHeight: horizontal ? content.implicitHeight * (1 - offsetScale) : content.implicitHeight

    x: {
        if (content.isDetached)
            return (parent.width - content.nonAnimWidth) / 2;
        if (!horizontal)
            return barOnRight ? parent.width - implicitWidth : 0;

        const off = content.currentCenter - borderThickness - content.nonAnimWidth / 2;
        const diff = parent.width - Math.floor(off + content.nonAnimWidth);
        if (diff < 0)
            return off + diff;
        return Math.max(off, 0);
    }
    y: {
        if (content.isDetached)
            return (parent.height - content.nonAnimHeight) / 2;
        if (horizontal)
            return position === "bottom" ? parent.height - implicitHeight : 0;

        const off = content.currentCenter - borderThickness - content.nonAnimHeight / 2;
        const diff = parent.height - Math.floor(off + content.nonAnimHeight);
        if (diff < 0)
            return off + diff;
        return Math.max(off, 0);
    }

    Behavior on offsetScale {
        Anim {}
    }

    Behavior on x {
        enabled: !root.horizontal || root.offsetScale < 1

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Behavior on y {
        enabled: !root.horizontal && root.offsetScale < 1

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Wrapper {
        id: content

        screen: root.screen
        offsetScale: root.offsetScale

        // Only the anchors for the current bar edge resolve, the others are undefined
        // qmllint disable Quick.anchor-combinations
        anchors.verticalCenter: root.horizontal ? undefined : parent.verticalCenter
        anchors.horizontalCenter: root.horizontal ? parent.horizontalCenter : undefined
        anchors.left: !root.horizontal && !root.barOnRight ? parent.left : undefined
        anchors.right: !root.horizontal && root.barOnRight ? parent.right : undefined
        anchors.top: root.horizontal && root.position === "top" ? parent.top : undefined
        anchors.bottom: root.horizontal && root.position === "bottom" ? parent.bottom : undefined
        // qmllint enable Quick.anchor-combinations
        anchors.leftMargin: !root.horizontal && !root.barOnRight ? (-implicitWidth - 5) * root.offsetScale : 0
        anchors.rightMargin: !root.horizontal && root.barOnRight ? (-implicitWidth - 5) * root.offsetScale : 0
        anchors.topMargin: root.horizontal && root.position === "top" ? (-implicitHeight - 5) * root.offsetScale : 0
        anchors.bottomMargin: root.horizontal && root.position === "bottom" ? (-implicitHeight - 5) * root.offsetScale : 0
    }
}
