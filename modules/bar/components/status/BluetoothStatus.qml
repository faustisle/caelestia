import QtQuick
import Quickshell.Bluetooth
import qs.components

Item {
    id: root

    required property color colour

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    MaterialIcon {
        id: icon

        animate: true
        text: {
            if (!Bluetooth.defaultAdapter?.enabled)
                return "bluetooth_disabled";
            if (Bluetooth.devices.values.some(d => d.connected))
                return "bluetooth_connected";
            return "bluetooth";
        }
        color: root.colour
    }
}
