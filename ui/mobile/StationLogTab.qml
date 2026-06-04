/*
	Copyright (C) 2019-2021 Doug McLain
	Modified for DroidStar Enhanced Station Log
*/

import QtQuick
import QtQuick.Controls

Item {
    id: stationLogTab
    
    ListModel {
        id: stationLogModel
    }

    function refreshLog() {
        stationLogModel.clear();
        var csv = droidstar.readStationLog();
        if (!csv || csv.trim() === "") return;
        var lines = csv.split("\n");
        
        // Populate model in reverse order (newest first)
        for (var i = lines.length - 1; i >= 0; i--) {
            var line = lines[i].trim();
            if (line === "") continue;
            
            // Safe CSV quote parser in JS
            var parts = [];
            var insideQuotes = false;
            var currentPart = "";
            for (var j = 0; j < line.length; j++) {
                var c = line[j];
                if (c === '"') {
                    insideQuotes = !insideQuotes;
                } else if (c === ',' && !insideQuotes) {
                    parts.push(currentPart);
                    currentPart = "";
                } else {
                    currentPart += c;
                }
            }
            parts.push(currentPart);
            
            if (parts.length >= 5) {
                stationLogModel.append({
                    "date": parts[0],
                    "time": parts[1],
                    "callsign": parts[2],
                    "name": parts[3],
                    "country": parts[4]
                });
            }
        }
    }

    Component.onCompleted: refreshLog()

    // Title Header
    Rectangle {
        id: headerBar
        width: parent.width
        height: 42
        color: "#222222"
        border.color: "#333333"
        border.width: 1

        Text {
            text: qsTr("STATION LOG")
            color: "white"
            font.pixelSize: 14
            font.bold: true
            anchors.centerIn: parent
        }
    }

    // Main Log Panel Container
    Rectangle {
        id: logCard
        anchors.top: headerBar.bottom
        anchors.bottom: actionBar.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        color: "#161B22"
        border.color: "#555555"
        border.width: 1.5
        radius: 8

        // Table Header
        Column {
            id: tableHeaderCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 8
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            Row {
                width: parent.width
                height: 16

                Text { width: parent.width * 0.15; text: "DATE";      color: "#888888"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter }
                Text { width: parent.width * 0.15; text: "TIME";      color: "#888888"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter }
                Text { width: parent.width * 0.20; text: "CALLSIGN";  color: "#888888"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter }
                Text { width: parent.width * 0.25; text: "NAME";      color: "#888888"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter }
                Text { width: parent.width * 0.25; text: "COUNTRY";   color: "#888888"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#333333"
            }
        }

        // List Scroll View
        ListView {
            id: logListView
            anchors.top: tableHeaderCol.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            clip: true
            model: stationLogModel
            spacing: 2
            
            ScrollBar.vertical: ScrollBar { active: true }

            delegate: Rectangle {
                id: delegateRect
                width: logListView.width
                height: 28
                color: index % 2 === 0 ? "#1A202C" : "transparent"
                radius: 4

                Row {
                    anchors.fill: parent

                    Text { width: delegateRect.width * 0.15; text: model.date;      color: "white"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
                    Text { width: delegateRect.width * 0.15; text: model.time;      color: "white"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
                    Text { width: delegateRect.width * 0.20; text: model.callsign;  color: "#FFB000"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
                    Text { width: delegateRect.width * 0.25; text: model.name;      color: "white"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight }
                    Text { width: delegateRect.width * 0.25; text: model.country;   color: "#9AE6B4"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight }
                }
            }

            // Placeholder if empty
            Text {
                text: qsTr("No stations logged yet")
                color: "#555555"
                font.pixelSize: 13
                font.italic: true
                anchors.centerIn: parent
                visible: stationLogModel.count === 0
            }
        }
    }

    // Action Bar (Bottom Controls)
    Rectangle {
        id: actionBar
        width: parent.width
        height: 52
        anchors.bottom: parent.bottom
        color: "#222222"
        border.color: "#333333"
        border.width: 1

        Row {
            anchors.centerIn: parent
            spacing: 16

            // Export Button
            Button {
                id: exportBtn
                width: 140
                height: 34
                text: qsTr("Export Log (CSV)")
                flat: false
                
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.bold: true
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                background: Rectangle {
                    color: parent.pressed ? "#1E4620" : (parent.hovered ? "#2D6A4F" : "#1B4332")
                    border.color: "#52B788"
                    border.width: 1.5
                    radius: 6
                }

                onClicked: {
                    var filePath = droidstar.exportStationLog();
                    if (filePath === "EMPTY") {
                        statusPopupText.text = qsTr("Log is empty. No stations to export!");
                        statusPopup.open();
                    } else if (filePath === "ERROR") {
                        statusPopupText.text = qsTr("Failed to export log file!");
                        statusPopup.open();
                    } else {
                        statusPopupText.text = qsTr("Log exported successfully to:\n\n") + filePath;
                        statusPopup.open();
                    }
                }
            }

            // Clear Button
            Button {
                id: clearBtn
                width: 140
                height: 34
                text: qsTr("Clear History")
                flat: false

                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.bold: true
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: parent.pressed ? "#5C1D24" : (parent.hovered ? "#800F2F" : "#590D22")
                    border.color: "#FF4D6D"
                    border.width: 1.5
                    radius: 6
                }

                onClicked: {
                    confirmPopup.open();
                }
            }
        }
    }

    // Custom Styled Status Popup
    Popup {
        id: statusPopup
        anchors.centerIn: parent
        width: parent.width * 0.85
        height: 180
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#161B22"
            border.color: "#555555"
            border.width: 2
            radius: 10
        }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 16

            Text {
                text: qsTr("Station Log Exporter")
                color: "white"
                font.bold: true
                font.pixelSize: 13
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                id: statusPopupText
                width: parent.width
                color: "#CCCCCC"
                font.pixelSize: 11
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Button {
                width: 80
                height: 28
                text: qsTr("Close")
                anchors.horizontalCenter: parent.horizontalCenter
                
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                background: Rectangle {
                    color: parent.pressed ? "#333" : "#444"
                    border.color: "#666"
                    border.width: 1
                    radius: 4
                }
                
                onClicked: statusPopup.close()
            }
        }
    }

    // Custom Styled Confirmation Popup
    Popup {
        id: confirmPopup
        anchors.centerIn: parent
        width: parent.width * 0.85
        height: 160
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#161B22"
            border.color: "#800F2F"
            border.width: 2
            radius: 10
        }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 16

            Text {
                text: qsTr("Clear Log History?")
                color: "white"
                font.bold: true
                font.pixelSize: 13
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: qsTr("Are you sure you want to permanently clear the station log?")
                width: parent.width
                color: "#CCCCCC"
                font.pixelSize: 11
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Row {
                spacing: 16
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    width: 80
                    height: 28
                    text: qsTr("Yes")

                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: parent.pressed ? "#5C1D24" : "#800F2F"
                        border.color: "#FF4D6D"
                        border.width: 1
                        radius: 4
                    }

                    onClicked: {
                        droidstar.clearStationLog();
                        stationLogTab.refreshLog();
                        confirmPopup.close();
                    }
                }

                Button {
                    width: 80
                    height: 28
                    text: qsTr("No")

                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: parent.pressed ? "#333" : "#444"
                        border.color: "#666"
                        border.width: 1
                        radius: 4
                    }

                    onClicked: confirmPopup.close()
                }
            }
        }
    }
}
