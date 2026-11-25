import QtQuick
import Caelestia.Config
import qs.services

ColorAnimation {
    duration: Tokens.anim.durations.expressiveSlowEffects
    easing: Theme.fluent ? Tokens.anim.standard : Tokens.anim.expressiveSlowEffects
}
