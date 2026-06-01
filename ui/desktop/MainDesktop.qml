import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 800
    height: 600
    title: qsTr("DroidStar Enhanced - Desktop")

    Rectangle {
        anchors.fill: parent
        color: "#1e1e1e"

        Text {
            anchors.centerIn: parent
            text: qsTr("Desktop UI Placeholder\n(Native layout pending)")
            color: "white"
            font.pixelSize: 24
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
