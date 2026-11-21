pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property var clock: Config.background.desktopClock

    readonly property list<MenuItem> positionItems: [
        MenuItem {
            text: Tr.trCtx("Top left", "desktop clock position")
            icon: "north_west"
            value: "top-left"
        },
        MenuItem {
            text: Tr.trCtx("Top center", "desktop clock position")
            icon: "north"
            value: "top-center"
        },
        MenuItem {
            text: Tr.trCtx("Top right", "desktop clock position")
            icon: "north_east"
            value: "top-right"
        },
        MenuItem {
            text: Tr.trCtx("Middle left", "desktop clock position")
            icon: "west"
            value: "middle-left"
        },
        MenuItem {
            text: Tr.trCtx("Middle center", "desktop clock position")
            icon: "center_focus_strong"
            value: "middle-center"
        },
        MenuItem {
            text: Tr.trCtx("Middle right", "desktop clock position")
            icon: "east"
            value: "middle-right"
        },
        MenuItem {
            text: Tr.trCtx("Bottom left", "desktop clock position")
            icon: "south_west"
            value: "bottom-left"
        },
        MenuItem {
            text: Tr.trCtx("Bottom center", "desktop clock position")
            icon: "south"
            value: "bottom-center"
        },
        MenuItem {
            text: Tr.trCtx("Bottom right", "desktop clock position")
            icon: "south_east"
            value: "bottom-right"
        }
    ]

    title: Tr.tr("Desktop clock")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("General")
        }

        ToggleRow {
            first: true
            text: Tr.trCtx("Enabled", "toggle label")
            subtext: Tr.tr("Show the clock on the desktop")
            checked: root.clock.enabled
            onToggled: GlobalConfig.background.desktopClock.enabled = checked
        }

        SelectRow {
            label: Tr.tr("Position")
            subtext: Tr.tr("Corner or edge where the clock sits")
            menuItems: root.positionItems
            active: root.positionItems.find(item => item.value === root.clock.position) ?? root.positionItems[8]
            onSelected: item => GlobalConfig.background.desktopClock.position = item.value
        }

        SliderRow {
            icon: "zoom_out_map"
            label: Tr.tr("Scale")
            valueLabel: `${Math.round(root.clock.scale * 100)}%`
            value: root.clock.scale
            from: 0.5
            to: 2
            stepSize: 0.05
            onMoved: value => GlobalConfig.background.desktopClock.scale = value
        }

        ToggleRow {
            last: true
            text: Tr.tr("Invert colours")
            subtext: Tr.tr("Use darker clock colours on light wallpapers")
            checked: root.clock.invertColors
            onToggled: GlobalConfig.background.desktopClock.invertColors = checked
        }

        SectionHeader {
            text: Tr.tr("Background")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Show background")
            subtext: Tr.tr("Place a soft plate behind the clock")
            checked: root.clock.background.enabled
            onToggled: GlobalConfig.background.desktopClock.background.enabled = checked
        }

        SliderRow {
            icon: "opacity"
            label: Tr.tr("Opacity")
            valueLabel: `${Math.round(root.clock.background.opacity * 100)}%`
            value: root.clock.background.opacity
            from: 0
            to: 1
            stepSize: 0.05
            enabled: root.clock.background.enabled
            onMoved: value => GlobalConfig.background.desktopClock.background.opacity = value
        }

        ToggleRow {
            last: true
            text: Tr.tr("Blur wallpaper")
            subtext: Tr.tr("Blur the wallpaper behind the clock background")
            checked: root.clock.background.blur
            enabled: root.clock.background.enabled
            onToggled: GlobalConfig.background.desktopClock.background.blur = checked
        }

        SectionHeader {
            text: Tr.tr("Shadow")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Show shadow")
            subtext: Tr.tr("Add a soft shadow behind the clock")
            checked: root.clock.shadow.enabled
            onToggled: GlobalConfig.background.desktopClock.shadow.enabled = checked
        }

        SliderRow {
            icon: "opacity"
            label: Tr.tr("Opacity")
            valueLabel: `${Math.round(root.clock.shadow.opacity * 100)}%`
            value: root.clock.shadow.opacity
            from: 0
            to: 1
            stepSize: 0.05
            enabled: root.clock.shadow.enabled
            onMoved: value => GlobalConfig.background.desktopClock.shadow.opacity = value
        }

        SliderRow {
            last: true
            icon: "blur_on"
            label: Tr.tr("Blur")
            valueLabel: `${Math.round(root.clock.shadow.blur * 100)}%`
            value: root.clock.shadow.blur
            from: 0
            to: 1
            stepSize: 0.05
            enabled: root.clock.shadow.enabled
            onMoved: value => GlobalConfig.background.desktopClock.shadow.blur = value
        }
    }
}
