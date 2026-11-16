pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property var iconsConfig: Config.background.desktopIcons

    readonly property list<MenuItem> positionItems: [
        MenuItem {
            text: Tr.trCtx("Top left", "desktop icon position")
            icon: "north_west"
            value: "top-left"
        },
        MenuItem {
            text: Tr.trCtx("Top right", "desktop icon position")
            icon: "north_east"
            value: "top-right"
        },
        MenuItem {
            text: Tr.trCtx("Bottom left", "desktop icon position")
            icon: "south_west"
            value: "bottom-left"
        },
        MenuItem {
            text: Tr.trCtx("Bottom right", "desktop icon position")
            icon: "south_east"
            value: "bottom-right"
        }
    ]

    title: Tr.tr("Desktop icons")
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
            subtext: Tr.tr("Show application shortcuts from your desktop folder")
            checked: root.iconsConfig.enabled
            onToggled: GlobalConfig.background.desktopIcons.enabled = checked
        }

        ToggleRow {
            text: Tr.tr("Show labels")
            subtext: Tr.tr("Show app names under the icons")
            checked: root.iconsConfig.showLabels
            onToggled: GlobalConfig.background.desktopIcons.showLabels = checked
        }

        StepperRow {
            label: Tr.tr("Icon size")
            subtext: Tr.tr("Size of the icons (px)")
            value: root.iconsConfig.iconSize
            from: 24
            to: 128
            stepSize: 4
            onMoved: value => GlobalConfig.background.desktopIcons.iconSize = Math.round(value)
        }

        SelectRow {
            last: true
            label: Tr.tr("Position")
            subtext: Tr.tr("Corner of the desktop where shortcuts start")
            menuItems: root.positionItems
            active: root.positionItems.find(item => item.value === root.iconsConfig.position) ?? root.positionItems[1]
            onSelected: item => GlobalConfig.background.desktopIcons.position = item.value
        }
    }
}
