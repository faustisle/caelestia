import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.modules.bar as Bar
import qs.modules.launcher as Launcher
import qs.modules.notifications as Notifications
import qs.modules.osd as Osd
import qs.modules.session as Session
import qs.modules.utilities as Utilities
import qs.modules.bar.popouts as BarPopouts
import qs.modules.utilities.toasts as Toasts

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property Bar.BarWrapper bar
    required property EdgeGeometry geometry
    required property real borderThickness

    readonly property alias osd: osd
    readonly property alias osdWrapper: osdWrapper
    readonly property alias notifications: notifications
    readonly property alias session: session
    readonly property alias sessionWrapper: sessionWrapper
    readonly property alias launcher: launcher
    readonly property alias popouts: popoutsWrapper.content
    readonly property alias popoutsWrapper: popoutsWrapper
    readonly property alias utilities: utilities
    readonly property alias toasts: toasts

    anchors.fill: parent
    anchors.leftMargin: geometry.insetLeft(borderThickness)
    anchors.topMargin: geometry.insetTop(borderThickness)
    anchors.rightMargin: geometry.insetRight(borderThickness)
    anchors.bottomMargin: geometry.insetBottom(borderThickness)

    Item {
        id: osdWrapper

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        clip: true

        implicitWidth: osd.implicitWidth * (1 - osd.offsetScale)
        implicitHeight: osd.implicitHeight

        Osd.Wrapper {
            id: osd

            screen: root.screen
            screenState: root.screenState
            panelOrSessionVisible: session.visible

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
        }
    }

    Notifications.Wrapper {
        id: notifications

        screenState: root.screenState
        rightPanel: utilities
        osdPanel: osdWrapper
        sessionPanel: sessionWrapper
        popoutsPanel: popoutsWrapper

        anchors.top: parent.top
        anchors.right: parent.right
    }

    Item {
        id: sessionWrapper

        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.geometry.barOnLeft ? -root.bar.implicitWidth / 2 : 0
        clip: utilities.visible

        implicitWidth: session.implicitWidth
        implicitHeight: session.implicitHeight

        Session.Wrapper {
            id: session

            screenState: root.screenState

            anchors.centerIn: parent
        }
    }

    Item {
        anchors.fill: parent
        // Keep the launcher's spawn animation from showing through the bar
        clip: true

        Launcher.Wrapper {
            id: launcher

            screen: root.screen
            screenState: root.screenState
            panels: root
            barOnBottom: root.geometry.barOnBottom
        }
    }

    BarPopouts.ClipWrapper {
        id: popoutsWrapper

        screen: root.screen
        screenState: root.screenState
        position: root.geometry.position
        borderThickness: root.borderThickness
    }

    Item {
        id: utilitiesClip

        anchors.fill: parent
        // Keep the quick settings reveal from showing through the bar modules
        // on top-bar layouts. This mirrors the launcher's spawn clipping.
        clip: true

        Utilities.Wrapper {
            id: utilities

            screenState: root.screenState
            popouts: popoutsWrapper.content

            topInset: notifications.height
            anchors.top: parent.top
            anchors.right: parent.right
        }
    }

    Toasts.Toasts {
        id: toasts

        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium + (utilities.visible ? utilities.width : 0)
    }
}
