pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import "storage"

PageBase {
    id: root

    title: Tr.tr("Storage")
    isSubPage: false

    Component.onCompleted: Storage.refresh()

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Disks")
        }

        Repeater {
            model: Storage.volumes

            StorageVolumeRow {}
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            visible: !Storage.volumesReady
            implicitHeight: disksLoading.implicitHeight + Tokens.padding.large * 2

            RowLayout {
                id: disksLoading

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                LoadingIndicator {
                    implicitSize: 28
                }

                StyledText {
                    text: Tr.tr("Reading disks…")
                    font: Tokens.font.body.small
                }
            }
        }

        SectionHeader {
            text: Tr.tr("Where space goes")
            visible: Storage.measuring || Storage.homeDirs.length > 0
        }

        Repeater {
            model: Storage.homeDirs

            StorageUsageRow {}
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            visible: Storage.measuring && Storage.homeDirs.length === 0
            implicitHeight: measuring.implicitHeight + Tokens.padding.large * 2

            RowLayout {
                id: measuring

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                LoadingIndicator {
                    implicitSize: 28
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("Measuring disk usage…")
                    font: Tokens.font.body.small
                }

                StyledProgressBar {
                    Layout.preferredWidth: 160
                    implicitHeight: Tokens.padding.small
                    indeterminate: true
                }
            }
        }

        SectionHeader {
            text: Tr.tr("Free up space")
            visible: Storage.cleanups.length > 0
        }

        Repeater {
            model: Storage.cleanups

            StorageCleanRow {}
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large

            StyledText {
                Layout.fillWidth: true
                visible: Storage.lastError !== ""
                text: Storage.lastError
                color: Colours.palette.m3error
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }

            TextButton {
                text: Storage.measuring ? Tr.tr("Measuring…") : Tr.tr("Rescan")
                enabled: !Storage.measuring && Storage.cleaning === ""
                onClicked: Storage.refresh(true)
            }
        }
    }
}
