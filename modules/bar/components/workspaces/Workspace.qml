pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import M3Shapes
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property var modelData
    required property int index
    required property int activeWsId
    required property int ws
    required property HyprlandMonitor monitor
    property string wsName
    property string activeWsName

    required property int displayType
    required property bool showWindows
    required property var iconRules
    required property bool horizontal
    readonly property int indicatorSize: (horizontal ? Tokens.sizes.bar.horizontalInnerWidth : Tokens.sizes.bar.innerWidth) - Tokens.padding.small
    property string activeLabel
    property string occupiedLabel
    property string label

    readonly property list<HyprlandToplevel> toplevels: wsName ? Hypr.toplevelsForWsName(wsName, GlobalConfig.bar.workspaces.ignoredTags) : Hypr.toplevelsForWs(ws, GlobalConfig.bar.workspaces.ignoredTags)
    readonly property bool isOccupied: toplevels.length > 0
    readonly property bool hasWindows: isOccupied && showWindows && Config.bar.workspaces.maxWindowIcons > 0
    readonly property bool focused: activeWsName ? wsName === activeWsName : activeWsId === ws
    readonly property HyprlandWorkspace workspace: wsName ? Hypr.workspaces.values.find(w => w.name === wsName) ?? null : Hypr.workspaces.values.find(w => w.id === ws) ?? null
    readonly property list<int> focusedShapeList: [MaterialShape.Slanted, MaterialShape.Oval, MaterialShape.Pill, MaterialShape.Triangle, MaterialShape.Arrow, MaterialShape.Diamond, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.VerySunny, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Cookie6Sided, MaterialShape.Cookie7Sided, MaterialShape.Cookie9Sided, MaterialShape.Cookie12Sided, MaterialShape.Clover4Leaf, MaterialShape.SoftBurst, MaterialShape.Ghostish]

    property color offMonitorColour: Colours.palette.m3outlineVariant
    readonly property bool onOtherMonitor: {
        if (Config.bar.workspaces.perMonitor)
            return false;
        const mon = workspace?.monitor;
        return !!(mon && mon !== monitor);
    }
    readonly property color fgColour: {
        if (onOtherMonitor)
            return offMonitorColour;
        if (focused || isOccupied || Config.bar.workspaces.occupiedBg)
            return Colours.palette.m3onSurface;
        return Colours.layer(Colours.palette.m3outlineVariant, 2);
    }

    function updateShape(): void {
        if (Theme.fluent)
            return;

        const shape = indicator.item as MaterialShape;
        if (!shape)
            return;

        if (focused)
            shape.shape = focusedShapeList[Math.floor(Math.random() * focusedShapeList.length)];
        else
            shape.shape = Qt.binding(() => isOccupied ? MaterialShape.Square : MaterialShape.Circle);
    }

    anchors.horizontalCenter: horizontal ? undefined : parent?.horizontalCenter
    LazyListView.preferredHeight: horizontal ? -1 : (LazyListView.removing ? 0 : layout.implicitHeight + (hasWindows ? Tokens.padding.extraSmall : 0))
    LazyListView.visibleHeight: horizontal ? -1 : LazyListView.preferredHeight
    LazyListView.preferredWidth: horizontal ? (LazyListView.removing ? 0 : layout.implicitWidth) : -1
    LazyListView.visibleWidth: horizontal ? LazyListView.preferredWidth : -1

    opacity: LazyListView.removing || LazyListView.adding ? 0 : 1

    onFocusedChanged: updateShape()
    Component.onCompleted: updateShape()

    Behavior on LazyListView.visibleHeight {
        enabled: !root.horizontal

        Anim {}
    }

    Behavior on LazyListView.visibleWidth {
        enabled: root.horizontal

        Anim {}
    }

    Behavior on y {
        enabled: root.LazyListView.ready && !root.horizontal

        Anim {}
    }

    Behavior on x {
        enabled: root.LazyListView.ready && root.horizontal

        Anim {}
    }

    Behavior on width {
        enabled: root.horizontal

        Anim {}
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    Component {
        id: flatShapeComponent

        StyledRect {
            implicitWidth: root.indicatorSize
            implicitHeight: root.indicatorSize

            radius: Tokens.rounding.small
            color: root.fgColour
            scale: root.focused ? 2 / 3 : root.isOccupied ? 1 / 3 : 1 / 4

            Behavior on color {
                CAnim {}
            }

            Behavior on scale {
                Anim {}
            }
        }
    }

    Component {
        id: shapeComponent

        MaterialShape {
            implicitSize: root.indicatorSize

            color: root.fgColour
            scale: root.focused ? 2 / 3 : root.isOccupied ? 1 / 3 : 1 / 4

            animationEasing: Theme.fluent ? Tokens.anim.standard : Tokens.anim.expressiveDefaultSpatial
            animationDuration: Tokens.anim.durations.expressiveDefaultSpatial * Tokens.anim.durations.scale

            Behavior on color {
                CAnim {}
            }

            Behavior on scale {
                Anim {}
            }
        }
    }

    Component {
        id: textComponent

        StyledText {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            animate: true
            text: {
                if (root.focused) {
                    const label = root.activeLabel;
                    if (label)
                        return label;
                }

                if (root.focused || root.isOccupied) {
                    const label = root.occupiedLabel;
                    if (label)
                        return label;
                }

                const label = root.label;
                if (label)
                    return label;

                const ws = root.workspace;
                const wsName = root.wsName ? Hypr.trimWsName(root.wsName) : !ws || ws.name === String(root.ws) ? root.ws : Hypr.trimWsName(ws.name)[0];

                const capitalisation = Config.bar.workspaces.capitalisation;
                if (capitalisation === BarWorkspaceCapitalisation.Upper)
                    return String(wsName).toUpperCase();
                else if (capitalisation === BarWorkspaceCapitalisation.Lower)
                    return String(wsName).toLowerCase();
                return wsName;
            }
            color: root.fgColour
            verticalAlignment: Qt.AlignVCenter
            font.family: Tokens.font.workspaces
        }
    }

    Component {
        id: iconComponent

        MaterialIcon {
            anchors.centerIn: parent
            fill: 1
            grade: 25
            text: iconCacher.icon
            color: root.fgColour
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Qt.AlignVCenter

            WsIconCacher {
                id: iconCacher
            }
        }
    }

    Component {
        id: iconLoaderComponent

        Loader {
            anchors.centerIn: parent
            sourceComponent: loaderIconCacher.icon ? iconComponent : textComponent

            WsIconCacher {
                id: loaderIconCacher
            }
        }
    }

    GridLayout {
        id: layout

        anchors.fill: parent
        columns: root.horizontal ? -1 : 1
        rowSpacing: 0
        columnSpacing: 0

        Loader {
            id: indicator

            Layout.alignment: root.horizontal ? Qt.AlignVCenter | Qt.AlignHCenter : Qt.AlignHCenter | Qt.AlignTop
            Layout.preferredWidth: root.horizontal ? root.indicatorSize : -1
            Layout.preferredHeight: root.horizontal ? -1 : root.indicatorSize
            sourceComponent: {
                if (root.displayType === BarWorkspaceDisplay.Icons)
                    return iconLoaderComponent;
                if (root.displayType === BarWorkspaceDisplay.Text)
                    return textComponent;
                return Theme.fluent ? flatShapeComponent : shapeComponent;
            }

            onItemChanged: root.updateShape()
        }

        Loader {
            id: windows

            asynchronous: true

            Layout.fillWidth: !root.horizontal
            Layout.fillHeight: root.horizontal
            Layout.leftMargin: root.horizontal && root.hasWindows ? -Tokens.spacing.extraSmall / 2 : 0
            Layout.topMargin: root.horizontal ? 0 : -Tokens.spacing.extraSmall / 2
            Layout.rightMargin: root.horizontal && root.hasWindows ? 6 : 0
            Layout.preferredWidth: root.horizontal ? (root.hasWindows && item ? (item as LazyListView).layoutWidth : 0) : -1
            Layout.preferredHeight: root.horizontal ? -1 : (root.hasWindows && item ? (item as LazyListView).layoutHeight : 0)

            visible: active
            active: root.showWindows && Config.bar.workspaces.maxWindowIcons > 0

            sourceComponent: LazyListView {
                horizontal: root.horizontal
                spacing: 0
                implicitWidth: root.horizontal ? contentWidth : -1
                implicitHeight: root.horizontal ? -1 : contentHeight
                cullDelegates: false
                removeDuration: Tokens.anim.durations.expressiveDefaultEffects

                model: ScriptModel {
                    values: {
                        const windows = root.toplevels;
                        const maxIcons = root.Config.bar.workspaces.maxWindowIcons;
                        return maxIcons > 0 ? windows.slice(0, maxIcons) : windows;
                    }
                }

                delegate: MaterialIcon {
                    id: win

                    required property var modelData
                    required property int index // Needed, LazyListView will fail to set it if it doesn't exist

                    grade: 0
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: Icons.getAppCategoryIcon(modelData.lastIpcObject.class, "terminal")
                    color: root.onOtherMonitor ? root.offMonitorColour : Colours.palette.m3onSurfaceVariant

                    opacity: LazyListView.adding || LazyListView.removing ? 0 : 1

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    Behavior on x {
                        enabled: root.horizontal

                        Anim {}
                    }

                    Behavior on y {
                        enabled: !root.horizontal

                        Anim {}
                    }
                }
            }
        }
    }

    component WsIconCacher: QtObject {
        id: cacher

        property string name
        readonly property string icon: Icons.matchIconRuleList(Hypr.trimWsName(name), root.iconRules)
        readonly property HyprlandWorkspace wsObj: Hypr.workspaces.values.find(w => root.wsName ? w.name === root.wsName : w.id === root.ws) ?? null

        readonly property Connections conn: Connections {
            function onNameChanged(): void {
                cacher.updateName();
            }

            target: cacher.wsObj
        }

        function updateName(): void {
            if (wsObj)
                name = wsObj.name;
        }

        onWsObjChanged: updateName()
        Component.onCompleted: updateName()
    }
}
