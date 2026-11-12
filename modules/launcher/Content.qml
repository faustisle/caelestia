pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property ScreenState screenState
    required property var panels
    required property real maxHeight
    required property bool spotlight

    readonly property int padding: Tokens.padding.large
    readonly property int rounding: Tokens.rounding.extraLarge

    readonly property alias searchBar: search
    readonly property bool showResults: !spotlight || spotlightResults

    // Offset from the top of the launcher to the centre of the search bar.
    // Used to keep the search bar centred while results grow below it.
    readonly property real searchCenterOffset: padding + search.height / 2

    // Latched so the results do not collapse while the launcher is closing
    property bool spotlightResults: false

    function syncSpotlightResults(): void {
        if (spotlight && screenState.launcher)
            spotlightResults = search.text.length > 0;
    }

    onSpotlightChanged: syncSpotlightResults()

    implicitWidth: listWrapper.width + padding * 2
    implicitHeight: padding * 2 + search.height + listWrapper.height

    Item {
        id: listWrapper

        readonly property real naturalHeight: list.height + root.padding
        // Separate the results reveal from the list size so resizing the list
        // does not queue a second animation behind the list's own resize.
        property real reveal: root.spotlight ? (root.showResults ? 1 : 0) : 1

        implicitWidth: list.width
        implicitHeight: naturalHeight
        height: naturalHeight * reveal
        visible: !root.spotlight || height > 0
        clip: root.spotlight

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: search.bottom
        anchors.topMargin: root.padding

        Behavior on reveal {
            enabled: root.spotlight

            Anim {}
        }

        ContentList {
            id: list

            content: root
            screenState: root.screenState
            panels: root.panels
            maxHeight: root.spotlight ? Math.max(0, root.maxHeight / 2 - search.height / 2 - root.padding * 2) : root.maxHeight - search.implicitHeight - root.padding * 3
            search: search
            padding: root.padding
            rounding: root.rounding
        }
    }

    SearchBar {
        id: search

        objectName: "launcherSearch"
        backgroundless: root.spotlight

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.padding

        topPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)
        bottomPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)

        placeholderText: Tr.tr("Type \"%1\" for commands").arg(GlobalConfig.launcher.actionPrefix)

        onAccepted: {
            const currentItem = list.currentList?.currentItem;
            if (currentItem) {
                if (list.showWallpapers) {
                    if (Colours.scheme === "dynamic" && currentItem.modelData.path !== Wallpapers.actualCurrent)
                        Wallpapers.previewColourLock = true;
                    Wallpapers.setWallpaper(currentItem.modelData.path);
                    root.screenState.launcher = false;
                } else if (text.startsWith(GlobalConfig.launcher.actionPrefix)) {
                    if (text.startsWith(`${GlobalConfig.launcher.actionPrefix}calc `))
                        currentItem.onClicked();
                    else
                        currentItem.modelData.onClicked(list.currentList);
                } else {
                    Apps.launch(currentItem.modelData);
                    root.screenState.launcher = false;
                }
            }
        }

        Keys.onUpPressed: list.currentList?.decrementCurrentIndex()
        Keys.onDownPressed: list.currentList?.incrementCurrentIndex()

        Keys.onEscapePressed: root.screenState.launcher = false

        Keys.onPressed: event => {
            if (!GlobalConfig.launcher.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                    list.currentList?.incrementCurrentIndex();
                    event.accepted = true;
                } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                    list.currentList?.decrementCurrentIndex();
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab) {
                list.currentList?.incrementCurrentIndex();
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                list.currentList?.decrementCurrentIndex();
                event.accepted = true;
            }
        }

        Component.onCompleted: forceActiveFocus()

        Connections {
            function onLauncherChanged(): void {
                if (!root.screenState.launcher)
                    search.text = "";
                else
                    root.syncSpotlightResults();
            }

            function onSessionChanged(): void {
                if (!root.screenState.session)
                    search.forceActiveFocus();
            }

            target: root.screenState
        }

        Connections {
            function onTextChanged(): void {
                root.syncSpotlightResults();
            }

            target: search
        }
    }
}
