pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.modules.launcher.services

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property var panels

    readonly property bool shouldBeActive: screenState.launcher && Config.launcher.enabled
    readonly property bool spotlight: Config.launcher.spotlight

    readonly property real maxHeight: screen.height - Config.border.thickness * 2 + Tokens.padding.extraLarge;

    // Sit a third of the way down the screen while results grow downwards from the search bar
    readonly property real spotlightTopMargin: {
        const searchCenter = content.item?.searchCenterOffset ?? implicitHeight / 2;
        return Math.max(0, (parent?.height ?? screen.height) / 3 - searchCenter);
    }

    property real offsetScale: shouldBeActive ? 0 : 1

    onShouldBeActiveChanged: {
        if (shouldBeActive)
            implicitHeight = Qt.binding(() => content.implicitHeight);
        else
            implicitHeight = implicitHeight; // Break binding during close anim
    }

    visible: offsetScale < 1
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: spotlight ? 0 : (-implicitHeight - 5) * offsetScale
    anchors.topMargin: spotlight ? spotlightTopMargin + Tokens.spacing.small * offsetScale : 0
    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth || 630 // Hard coded fallback for first open
    opacity: 1 - offsetScale

    states: [
        State {
            name: "regular"
            when: !root.spotlight

            AnchorChanges {
                target: root
                anchors.top: undefined
                anchors.bottom: parent.bottom
            }
        },
        State {
            name: "spotlight"
            when: root.spotlight

            AnchorChanges {
                target: root
                anchors.bottom: undefined
                anchors.top: parent.top
            }
        }
    ]

    Component.onCompleted: Qt.callLater(() => Apps) // Load apps on init

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screenState: root.screenState
            panels: root.panels
            maxHeight: root.maxHeight
        }
    }
}
