pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<MenuItem> accelItems: [
        MenuItem {
            text: Tr.trCtx("Adaptive", "mouse acceleration profile")
            value: "adaptive"
        },
        MenuItem {
            text: Tr.trCtx("Flat", "mouse acceleration profile")
            value: "flat"
        }
    ]

    readonly property list<MenuItem> scrollItems: [
        MenuItem {
            text: Tr.trCtx("Two finger", "touchpad scroll method")
            value: "2fg"
        },
        MenuItem {
            text: Tr.trCtx("Edge", "touchpad scroll method")
            value: "edge"
        },
        MenuItem {
            text: Tr.trCtx("On button down", "touchpad scroll method")
            value: "on_button_down"
        },
        MenuItem {
            text: Tr.trCtx("None", "touchpad scroll method")
            value: "no_scroll"
        }
    ]

    title: Tr.tr("Input")
    isSubPage: false

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Mouse")
        }

        SliderRow {
            first: true
            icon: "mouse"
            label: Tr.tr("Pointer speed")
            valueLabel: HyprInput.sensitivity.toFixed(2)
            value: HyprInput.sensitivity
            from: -1
            to: 1
            stepSize: 0.05
            onMoved: value => HyprInput.setSensitivity(value)
        }

        SelectRow {
            last: true
            label: Tr.tr("Acceleration profile")
            subtext: Tr.tr("How pointer movement accelerates with speed")
            menuItems: root.accelItems
            active: root.accelItems.find(item => item.value === HyprInput.accelProfile) ?? root.accelItems[0]
            onSelected: item => HyprInput.setAccelProfile(item.value)
        }

        SectionHeader {
            text: Tr.tr("Touchpad")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Tap to click")
            subtext: Tr.tr("Tapping the touchpad clicks the pointer")
            checked: HyprInput.tapToClick
            onToggled: HyprInput.setTapToClick(checked)
        }

        ToggleRow {
            text: Tr.tr("Tap and drag")
            subtext: Tr.tr("Tap and move a finger to drag")
            checked: HyprInput.tapAndDrag
            onToggled: HyprInput.setTapAndDrag(checked)
        }

        ToggleRow {
            text: Tr.tr("Natural scrolling")
            subtext: Tr.tr("Reverse the scrolling direction")
            checked: HyprInput.naturalScroll
            onToggled: HyprInput.setNaturalScroll(checked)
        }

        ToggleRow {
            text: Tr.tr("Disable while typing")
            subtext: Tr.tr("Ignore touchpad input while typing")
            checked: HyprInput.disableWhileTyping
            onToggled: HyprInput.setDisableWhileTyping(checked)
        }

        SelectRow {
            last: true
            label: Tr.tr("Scroll method")
            subtext: Tr.tr("How the touchpad scrolls")
            menuItems: root.scrollItems
            active: root.scrollItems.find(item => item.value === HyprInput.scrollMethod) ?? root.scrollItems[0]
            onSelected: item => HyprInput.setScrollMethod(item.value)
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large
            text: Tr.tr("Saved by Caelestia and reapplied when the shell starts.")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }
    }
}
