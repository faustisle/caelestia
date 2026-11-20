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

    title: Tr.tr("Night light")
    isSubPage: false

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Schedule")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Enable night light")
            subtext: NightLight.useSchedule ? Tr.tr("Warm the screen automatically at the scheduled times") : Tr.tr("Warm the screen while enabled")
            checked: NightLight.enabled
            onToggled: NightLight.enabled = checked
        }

        ToggleRow {
            text: Tr.tr("Use schedule")
            subtext: Tr.tr("Only apply the filter between the start and end times")
            checked: NightLight.useSchedule
            enabled: NightLight.enabled
            onToggled: NightLight.useSchedule = checked
        }

        TimeRow {
            label: Tr.tr("Starts at")
            minutes: NightLight.startMinutes
            enabled: NightLight.enabled && NightLight.useSchedule
            onMoved: value => NightLight.startMinutes = value
        }

        TimeRow {
            label: Tr.tr("Ends at")
            minutes: NightLight.endMinutes
            enabled: NightLight.enabled && NightLight.useSchedule
            onMoved: value => NightLight.endMinutes = value
        }

        StepperRow {
            last: true
            label: Tr.tr("Transition")
            subtext: Tr.tr("Fade in before the start and out after the end (minutes)")
            value: NightLight.transitionMinutes
            from: 0
            to: 60
            stepSize: 5
            onMoved: value => NightLight.transitionMinutes = Math.round(value)
        }

        SectionHeader {
            text: Tr.tr("Colour")
        }

        SliderRow {
            first: true
            last: true
            icon: "nightlight"
            label: Tr.tr("Temperature")
            valueLabel: `${NightLight.temperature}K`
            value: NightLight.temperature
            from: NightLight.minTemperature
            to: NightLight.maxTemperature
            stepSize: 100
            onMoved: value => NightLight.temperature = NightLight.clampTemperature(value)
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            text: NightLight.statusText
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        StyledText {
            Layout.fillWidth: true
            visible: NightLight.enabled && NightLight.useSchedule
            text: Tr.tr("The transition starts %1 minutes before %2 and fades out after %3.").arg(NightLight.transitionMinutes).arg(NightLight.formatTime(NightLight.startMinutes)).arg(NightLight.formatTime(NightLight.endMinutes))
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }
}
