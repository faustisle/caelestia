pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.services

Variants {
    model: Screens.screens

    Scope {
        id: scope

        required property ShellScreen modelData

        readonly property var config: GlobalConfig.forScreen(modelData.name)

        // The bar's orientation is baked into the layouts, loaders and running animations of every
        // drawer, so a live position change rebuilds the screen's windows instead of converting them
        // in place, which leaves half of them still facing the old edge.
        function rebuild(): void {
            loader.active = false;
            loader.active = true;
        }

        LazyLoader {
            id: loader

            active: true

            Drawer {
                screen: scope.modelData
            }
        }

        Connections {
            function onPositionChanged(): void {
                Qt.callLater(scope.rebuild);
            }

            target: scope.config.bar
        }
    }

    component Drawer: Scope {
        id: drawer

        required property ShellScreen screen

        readonly property alias geometry: content.geometry

        Exclusions {
            screen: drawer.screen
            bar: content.bar
            geometry: content.geometry
        }

        ContentWindow {
            id: content

            screen: drawer.screen
        }
    }
}
