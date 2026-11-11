pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property ScreenState screenState

    readonly property bool shouldBeActive: screenState.session && Config.session.enabled

    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    implicitWidth: content.implicitWidth || Tokens.sizes.session.button * 4 + Tokens.spacing.large * 3 + Tokens.padding.large * 2
    implicitHeight: content.implicitHeight || Tokens.sizes.session.button + Tokens.padding.large * 2
    opacity: 1 - offsetScale

    // Fade the background and buttons as a single composited group, matching
    // the spotlight launcher.
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        blurMax: 15
        shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
    }

    Behavior on offsetScale {
        Anim {}
    }

    Item {
        id: background

        anchors.fill: parent
        opacity: Colours.tPalette.m3surface.a

        StyledRect {
            anchors.fill: parent
            color: Colours.tPalette.m3surface
            radius: Tokens.rounding.extraLarge
        }
    }

    Loader {
        id: content

        anchors.centerIn: parent
        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screenState: root.screenState
        }
    }
}
