pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var workspaces
    required property int wsSpacing
    required property bool horizontal

    AnimatedRepeater {
        model: ScriptModel {
            values: root.workspaces
        }

        removeDuration: Tokens.anim.durations.expressiveDefaultEffects

        StyledRect {
            required property int index
            required property Workspace modelData

            property real shift: {
                if (!modelData || index === 0)
                    return 0;
                if (modelData.focused)
                    return -root.wsSpacing / 2 - (root.horizontal ? implicitWidth : implicitHeight);
                return (root.workspaces[index - 1]?.focused ?? false) ? root.wsSpacing / 2 : 0;
            }

            anchors.left: root.horizontal ? undefined : parent?.left
            anchors.right: root.horizontal ? undefined : parent?.right
            anchors.top: root.horizontal ? parent?.top : undefined
            anchors.bottom: root.horizontal ? parent?.bottom : undefined
            anchors.margins: Tokens.padding.extraSmall

            x: root.horizontal && modelData ? modelData.x - root.wsSpacing / 2 + shift : 0
            y: root.horizontal || !modelData ? 0 : modelData.y - root.wsSpacing / 2 + shift
            implicitWidth: root.horizontal ? 1 : 0
            implicitHeight: root.horizontal ? 0 : 1
            color: Colours.palette.m3outline

            opacity: AnimatedRepeater.adding || AnimatedRepeater.removing || !modelData || index === 0 || root.workspaces[index - 1]?.ws === modelData?.ws - 1 ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on shift {
                Anim {}
            }
        }
    }
}
