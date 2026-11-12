pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services

Row {
    id: root

    required property ScreenState screenState
    required property real scaleFactor

    padding: Tokens.padding.large * scaleFactor
    spacing: Tokens.spacing.large * scaleFactor

    readonly property var buttons: [logout, shutdown, hibernate, reboot]

    Keys.onPressed: event => {
        const blocked = Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier | Qt.ShiftModifier;
        if ((event.modifiers & blocked) === 0 && event.key >= Qt.Key_1 && event.key <= Qt.Key_4) {
            const button = root.buttons[event.key - Qt.Key_1];
            if (button) {
                button.exec();
                event.accepted = true;
            }
        }
    }

    SessionButton {
        id: logout

        icon: Config.session.icons.logout
        title: "Log Out"
        number: 1
        command: Config.session.commands.logout

        KeyNavigation.right: shutdown

        Component.onCompleted: forceActiveFocus()

        Connections {
            function onLauncherChanged(): void {
                if (!root.screenState.launcher)
                    logout.forceActiveFocus();
            }

            target: root.screenState
        }
    }

    SessionButton {
        id: shutdown

        icon: Config.session.icons.shutdown
        title: "Shutdown"
        number: 2
        command: Config.session.commands.shutdown

        KeyNavigation.left: logout
        KeyNavigation.right: hibernate
    }

    SessionButton {
        id: hibernate

        icon: Config.session.icons.hibernate
        title: "Hibernate"
        number: 3
        command: Config.session.commands.hibernate

        KeyNavigation.left: shutdown
        KeyNavigation.right: reboot
    }

    SessionButton {
        id: reboot

        icon: Config.session.icons.reboot
        title: "Restart"
        number: 4
        command: Config.session.commands.reboot

        KeyNavigation.left: hibernate
    }

    component SessionButton: ButtonBase {
        id: button

        required property string icon
        required property string title
        required property int number
        required property list<string> command

        function exec(): void {
            if (!SessionManager.exec(command))
                Quickshell.execDetached(command);
        }

        implicitWidth: Tokens.sizes.session.button * root.scaleFactor
        implicitHeight: Tokens.sizes.session.button * root.scaleFactor

        inactiveColour: activeFocus ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
        inactiveOnColour: activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
        activeOnColour: Colours.palette.m3onPrimary
        radius: pressed ? Tokens.rounding.medium * root.scaleFactor : activeFocus ? Tokens.rounding.extraLarge * root.scaleFactor : Tokens.rounding.largeIncreased * root.scaleFactor
        onClicked: exec()

        Rectangle {
            readonly property real badgePadding: Tokens.padding.extraSmall * root.scaleFactor / 2

            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Tokens.padding.extraSmall * root.scaleFactor

            implicitWidth: Math.max(height, badgeLabel.implicitWidth + badgePadding * 2)
            height: badgeLabel.implicitHeight + badgePadding
            radius: height / 2
            color: Qt.alpha(button.onColour, 0.12)

            StyledText {
                id: badgeLabel

                anchors.centerIn: parent
                text: button.number
                color: button.onColour
                font: Tokens.font.label.builders.small.weight(Font.Medium).scale(root.scaleFactor * 0.8).build()
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: Tokens.spacing.extraSmall * root.scaleFactor

            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: button.icon
                color: button.onColour
                fontStyle: Tokens.font.icon.builders.large.scale(1.3 * root.scaleFactor).build()
                fill: 1
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: button.title
                color: button.onColour
                font: Tokens.font.label.builders.medium.scale(root.scaleFactor).build()
            }
        }

        Keys.onEnterPressed: exec()
        Keys.onReturnPressed: exec()
        Keys.onEscapePressed: root.screenState.session = false
        Keys.onPressed: event => {
            if (!Config.session.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if ((event.key === Qt.Key_L || event.key === Qt.Key_N) && KeyNavigation.right) {
                    KeyNavigation.right.focus = true;
                    event.accepted = true;
                } else if ((event.key === Qt.Key_H || event.key === Qt.Key_P) && KeyNavigation.left) {
                    KeyNavigation.left.focus = true;
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab && KeyNavigation.right) {
                KeyNavigation.right.focus = true;
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                if (KeyNavigation.left) {
                    KeyNavigation.left.focus = true;
                    event.accepted = true;
                }
            }
        }
    }
}
