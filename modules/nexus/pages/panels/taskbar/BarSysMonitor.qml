pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("System monitor")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            first: true
            text: Tr.trCtx("Background", "taskbar system monitor: draw a background behind the monitor")
            checked: Config.bar.sysMonitor.background
            onToggled: GlobalConfig.bar.sysMonitor.background = checked
        }

        ToggleRow {
            text: Tr.tr("Show popout")
            subtext: Tr.tr("Show performance details when hovering the system monitor")
            checked: Config.bar.popouts.sysMonitor
            onToggled: GlobalConfig.bar.popouts.sysMonitor = checked
        }

        ToggleRow {
            text: Tr.tr("Show icons")
            checked: Config.bar.sysMonitor.showIcons
            onToggled: GlobalConfig.bar.sysMonitor.showIcons = checked
        }

        ToggleRow {
            text: Tr.tr("CPU usage")
            checked: Config.bar.sysMonitor.showCpu
            onToggled: GlobalConfig.bar.sysMonitor.showCpu = checked
        }

        ToggleRow {
            text: Tr.tr("CPU temperature")
            checked: Config.bar.sysMonitor.showCpuTemp
            onToggled: GlobalConfig.bar.sysMonitor.showCpuTemp = checked
        }

        ToggleRow {
            text: Tr.tr("Memory usage")
            checked: Config.bar.sysMonitor.showMemory
            onToggled: GlobalConfig.bar.sysMonitor.showMemory = checked
        }

        // Popout widgets
        SectionHeader {
            text: Tr.tr("Popout widgets")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Battery")
            checked: Config.dashboard.performance.showBattery
            onToggled: GlobalConfig.dashboard.performance.showBattery = checked
        }

        ToggleRow {
            text: Tr.tr("GPU")
            checked: Config.dashboard.performance.showGpu
            onToggled: GlobalConfig.dashboard.performance.showGpu = checked
        }

        ToggleRow {
            text: Tr.tr("CPU")
            checked: Config.dashboard.performance.showCpu
            onToggled: GlobalConfig.dashboard.performance.showCpu = checked
        }

        ToggleRow {
            text: Tr.tr("Memory")
            checked: Config.dashboard.performance.showMemory
            onToggled: GlobalConfig.dashboard.performance.showMemory = checked
        }

        ToggleRow {
            text: Tr.tr("Storage")
            checked: Config.dashboard.performance.showStorage
            onToggled: GlobalConfig.dashboard.performance.showStorage = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Network")
            checked: Config.dashboard.performance.showNetwork
            onToggled: GlobalConfig.dashboard.performance.showNetwork = checked
        }
    }
}
