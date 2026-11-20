pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import qs.components
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts

    readonly property bool shouldBeActive: screenState.utilities && Config.utilities.enabled && !(screenState.session && Config.session.enabled)
    readonly property real totalPadding: content.anchors.margins * 2
    readonly property real nonAnimHeight: ((content.item as Content)?.nonAnimHeight ?? 0) + totalPadding
    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    // The original utilities panel slid in from the bottom-right corner. The
    // quick settings hover is at the top-right, so anchor and reveal it there.
    anchors.topMargin: (-implicitHeight - 5) * offsetScale
    implicitHeight: content.implicitHeight + totalPadding
    implicitWidth: Tokens.sizes.utilities.width
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: Tokens.padding.large

        asynchronous: true
        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            implicitWidth: root.implicitWidth - root.totalPadding
            screenState: root.screenState
            popouts: root.popouts
        }
    }
}
