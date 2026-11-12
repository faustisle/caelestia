pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property var panels
    required property var bar

    readonly property bool shouldBeActive: screenState.launcher && Config.launcher.enabled
    readonly property bool spotlight: Config.launcher.spotlight && !screenState.launcherRegular
    readonly property Item searchBar: content.item?.searchBar ?? null

    // Anchor the regular launcher to the panel launcher button instead of
    // hardcoding a screen corner, so it follows a movable bar.
    readonly property Item button: bar?.launcherButton ?? null
    readonly property real regularTopMargin: root.button && root.parent ? root.button.mapToItem(root.parent, 0, 0).y : 0

    readonly property real maxHeight: screen.height - Config.border.thickness * 2 + Tokens.padding.extraLarge

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
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.topMargin: (spotlight ? spotlightTopMargin : regularTopMargin) + Tokens.spacing.small * offsetScale
    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth || 630 // Hard coded fallback for first open
    opacity: 1 - offsetScale
    // Render the whole launcher offscreen while it fades so the blob and the
    // search pill are faded as one composited group instead of two translucent
    // layers stacking on top of each other.
    layer.enabled: root.spotlight

    states: [
        State {
            name: "regular"
            when: !root.spotlight

            AnchorChanges {
                target: root
                anchors.left: parent.left
                anchors.horizontalCenter: undefined
            }
        },
        State {
            name: "spotlight"
            when: root.spotlight

            AnchorChanges {
                target: root
                anchors.left: undefined
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    ]

    Component.onCompleted: Qt.callLater(() => Apps) // Load apps on init

    Behavior on offsetScale {
        Anim {}
    }

    // Keep the spotlight background inside the wrapper so it fades together
    // with the search pill as a single composited group.
    Item {
        id: spotlightBg

        anchors.fill: parent
        visible: root.spotlight
        opacity: Colours.tPalette.m3surface.a

        StyledRect {
            anchors.fill: parent
            color: Colours.tPalette.m3surface
            radius: Tokens.rounding.extraLarge
        }
    }

    // Mirrors the search pill so the background can be pre-composed with the
    // blob above. The real pill is made transparent in spotlight mode.
    StyledRect {
        id: spotlightSearchBg

        readonly property Item search: root.searchBar

        visible: root.spotlight && search !== null
        x: search?.x ?? 0
        y: search?.y ?? 0
        width: search?.width ?? 0
        height: search?.height ?? 0
        radius: Tokens.rounding.full
        color: Colours.tPalette.m3surfaceContainer
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screenState: root.screenState
            panels: root.panels
            spotlight: root.spotlight
            maxHeight: root.maxHeight
        }
    }
}
