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
    readonly property real scaleFactor: 1.8
    readonly property real contentWidth: content.implicitWidth || Tokens.sizes.session.button * 4 + Tokens.spacing.large * 3 + Tokens.padding.large * 2
    readonly property real contentHeight: content.implicitHeight || Tokens.sizes.session.button + Tokens.padding.large * 2

    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    implicitWidth: contentWidth * scaleFactor
    implicitHeight: contentHeight * scaleFactor
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
        id: scaledContent

        anchors.centerIn: parent
        width: root.contentWidth
        height: root.contentHeight
        scale: root.scaleFactor

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

            anchors.fill: parent
            active: root.shouldBeActive || root.visible

            sourceComponent: Content {
                screenState: root.screenState
            }
        }
    }
}
