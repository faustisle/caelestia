import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

RowLayout {
    id: root

    required property var lock

    readonly property real sideWidth: Math.round(width * Tokens.sizes.lock.sideWidthRatio)

    spacing: Tokens.spacing.largeIncreased * 2

    Center {
        lock: root.lock
    }

    Item {
        Layout.fillWidth: true
    }

    ColumnLayout {
        Layout.preferredWidth: root.sideWidth
        Layout.maximumWidth: root.sideWidth
        Layout.fillHeight: true
        spacing: Tokens.spacing.medium

        Resources {
            Layout.fillWidth: true
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            bottomRightRadius: Tokens.rounding.extraLarge
            radius: Tokens.rounding.medium
            color: Colours.tPalette.m3surfaceContainer

            NotifDock {
                lock: root.lock
            }
        }
    }
}
