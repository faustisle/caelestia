pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia
import Caelestia.I18n
import qs.components
import qs.services

MouseArea {
    id: root

    required property LazyLoader loader
    required property ShellScreen screen

    property bool selecting
    property real realBorderWidth: 2
    property real realRounding: 0
    property real ssx
    property real ssy

    property real sx: screen.width / 2
    property real sy: screen.height / 2
    property real ex: screen.width / 2
    property real ey: screen.height / 2

    property real rsx: Math.min(sx, ex)
    property real rsy: Math.min(sy, ey)
    property real sw: Math.abs(sx - ex)
    property real sh: Math.abs(sy - ey)

    function save(): void {
        const tmpfile = Qt.resolvedUrl(`/tmp/caelestia-picker-${Quickshell.processId}-${Date.now()}.png`);
        CUtils.saveItem(screencopy, tmpfile, Qt.rect(Math.ceil(rsx), Math.ceil(rsy), Math.floor(sw), Math.floor(sh)), path => {
            const script = `
                wl-copy --type image/png < "$1"
                action=$(notify-send -a caelestia-cli -i "$1" -A "default=$4" "$2" "$3")
                [ "$action" = "default" ] && exec swappy -f "$1"
            `;

            Quickshell.execDetached(["sh", "-c", script, "sh", path, Tr.tr("Screenshot taken"), Tr.tr("Screenshot copied to clipboard"), Tr.tr("Edit")]);
            if (!root.loader.freeze)
                screencopy.active = false;

            closeAnim.start();
        });
    }

    anchors.fill: parent
    opacity: 0
    hoverEnabled: true
    cursorShape: Qt.CrossCursor

    Component.onCompleted: opacity = 1

    onPressed: event => {
        selecting = true;
        ssx = event.x;
        ssy = event.y;
        sx = ssx;
        sy = ssy;
        ex = ssx;
        ey = ssy;
    }

    onReleased: {
        if (closeAnim.running)
            return;

        if (root.sw < 1 || root.sh < 1) {
            closeAnim.start();
            return;
        }

        if (root.loader.freeze) {
            save();
        } else {
            overlay.visible = false;
            root.selecting = false;
            screencopy.visible = false;
            screencopy.active = true;
        }
    }

    onPositionChanged: event => {
        if (pressed) {
            sx = ssx;
            sy = ssy;
            ex = event.x;
            ey = event.y;
        }
    }

    focus: true
    Keys.onEscapePressed: closeAnim.start()

    SequentialAnimation {
        id: closeAnim

        PropertyAction {
            target: root.loader
            property: "closing"
            value: true
        }
        ParallelAnimation {
            Anim {
                target: root
                property: "opacity"
                to: 0
                type: Anim.StandardLarge
            }
            Anim {
                target: root
                properties: "rsx,rsy"
                to: 0
            }
            Anim {
                target: root
                property: "sw"
                to: root.screen.width
            }
            Anim {
                target: root
                property: "sh"
                to: root.screen.height
            }
        }
        PropertyAction {
            target: root.loader
            property: "activeAsync"
            value: false
        }
    }

    Loader {
        id: screencopy

        asynchronous: true
        anchors.fill: parent

        active: root.loader.freeze

        sourceComponent: ScreencopyView {
            captureSource: root.screen

            onHasContentChanged: {
                if (hasContent && !root.loader.freeze) {
                    overlay.visible = true;
                    root.selecting = true;
                    root.save();
                }
            }
        }
    }

    Item {
        id: overlay

        anchors.fill: parent
        opacity: 0.3

        Rectangle {
            x: 0
            y: 0
            width: parent.width
            height: Math.max(0, root.rsy)
            color: Colours.palette.m3secondaryContainer
        }

        Rectangle {
            x: 0
            y: Math.min(parent.height, root.rsy + root.sh)
            width: parent.width
            height: Math.max(0, parent.height - y)
            color: Colours.palette.m3secondaryContainer
        }

        Rectangle {
            x: 0
            y: root.rsy
            width: Math.max(0, root.rsx)
            height: Math.min(root.sh, parent.height - y)
            color: Colours.palette.m3secondaryContainer
        }

        Rectangle {
            x: Math.min(parent.width, root.rsx + root.sw)
            y: root.rsy
            width: Math.max(0, parent.width - x)
            height: Math.min(root.sh, parent.height - y)
            color: Colours.palette.m3secondaryContainer
        }
    }

    Rectangle {
        id: border

        visible: root.selecting
        color: "transparent"
        radius: root.realRounding > 0 ? root.realRounding + root.realBorderWidth : 0
        border.width: root.realBorderWidth
        border.color: Colours.palette.m3primary

        x: root.rsx - root.realBorderWidth
        y: root.rsy - root.realBorderWidth
        implicitWidth: root.sw + root.realBorderWidth * 2
        implicitHeight: root.sh + root.realBorderWidth * 2

        Behavior on border.color {
            CAnim {}
        }
    }

    Behavior on opacity {
        Anim {
            type: Anim.StandardLarge
        }
    }

    Behavior on rsx {
        enabled: !root.pressed

        Anim {}
    }

    Behavior on rsy {
        enabled: !root.pressed

        Anim {}
    }

    Behavior on sw {
        enabled: !root.pressed

        Anim {}
    }

    Behavior on sh {
        enabled: !root.pressed

        Anim {}
    }
}
