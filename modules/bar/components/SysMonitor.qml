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

    required property bool horizontal

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

    property bool compact
    property real expandedLength
    property real compactLength
    property bool cpuAlert: false
    property bool memoryAlert: false
    property bool tempAlert: false
    property var cpuSamples: []

    readonly property bool hasMetrics: Config.bar.sysMonitor.showCpu || Config.bar.sysMonitor.showCpuTemp || Config.bar.sysMonitor.showMemory
    readonly property int compactMetric: {
        if (Config.bar.sysMonitor.showMemory && memoryAlert)
            return 2;
        if (Config.bar.sysMonitor.showCpu && cpuAlert)
            return 0;
        if (Config.bar.sysMonitor.showCpuTemp && tempAlert)
            return 1;
        if (Config.bar.sysMonitor.showMemory)
            return 2;
        if (Config.bar.sysMonitor.showCpu)
            return 0;
        if (Config.bar.sysMonitor.showCpuTemp)
            return 1;
        return 2;
    }
    readonly property string compactIcon: compactMetric === 0 ? "memory" : compactMetric === 1 ? "thermometer" : "memory_alt"
    readonly property string compactValue: compactMetric === 0 ? cpuValue : compactMetric === 1 ? tempValue : memoryValue
    readonly property string compactUnit: compactMetric === 0 ? "%" : compactMetric === 1 ? tempUnit : memoryUnit
    readonly property font compactIconFont: compactMetric === 2 ? memoryIconFont : iconFont
    readonly property bool compactAlert: compactMetric === 0 ? cpuAlert : compactMetric === 1 ? tempAlert : memoryAlert

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

    function updateLengths(): void {
        if (!root.compact) {
            const expanded = root.horizontal ? root.implicitWidth : root.implicitHeight;
            if (expanded > 0)
                root.expandedLength = expanded;
        }

        const metric = root.compact ? compactMetricView : root.compactMetric === 0 ? cpuMetric : root.compactMetric === 1 ? tempMetric : memoryMetric;
        const compact = (root.horizontal ? metric.implicitWidth : metric.implicitHeight) + root.padding * 2;
        if (compact > 0)
            root.compactLength = compact;
    }

    onCompactChanged: updateLengths()
    onCompactMetricChanged: updateLengths()
    onImplicitWidthChanged: updateLengths()
    onImplicitHeightChanged: updateLengths()

    Component.onCompleted: {
        sampleCpu();
        refreshAlerts();
        updateLengths();
    }

    implicitWidth: horizontal ? layout.implicitWidth + root.padding * 2 : Tokens.sizes.bar.innerWidth
    implicitHeight: horizontal ? Tokens.sizes.bar.innerWidth : layout.implicitHeight + root.padding * 2

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.sysMonitor.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    ServiceRef {
        service: Cpu
    }

    ServiceRef {
        service: Memory
    }

    Connections {
        function onPercentageChanged(): void {
            root.sampleCpu();
            root.refreshAlerts();
        }

        function onTemperatureChanged(): void {
            root.refreshAlerts();
        }

        target: Cpu
    }

    Connections {
        function onChanged(): void {
            root.refreshAlerts();
        }

        target: Memory
    }

    GridLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: root.padding
        columns: root.horizontal ? -1 : 1
        rowSpacing: Tokens.spacing.medium
        columnSpacing: Tokens.spacing.medium

        Metric {
            id: compactMetricView

            visible: root.compact && root.hasMetrics
            icon: root.compactIcon
            iconFont: root.compactIconFont
            value: root.compactValue
            unit: root.compactUnit
            alert: root.compactAlert
        }

        Metric {
            id: cpuMetric

            visible: !root.compact && Config.bar.sysMonitor.showCpu
            icon: "memory"
            value: root.cpuValue
            unit: "%"
            alert: root.cpuAlert
        }

        Separator {
            visible: !root.compact && cpuMetric.visible && tempMetric.visible
        }

        Metric {
            id: tempMetric

            visible: !root.compact && Config.bar.sysMonitor.showCpuTemp
            icon: "thermometer"
            value: root.tempValue
            unit: root.tempUnit
            alert: root.tempAlert
        }

        Separator {
            visible: !root.compact && tempMetric.visible && memoryMetric.visible
        }

        Metric {
            id: memoryMetric

            visible: !root.compact && Config.bar.sysMonitor.showMemory
            icon: "memory_alt"
            iconFont: root.memoryIconFont
            value: root.memoryValue
            unit: root.memoryUnit
            alert: root.memoryAlert
        }
    }

    component Metric: GridLayout {
        id: metric

        required property string icon
        required property string value
        required property string unit
        property bool alert: false
        property font iconFont: root.iconFont

        readonly property color metricColour: alert ? root.alertColour : root.colour

        Layout.fillWidth: !root.horizontal
        Layout.fillHeight: root.horizontal
        columns: root.horizontal ? -1 : 1
        rowSpacing: Tokens.spacing.extraSmall / 2
        columnSpacing: Tokens.spacing.extraSmall / 2

        MaterialIcon {
            Layout.fillWidth: !root.horizontal
            Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignHCenter
            visible: Config.bar.sysMonitor.showIcons
            horizontalAlignment: Text.AlignHCenter
            text: metric.icon
            color: metric.metricColour
            fontStyle: metric.iconFont
        }

        StyledText {
            Layout.fillWidth: !root.horizontal
            Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            text: metric.value
            font: root.valueFont
            color: metric.metricColour
        }

        StyledText {
            Layout.fillWidth: !root.horizontal
            Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            text: metric.unit
            font: root.unitFont
            color: metric.metricColour
        }
    }

    component Separator: StyledRect {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        implicitWidth: root.horizontal ? 1 : 15          // tune
        implicitHeight: root.horizontal ? 15 : 1
        color: Colours.palette.m3outlineVariant
    }
}
