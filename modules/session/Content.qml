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
    readonly property real maxTitleWidth: Math.max(logout.titleWidth, shutdown.titleWidth, hibernate.titleWidth, reboot.titleWidth)

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

        readonly property real contentPadding: Tokens.padding.largeIncreased * root.scaleFactor
        readonly property real cornerRadius: Tokens.rounding.largeIncreased * root.scaleFactor
        readonly property real titleWidth: titleLabel.implicitWidth
        readonly property real buttonSize: Math.max(Tokens.sizes.session.button * root.scaleFactor, root.maxTitleWidth + contentPadding * 2, contentColumn.implicitHeight + contentPadding * 2)

        function exec(): void {
            if (!SessionManager.exec(command))
                Quickshell.execDetached(command);
        }

        implicitWidth: buttonSize
        implicitHeight: buttonSize

        inactiveColour: activeFocus ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
        inactiveOnColour: activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
        activeOnColour: Colours.palette.m3onPrimary
        radius: cornerRadius
        onClicked: exec()

        Rectangle {
            id: badge

            readonly property real paddingH: Tokens.padding.extraSmall * root.scaleFactor
            readonly property real paddingV: Tokens.padding.extraSmall * root.scaleFactor / 2

            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Tokens.padding.medium * root.scaleFactor

            implicitWidth: Math.max(height, badgeLabel.implicitWidth + paddingH * 2)
            height: badgeLabel.implicitHeight + paddingV * 2
            radius: button.cornerRadius * 0.3
            color: Qt.alpha(button.onColour, 0.12)

            StyledText {
                id: badgeLabel

                anchors.centerIn: parent
                text: button.number
                color: button.onColour
                font: Tokens.font.label.builders.small.scale(root.scaleFactor * 0.75).build()
            }
        }

        Column {
            id: contentColumn

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
                id: titleLabel

                anchors.horizontalCenter: parent.horizontalCenter
                text: button.title
                color: button.onColour
                font: Tokens.font.body.builders.small.scale(root.scaleFactor * 0.9).build()
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
