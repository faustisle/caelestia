import QtQuick

QtObject {
    required property string text
    property string icon
    property string image
    property string trailingIcon
    property string activeIcon: icon
    property string activeImage: image
    property string activeText: text
    property var value

    signal clicked
}
