pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    readonly property real fontScale: {
        const diff = width / 391 - 1; // 391 is the width at 1080 height screen
        return 1 + Math.pow(Math.abs(diff), 0.8) * Math.sign(diff);
    }

    visible: GlobalConfig.lock.enableSessionControls
    implicitHeight: buttonsLayout.implicitHeight + Tokens.padding.large * 2
    radius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: buttonsLayout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.large

        SessionButton {
            icon: Config.session.icons.logout
            command: Config.session.commands.logout
        }
        SessionButton {
            icon: Config.session.icons.shutdown
            command: Config.session.commands.shutdown
        }
        SessionButton {
            icon: Config.session.icons.hibernate
            command: Config.session.commands.hibernate
        }
        SessionButton {
            icon: Config.session.icons.reboot
            command: Config.session.commands.reboot
        }
    }

    component SessionButton: IconButton {
        id: button

        required property list<string> command

        function exec(): void {
            if (!SessionManager.exec(command))
                Quickshell.execDetached(command);
        }

        Layout.fillWidth: true
        Layout.preferredHeight: width

        inactiveColour: activeFocus ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainerHigh
        inactiveOnColour: activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
        radius: pressed ? Tokens.rounding.medium : activeFocus ? Tokens.rounding.extraLarge : Tokens.rounding.largeIncreased
        font: Tokens.font.icon.builders.large.scale(root.fontScale * 1.3).build()
        onClicked: exec()
    }
}
