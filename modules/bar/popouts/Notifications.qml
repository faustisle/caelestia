pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.notifications.dock

Item {
    id: root

    required property ScreenState screenState
    required property var popouts

    readonly property Props props: Props {}

    implicitWidth: Tokens.sizes.notifs.width
    implicitHeight: Math.min(560, Math.max(360, (root.screenState.modelData?.height ?? 900) * 0.6))

    Connections {
        function onListChanged(): void {
            if (Notifs.list.length === 0)
                root.popouts.hasCurrent = false;
        }

        target: Notifs
    }

    StyledRect {
        anchors.fill: parent

        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainerLow
    }

    NotifDock {
        anchors.fill: parent

        props: root.props
        screenState: root.screenState
    }
}
