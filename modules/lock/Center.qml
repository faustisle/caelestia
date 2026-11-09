import "center"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var lock
    readonly property real centerScale: Math.min(1, (lock.screen?.height ?? 1080) / 1080)
    readonly property int centerWidth: Tokens.sizes.lock.centerWidth * centerScale

    Layout.preferredWidth: centerWidth
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        id: main

        anchors.centerIn: parent
        spacing: Tokens.spacing.largeIncreased

        Clock {
            Layout.alignment: Qt.AlignHCenter
            centerScale: root.centerScale
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter

            text: Time.format("dddd • MMMM dd").toUpperCase()
            color: Colours.palette.m3onSurface
            font: Tokens.font.title.builders.medium.weight(Font.DemiBold).build()
        }

        PasswordInput {
            Layout.alignment: Qt.AlignHCenter
            centerScale: Math.max(0.8, root.centerScale)
            centerWidth: root.centerWidth
            lock: root.lock
        }
    }

    StateMessage {
        anchors.top: main.bottom
        anchors.topMargin: Tokens.spacing.largeIncreased
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        pam: root.lock.pam
    }
}
