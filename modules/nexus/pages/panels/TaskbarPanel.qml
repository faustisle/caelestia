pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<MenuItem> positionItems: [
        MenuItem {
            text: Tr.tr("Left")
            value: "left"
        },
        MenuItem {
            text: Tr.tr("Top")
            value: "top"
        },
        MenuItem {
            text: Tr.tr("Bottom")
            value: "bottom"
        }
    ]

    readonly property list<MenuItem> logoItems: [
        MenuItem {
            text: Tr.tr("Auto (distro)")
            value: ""
            image: SysInfo.osLogo
        },
        MenuItem {
            text: Tr.tr("Caelestia")
            value: "caelestia"
            image: Qt.resolvedUrl("../../../../assets/logo.svg")
        },
        MenuItem {
            text: "Arch Linux"
            value: "distro:archlinux"
            image: Qt.resolvedUrl("../../../../assets/logos/archlinux.svg")
        },
        MenuItem {
            text: "CachyOS"
            value: "distro:cachyos"
            image: Qt.resolvedUrl("../../../../assets/logos/cachyos.svg")
        },
        MenuItem {
            text: "EndeavourOS"
            value: "distro:endeavouros"
            image: Qt.resolvedUrl("../../../../assets/logos/endeavouros.svg")
        },
        MenuItem {
            text: "Manjaro"
            value: "distro:manjaro"
            image: Qt.resolvedUrl("../../../../assets/logos/manjaro.svg")
        },
        MenuItem {
            text: "Debian"
            value: "distro:debian"
            image: Qt.resolvedUrl("../../../../assets/logos/debian.svg")
        },
        MenuItem {
            text: "Ubuntu"
            value: "distro:ubuntu"
            image: Qt.resolvedUrl("../../../../assets/logos/ubuntu.svg")
        },
        MenuItem {
            text: "Linux Mint"
            value: "distro:linuxmint"
            image: Qt.resolvedUrl("../../../../assets/logos/linuxmint.svg")
        },
        MenuItem {
            text: "Pop!_OS"
            value: "distro:popos"
            image: Qt.resolvedUrl("../../../../assets/logos/popos.svg")
        },
        MenuItem {
            text: "Fedora"
            value: "distro:fedora"
            image: Qt.resolvedUrl("../../../../assets/logos/fedora.svg")
        },
        MenuItem {
            text: "openSUSE"
            value: "distro:opensuse"
            image: Qt.resolvedUrl("../../../../assets/logos/opensuse.svg")
        },
        MenuItem {
            text: "NixOS"
            value: "distro:nixos"
            image: Qt.resolvedUrl("../../../../assets/logos/nixos.svg")
        },
        MenuItem {
            text: "Gentoo"
            value: "distro:gentoo"
            image: Qt.resolvedUrl("../../../../assets/logos/gentoo.svg")
        },
        MenuItem {
            text: "Void Linux"
            value: "distro:voidlinux"
            image: Qt.resolvedUrl("../../../../assets/logos/voidlinux.svg")
        },
        MenuItem {
            text: "Alpine Linux"
            value: "distro:alpinelinux"
            image: Qt.resolvedUrl("../../../../assets/logos/alpinelinux.svg")
        },
        MenuItem {
            text: "Kali Linux"
            value: "distro:kalilinux"
            image: Qt.resolvedUrl("../../../../assets/logos/kalilinux.svg")
        },
        MenuItem {
            text: "Raspberry Pi OS"
            value: "distro:raspberrypi"
            image: Qt.resolvedUrl("../../../../assets/logos/raspberrypi.svg")
        }
    ]

    title: Tr.tr("Taskbar")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Layout
        SectionHeader {
            first: true
            text: Tr.tr("Layout")
        }

        SelectRow {
            first: true
            label: Tr.tr("Position")
            subtext: Tr.tr("Which screen edge the bar sits on")
            menuItems: root.positionItems
            active: root.positionItems.find(i => i.value === GlobalConfig.bar.position) ?? root.positionItems[0]
            onSelected: item => GlobalConfig.bar.position = item.value
        }

        SelectRow {
            last: true
            label: Tr.tr("Launcher logo")
            subtext: Tr.tr("Icon shown on the launcher button")
            menuItems: root.logoItems
            active: root.logoItems.find(i => i.value === GlobalConfig.general.logo) ?? root.logoItems[0]
            onSelected: item => GlobalConfig.general.logo = item.value
        }

        // Behaviour
        SectionHeader {
            text: Tr.tr("Behaviour")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Persistent")
            subtext: Tr.tr("Keep the bar visible at all times")
            checked: Config.bar.persistent
            onToggled: GlobalConfig.bar.persistent = checked
        }

        ToggleRow {
            text: Tr.tr("Show on hover")
            subtext: Tr.tr("Reveal the bar when the cursor reaches the screen edge")
            checked: Config.bar.showOnHover
            onToggled: GlobalConfig.bar.showOnHover = checked
        }

        ToggleRow {
            text: Tr.tr("Adaptive compact")
            subtext: Tr.tr("Compact the tray and system monitor when the bar runs out of room")
            checked: Config.bar.adaptiveCompact
            onToggled: GlobalConfig.bar.adaptiveCompact = checked
        }

        StepperRow {
            last: true
            label: Tr.tr("Drag threshold")
            subtext: Tr.tr("Pixels dragged before the bar reveals")
            value: Config.bar.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.bar.dragThreshold = v
        }

        // Components
        SectionHeader {
            text: Tr.tr("Components")
        }

        NavRow {
            first: true
            icon: "workspaces"
            text: Tr.tr("Workspaces")
            subtext: Tr.tr("Indicators, window icons")
            onClicked: root.nState.openSubPage(5)
        }

        NavRow {
            icon: "widgets"
            text: Tr.tr("Tray")
            subtext: Tr.tr("System tray icons")
            onClicked: root.nState.openSubPage(6)
        }

        NavRow {
            icon: "monitor_heart"
            text: Tr.tr("System monitor")
            subtext: Tr.tr("CPU and memory usage")
            onClicked: root.nState.openSubPage(7)
        }

        NavRow {
            icon: "schedule"
            text: Tr.tr("Clock")
            subtext: Tr.tr("Date, icon, background")
            onClicked: root.nState.openSubPage(8)
        }

        NavRow {
            last: true
            icon: "signal_cellular_alt"
            text: Tr.tr("Status icons")
            subtext: Tr.tr("Visible indicators")
            onClicked: root.nState.openSubPage(9)
        }

        // Scroll actions
        SectionHeader {
            text: Tr.tr("Scroll actions")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Workspaces")
            subtext: Tr.tr("Scroll over the workspace indicator to switch workspaces")
            checked: Config.bar.scrollActions.workspaces
            onToggled: GlobalConfig.bar.scrollActions.workspaces = checked
        }

        ToggleRow {
            text: Tr.tr("Volume")
            subtext: Tr.tr("Scroll on the top half of the bar to adjust volume")
            checked: Config.bar.scrollActions.volume
            onToggled: GlobalConfig.bar.scrollActions.volume = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Brightness")
            subtext: Tr.tr("Scroll on the bottom half of the bar to adjust brightness")
            checked: Config.bar.scrollActions.brightness
            onToggled: GlobalConfig.bar.scrollActions.brightness = checked
        }
    }
}
