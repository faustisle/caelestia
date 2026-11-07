pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.components
import qs.services

StyledRect {
    id: root

    readonly property color colour: Colours.palette.m3tertiary
    readonly property int padding: Config.bar.sysMonitor.background ? Tokens.padding.medium : Tokens.padding.extraSmall
    readonly property var valueFont: Tokens.font.body.builders.small.scale(1.1).build()
    readonly property var unitFont: Tokens.font.body.builders.small.scale(0.8).build()
    readonly property var iconFont: Tokens.font.icon.builders.small.build()
    readonly property var memoryIconFont: Tokens.font.icon.builders.small.scale(0.85).build()

    readonly property string cpuValue: Math.round(isFinite(Cpu.percentage) ? Cpu.percentage * 100 : 0).toString()
    readonly property int resolvedTempUnit: Units.resolveTempUnit(GlobalConfig.services.sensorUnits)
    readonly property string tempValue: Math.round(isFinite(Cpu.temperature) ? Units.toTemperature(Cpu.temperature, GlobalConfig.services.sensorUnits) : 0).toString()
    readonly property string tempUnit: {
        if (Number(root.resolvedTempUnit) === TemperatureUnit.Fahrenheit)
            return "°F";
        if (Number(root.resolvedTempUnit) === TemperatureUnit.Kelvin)
            return "K";
        return "°C";
    }
    readonly property real memoryUsedMiB: Memory.used / 1024
    readonly property bool memoryInGiB: root.memoryUsedMiB >= 1024
    readonly property string memoryValue: (root.memoryInGiB ? root.memoryUsedMiB / 1024 : root.memoryUsedMiB).toFixed(1)
    readonly property string memoryUnit: root.memoryInGiB ? "GB" : "MB"

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: layout.implicitHeight + root.padding * 2

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.sysMonitor.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    ServiceRef {
        service: Cpu
    }

    ServiceRef {
        service: Memory
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: root.padding
        spacing: Tokens.spacing.medium

        Metric {
            visible: Config.bar.sysMonitor.showCpu
            icon: "memory"
            value: root.cpuValue
            unit: "%"
        }

        Metric {
            visible: Config.bar.sysMonitor.showCpuTemp
            icon: "thermometer"
            value: root.tempValue
            unit: root.tempUnit
        }

        Metric {
            visible: Config.bar.sysMonitor.showMemory
            icon: "memory_alt"
            iconFont: root.memoryIconFont
            value: root.memoryValue
            unit: root.memoryUnit
        }
    }

    component Metric: ColumnLayout {
        id: metric

        required property string icon
        required property string value
        required property string unit
        property font iconFont: root.iconFont

        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall / 2

        MaterialIcon {
            Layout.fillWidth: true
            visible: Config.bar.sysMonitor.showIcons
            horizontalAlignment: Text.AlignHCenter
            text: metric.icon
            color: root.colour
            fontStyle: metric.iconFont
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: metric.value
            font: root.valueFont
            color: root.colour
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: metric.unit
            font: root.unitFont
            color: root.colour
        }
    }
}
