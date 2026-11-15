pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property bool horizontal
    property bool autoCompact

    readonly property bool compact: Config.bar.tray.compact || autoCompact
    readonly property real expandedLength: horizontal ? layout.implicitWidth + padding * 2 : layout.implicitHeight + padding * 2

    readonly property alias layout: layout
    readonly property alias items: items
    readonly property alias expandIcon: expandIcon

    readonly property int padding: Config.bar.tray.background ? Tokens.padding.medium : Tokens.padding.extraSmall
    readonly property int spacing: Config.bar.tray.background ? Tokens.spacing.medium : Tokens.spacing.extraSmall

    property bool expanded

    readonly property real nonAnimSize: {
        if (!root.compact)
            return (horizontal ? layout.implicitWidth : layout.implicitHeight) + padding * 2;
        const pad = (Config.bar.tray.background ? Tokens.padding.extraSmall : 0) + padding;
        const iconSize = horizontal ? expandIcon.implicitWidth : expandIcon.implicitHeight;
        const layoutSize = horizontal ? layout.implicitWidth : layout.implicitHeight;
        if (expanded)
            return iconSize + layoutSize + spacing + pad;
        return Math.max(Config.bar.tray.background ? (horizontal ? height : width) : 0, iconSize + pad);
    }

    clip: true
    visible: horizontal ? width > 0 : height > 0

    implicitWidth: horizontal ? nonAnimSize : Tokens.sizes.bar.innerWidth
    implicitHeight: horizontal ? Tokens.sizes.bar.innerWidth : nonAnimSize

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, (Config.bar.tray.background && items.count > 0) ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    Grid {
        id: layout

        anchors.horizontalCenter: root.horizontal ? undefined : parent.horizontalCenter
        anchors.verticalCenter: root.horizontal ? parent.verticalCenter : undefined
        anchors.left: root.horizontal ? parent.left : undefined
        anchors.top: root.horizontal ? undefined : parent.top
        anchors.leftMargin: root.horizontal ? root.padding : 0
        anchors.topMargin: root.horizontal ? 0 : root.padding
        columns: root.horizontal ? -1 : 1
        rowSpacing: Tokens.spacing.small
        columnSpacing: Tokens.spacing.small

        opacity: root.expanded || !root.compact ? 1 : 0

        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing: Tokens.anim.standardDecel
            }
        }

        move: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing: Tokens.anim.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }

        Repeater {
            id: items

            model: ScriptModel {
                values: SystemTray.items.values.filter(i => i.status !== Status.Passive && !GlobalConfig.bar.tray.hiddenIcons.includes(i.id))
            }

            TrayItem {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: expandIcon

        asynchronous: true

        anchors.horizontalCenter: root.horizontal ? undefined : parent.horizontalCenter
        anchors.verticalCenter: root.horizontal ? parent.verticalCenter : undefined
        anchors.bottom: root.horizontal ? undefined : parent.bottom
        anchors.right: root.horizontal ? parent.right : undefined

        active: root.compact && items.count > 0

        sourceComponent: Item {
            implicitWidth: root.horizontal ? expandIconInner.implicitWidth - Tokens.padding.small : expandIconInner.implicitWidth
            implicitHeight: root.horizontal ? expandIconInner.implicitHeight : expandIconInner.implicitHeight - Tokens.padding.small

            MaterialIcon {
                id: expandIconInner

                anchors.horizontalCenter: root.horizontal ? undefined : parent.horizontalCenter
                anchors.verticalCenter: root.horizontal ? parent.verticalCenter : undefined
                anchors.bottom: root.horizontal ? undefined : parent.bottom
                anchors.right: root.horizontal ? parent.right : undefined
                anchors.bottomMargin: root.horizontal ? 0 : Config.bar.tray.background ? Tokens.padding.extraSmall : -Tokens.padding.small
                anchors.rightMargin: root.horizontal ? (Config.bar.tray.background ? Tokens.padding.extraSmall : -Tokens.padding.small) : 0
                text: "expand_less"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                rotation: root.horizontal ? (root.expanded ? 270 : 90) : (root.expanded ? 180 : 0)

                Behavior on rotation {
                    Anim {}
                }

                Behavior on anchors.bottomMargin {
                    Anim {}
                }

                Behavior on anchors.rightMargin {
                    Anim {}
                }
            }
        }
    }

    Behavior on implicitWidth {
        Anim {}
    }

    Behavior on implicitHeight {
        Anim {}
    }
}
