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
    readonly property color alertColour: Colours.palette.m3error
    readonly property real cpuThreshold: 80
    readonly property real memoryThreshold: 80
    // Alert at 90% of the CPU's critical temperature, clamped to an early
    // warning point, falling back to a fixed value when hwmon exposes none.
    readonly property real tempThreshold: Cpu.criticalTemperature > 0 ? Math.min(Cpu.criticalTemperature * 0.9, 95) : 80
    readonly property real alertHysteresis: 3
    readonly property int cpuSampleWindow: 3
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

    property bool cpuAlert: false
    property bool memoryAlert: false
    property bool tempAlert: false
    property var cpuSamples: []

    // Average the CPU samples so brief spikes don't flash the alert colour.
    readonly property real cpuAverage: root.cpuSamples.length > 0 ? root.cpuSamples.reduce((sum, value) => sum + value, 0) / root.cpuSamples.length : 0

    function sampleCpu(): void {
        const value = isFinite(Cpu.percentage) ? Cpu.percentage * 100 : 0;
        root.cpuSamples = root.cpuSamples.concat(value).slice(-root.cpuSampleWindow);
    }

    function refreshAlerts(): void {
        const hysteresis = root.alertHysteresis;
        const memory = isFinite(Memory.percentage) ? Memory.percentage * 100 : 0;
        const temp = isFinite(Cpu.temperature) ? Cpu.temperature : 0;
        root.cpuAlert = root.cpuAlert ? root.cpuAverage >= root.cpuThreshold - hysteresis : root.cpuAverage >= root.cpuThreshold;
        root.memoryAlert = root.memoryAlert ? memory >= root.memoryThreshold - hysteresis : memory >= root.memoryThreshold;
        root.tempAlert = root.tempAlert ? temp >= root.tempThreshold - hysteresis : temp >= root.tempThreshold;
    }

    Component.onCompleted: {
        sampleCpu();
        refreshAlerts();
    }

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

    Connections {
        target: Cpu

        function onPercentageChanged(): void {
            root.sampleCpu();
            root.refreshAlerts();
        }

        function onTemperatureChanged(): void {
            root.refreshAlerts();
        }
    }

    Connections {
        target: Memory

        function onChanged(): void {
            root.refreshAlerts();
        }
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: root.padding
        spacing: Tokens.spacing.medium

        Metric {
            id: cpuMetric

            visible: Config.bar.sysMonitor.showCpu
            icon: "memory"
            value: root.cpuValue
            unit: "%"
            alert: root.cpuAlert
        }

        Separator {
            visible: cpuMetric.visible && tempMetric.visible
        }

        Metric {
            id: tempMetric

            visible: Config.bar.sysMonitor.showCpuTemp
            icon: "thermometer"
            value: root.tempValue
            unit: root.tempUnit
            alert: root.tempAlert
        }

        Separator {
            visible: tempMetric.visible && memoryMetric.visible
        }

        Metric {
            id: memoryMetric

            visible: Config.bar.sysMonitor.showMemory
            icon: "memory_alt"
            iconFont: root.memoryIconFont
            value: root.memoryValue
            unit: root.memoryUnit
            alert: root.memoryAlert
        }
    }

    component Metric: ColumnLayout {
        id: metric

        required property string icon
        required property string value
        required property string unit
        property bool alert: false
        property font iconFont: root.iconFont

        readonly property color metricColour: alert ? root.alertColour : root.colour

        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall / 2

        MaterialIcon {
            Layout.fillWidth: true
            visible: Config.bar.sysMonitor.showIcons
            horizontalAlignment: Text.AlignHCenter
            text: metric.icon
            color: metric.metricColour
            fontStyle: metric.iconFont
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: metric.value
            font: root.valueFont
            color: metric.metricColour
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: metric.unit
            font: root.unitFont
            color: metric.metricColour
        }
    }

    component Separator: StyledRect {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 15          // tune
        implicitHeight: 1
        color: Colours.palette.m3outlineVariant
    }
}
