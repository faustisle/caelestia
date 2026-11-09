pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils
import qs.modules.nexus.common

Item {
    id: root

    implicitWidth: Tokens.sizes.bar.audioWidth
    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.small

        StyledText {
            Layout.topMargin: Tokens.padding.medium
            Layout.rightMargin: Tokens.padding.extraSmall
            text: Tr.tr("App volumes")
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
        }

        ItemList {
            id: streamList

            first: true
            last: true
            showList: true
            placeholderIcon: "music_off"
            placeholderText: Tr.tr("No apps playing audio")
            color: list.count === 0 ? Colours.tPalette.m3surfaceContainer : "transparent"
            list.spacing: Tokens.spacing.extraSmall / 2

            model: ScriptModel {
                values: [...Audio.streams]
            }

            delegate: SliderRow {
                id: stream

                required property PwNode modelData
                required property int index

                anchors.left: streamList.list.contentItem.left
                anchors.right: streamList.list.contentItem.right
                first: index === 0
                last: index === streamList.list.count - 1

                icon: Icons.getVolumeIcon(stream.modelData?.audio?.volume ?? 0, stream.modelData?.audio?.muted ?? false)
                label: Audio.getStreamName(stream.modelData)
                valueLabel: Strings.percentOne(value)
                value: stream.modelData?.audio?.volume ?? 0
                enabled: !stream.modelData?.audio?.muted
                onMoved: v => Audio.setStreamVolume(stream.modelData, v)
            }
        }
    }
}
