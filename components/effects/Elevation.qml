import QtQuick
import QtQuick.Effects
import qs.components
import qs.services

RectangularShadow {
    property int level
    property real dp: [0, 1, 3, 6, 8, 12][level]

    color: Qt.alpha(Colours.palette.m3shadow, Theme.shadowOpacity)
    blur: (dp * 5) ** 0.7 * (Theme.fluent ? 1.35 : 1)
    spread: Theme.fluent ? -dp * 0.22 : -dp * 0.3 + (dp * 0.1) ** 2
    offset.y: dp / (Theme.fluent ? 3 : 2)

    Behavior on dp {
        Anim {
            type: Anim.SlowEffects
        }
    }
}
