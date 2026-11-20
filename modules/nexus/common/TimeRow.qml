pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

ConnectedRect {
    id: root

    property alias label: label.text
    property string subtext
    property int minutes

    signal moved(value: int)

    function pad(value: real): string {
        const rounded = Math.round(value);
        return rounded < 10 ? `0${rounded}` : `${rounded}`;
    }

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins * 2

    RowLayout {
        id: rowLayout

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: label

                Layout.fillWidth: true
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.subtext
                text: root.subtext
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        StyledSpinBox {
            from: 0
            to: 23
            stepSize: 1
            value: Math.floor(root.minutes / 60)
            enabled: root.enabled
            textFromValue: value => root.pad(value)
            onValueModified: root.moved(value * 60 + (root.minutes % 60))
        }

        StyledText {
            text: ":"
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
        }

        StyledSpinBox {
            from: 0
            to: 55
            stepSize: 5
            value: root.minutes % 60
            enabled: root.enabled
            textFromValue: value => root.pad(value)
            onValueModified: root.moved(Math.floor(root.minutes / 60) * 60 + value)
        }
    }
}
