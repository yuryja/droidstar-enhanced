/*
	Copyright (C) 2019-2021 Doug McLain

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import QtQuick
import QtQuick.Controls

Item {
	id: mainTab
	property int rows: {
		if(USE_FLITE){
            mainTab.rows = 20;
		}
		else{
            mainTab.rows = 18;
		}
	}
	property bool tts: {
		if(USE_FLITE){
			tts = true;
		}
		else{
			tts = false;
		}
	}

	property real volValue: 0.5
	property real micValue: 0.1

    property bool isQSYing: false
    property string connectedTG: ""

    function triggerQSY() {
        if (mainTab.connectbutton.isconnected) {
            mainTab.isQSYing = true;
            mainTab.connectbutton.clickConnect();
        }
    }

	onWidthChanged:{
        if(_comboMode.currentText === "DMR"){
			_comboMode.width = (mainTab.width / 5) - 5;
			_connectbutton.width = (mainTab.width * 2 / 5 ) - 5
			_connectbutton.x = (mainTab.width * 3 / 5 )
		}
		else{
			_comboMode.width = (mainTab.width / 2) - 5;
			_connectbutton.width = (mainTab.width / 2) - 5;
			_connectbutton.x = mainTab.width / 2;
		}
	}

	property alias element3: _element3
	property alias label1: _label1
	property alias label2: _label2
	property alias label3: _label3
	property alias label4: _label4
	property alias label5: _label5
	property alias label6: _label6
	property alias ambestatus: _ambestatus
	property alias mmdvmstatus: _mmdvmstatus
	property alias netstatus: _netstatus
	property alias levelMeter: _levelMeter
	property alias uitimer: _uitimer
	property alias comboMode: _comboMode
	property alias comboHost: _comboHost
	property alias dtmflabel: _dtmflabel
	property alias editIAXDTMF: _editIAXDTMF
	property alias dtmfsendbutton: _dtmfsendbutton
	property alias comboModule: _comboModule
	property alias comboSlot: _comboSlot
	property alias comboCC: _comboCC
	property alias dmrtgidEdit: _dmrtgidEdit
	property alias comboM17CAN: _comboM17CAN
	property alias privateBox: _privateBox
	property alias connectbutton: _connectbutton
	property alias sliderMicGain: _slidermicGain
	property alias data1: _data1
	property alias data2: _data2
	property alias data3: _data3
	property alias data4: _data4
	property alias data5: _data5
	property alias data6: _data6
	property alias txtimer: _txtimer
	property alias buttonTX: _buttonTX
	property alias swtxBox: _swtxBox
	property alias swrxBox: _swrxBox
	property alias agcBox: _agcBox

    FontLoader {
        id: llpixelFont
        source: "fonts/arcade_pizzadude/ARCADE.TTF"
    }

    ListModel {
        id: lastHeardModel
    }

    function getCountryFromCallsign(callsign) {
        if (!callsign || callsign.length < 2) return "Unknown";
        callsign = callsign.toUpperCase().trim();
        
        var p2 = callsign.substring(0, 2);
        var p1 = callsign.substring(0, 1);
        
        var prefixMap2 = {
            "EA": "Spain", "EB": "Spain", "EC": "Spain",
            "YV": "Venezuela", "YW": "Venezuela", "YX": "Venezuela", "YY": "Venezuela",
            "CX": "Uruguay", "CW": "Uruguay",
            "XE": "Mexico", "XF": "Mexico",
            "LU": "Argentina", "LV": "Argentina", "LW": "Argentina",
            "CE": "Chile", "HK": "Colombia", "OA": "Peru", "ZP": "Paraguay", "CP": "Bolivia",
            "PY": "Brazil", "PV": "Brazil", "PP": "Brazil", "PT": "Brazil", "PU": "Brazil",
            "TI": "Costa Rica", "HP": "Panama", "HR": "Honduras", "YS": "El Salvador",
            "TG": "Guatemala", "YN": "Nicaragua", "CO": "Cuba", "CM": "Cuba", "HI": "Dominican Rep.",
            "HB": "Switzerland", "OE": "Austria", "OH": "Finland", "OZ": "Denmark",
            "CT": "Portugal", "SV": "Greece", "JY": "Jordan", "HZ": "Saudi Arabia", "OD": "Lebanon",
            "LA": "Norway", "LB": "Norway", "LC": "Norway", "LD": "Norway", "LN": "Norway",
            "SM": "Sweden", "SL": "Sweden", "SA": "Sweden", "SB": "Sweden",
            "ON": "Belgium", "OO": "Belgium", "OP": "Belgium", "OQ": "Belgium", "OR": "Belgium", "OS": "Belgium", "OT": "Belgium",
            "PA": "Netherlands", "PB": "Netherlands", "PC": "Netherlands", "PD": "Netherlands", "PE": "Netherlands", "PF": "Netherlands", "PG": "Netherlands", "PH": "Netherlands", "PI": "Netherlands",
            "VE": "Canada", "VO": "Canada", "VY": "Canada",
            "HL": "South Korea", "VK": "Australia", "ZL": "New Zealand", "ZS": "South Africa", "CN": "Morocco",
            "TA": "Turkey", "TB": "Turkey", "TC": "Turkey", "VU": "India",
            "4X": "Israel", "4Z": "Israel"
        };

        if (prefixMap2[p2]) {
            return prefixMap2[p2];
        }
        
        if (p1 === "W" || p1 === "K" || p1 === "N" || p1 === "A") {
            return "USA";
        }
        if (p1 === "G" || p1 === "M") {
            return "United Kingdom";
        }
        if (p1 === "F") {
            return "France";
        }
        if (p1 === "I") {
            return "Italy";
        }
        if (p1 === "D") {
            return "Germany";
        }
        if (p1 === "R") {
            return "Russia";
        }
        if (p1 === "U") {
            if (p2 >= "UA" && p2 <= "UI") return "Russia";
            return "Ukraine";
        }
        if (p1 === "J") {
            if (p2 >= "JA" && p2 <= "JS") return "Japan";
        }
        if (p1 === "B") {
            return "China";
        }
        
        return "Unknown";
    }

    function addLastHeard(data1Text, data6Text, streamId) {
        if (!data1Text || data1Text.trim() === "") {
            return;
        }
        
        // Parse Callsign and Name
        var tokens = data1Text.trim().split(/\s+/);
        var callsign = tokens[0].toUpperCase();
        var name = "";
        if (tokens.length > 1) {
            name = tokens.slice(1).join(" ");
        }
        
        // Parse Country using intelligent prefix database
        var country = getCountryFromCallsign(callsign);
        if (country === "Unknown" && data6Text && data6Text.trim() !== "") {
            country = data6Text.trim();
        }
        
        // Format UTC time
        var d = new Date();
        var utcTime = ("0" + d.getUTCHours()).slice(-2) + ":" + 
                      ("0" + d.getUTCMinutes()).slice(-2) + ":" + 
                      ("0" + d.getUTCSeconds()).slice(-2);
                      
        // Check for duplicates in last entry to prevent consecutive duplicates
        if (lastHeardModel.count > 0) {
            var firstItem = lastHeardModel.get(0);
            if (firstItem.callsign === callsign) {
                // Update time, country and name if available
                lastHeardModel.setProperty(0, "utc", utcTime);
                if (country !== "Unknown" && country !== "") {
                    lastHeardModel.setProperty(0, "country", country);
                }
                if (name !== "") {
                    lastHeardModel.setProperty(0, "name", name);
                }
                return;
            }
        }
        
        // Append to C++ persistent station log
        var dateStr = d.getUTCFullYear() + "-" + 
                      ("0" + (d.getUTCMonth()+1)).slice(-2) + "-" + 
                      ("0" + d.getUTCDate()).slice(-2);
        droidstar.appendToStationLog(dateStr, utcTime, callsign, name, country);
        if (typeof stationLogTab !== "undefined") {
            stationLogTab.refreshLog();
        }
        
        // Insert new entry at the beginning
        lastHeardModel.insert(0, {
            "utc": utcTime,
            "callsign": callsign,
            "name": name,
            "country": country
        });
        
        // Cap the list to 5 items
        while (lastHeardModel.count > 5) {
            lastHeardModel.remove(lastHeardModel.count - 1);
        }
    }

    Component {
        id: toggleSwitchComponent
        Item {
            width: 32; height: 52
            property alias labelText: lbl.text
            property bool checked: false
            property var onClickedFunc: function(){}
            Column {
                anchors.fill: parent; spacing: 2
                Text {
                    id: lbl; color: "white"; font.bold: true; font.pixelSize: 9
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Rectangle {
                    width: 26; height: 38; radius: 13; color: "#222222"
                    border.color: "#666"; border.width: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    Rectangle {
                        width: 22; height: 22; radius: 11; x: 2
                        y: checked ? 2 : 14
                        color: checked ? "#00CC00" : "#555555"
                        Behavior on y { NumberAnimation { duration: 100 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { checked = !checked; onClickedFunc(); }
                    }
                }
            }
        }
    }

    // --- TOP AMBER SCREEN ---
    Rectangle {
        id: screenBezel
        x: 5; y: 5
        width: parent.width - 10
        height: parent.height * 0.62
        color: "#222222"
        radius: 10
        border.color: "#555555"
        border.width: 2

        Rectangle {
            id: glassCard
            anchors.fill: parent
            anchors.margins: 4
            color: "#FFB000"
            radius: 8
            border.color: "#8C6200"
            border.width: 2

            // Horizontal S-Meter
            Item {
                id: sMeterContainer
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 6
                height: 10

                Rectangle { anchors.fill: parent; color: "transparent"; border.color: "#8C6200"; border.width: 1 }

                Rectangle {
                    id: _levelMeter
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.topMargin: 1; anchors.bottomMargin: 1; anchors.leftMargin: 1
                    width: 0
                    color: "#1A1A1A"
                    Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                }
                Row {
                    anchors.fill: parent
                    Repeater {
                        model: 22
                        Item {
                            width: parent.width / 22
                            height: parent.height
                            Rectangle { anchors.left: parent.left; width: 1; height: parent.height; color: "#FFB000" }
                        }
                    }
                }
            }

            // Labels and Data Column Layout (Constant Height)
            Column {
                id: labelsColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: sMeterContainer.bottom
                anchors.margins: 6
                spacing: 1
                visible: !mainTab.isQSYing

                Row {
                    width: parent.width
                    height: 22
                    Text { id: _label1; width: 120; height: parent.height; text: "MYCALL"; color: "#111111"; font.family: llpixelFont.name; font.bold: true; font.pixelSize: 22 }
                    Text { id: _data1;  height: parent.height; text: "";       color: "#111111"; font.family: llpixelFont.name; font.bold: true; font.pixelSize: 22 }
                }
                Row {
                    width: parent.width
                    height: 22
                    Text { id: _label2; width: 120; height: parent.height; text: "URCALL"; color: "#111111"; font.family: llpixelFont.name; font.bold: true; font.pixelSize: 22 }
                    Text { id: _data2;  height: parent.height; text: "";       color: "#111111"; font.family: llpixelFont.name; font.bold: true; font.pixelSize: 22 }
                }
                Row {
                    width: parent.width
                    height: 22
                    Text { id: _label3; width: 120; height: parent.height; text: "RPTR1";  color: "#111111"; font.family: llpixelFont.name; font.bold: true; font.pixelSize: 22 }
                    Text { id: _data3;  height: parent.height; text: "";       color: "#111111"; font.family: llpixelFont.name; font.bold: true; font.pixelSize: 22 }
                }
                Row {
                    width: parent.width
                    height: 22
                    Text { id: _label4; width: 120; height: parent.height; text: "RPTR2";  color: "#111111"; font.family: llpixelFont.name; font.bold: true; font.pixelSize: 22 }
                    Text { id: _data4;  height: parent.height; text: "";       color: "#111111"; font.family: llpixelFont.name; font.bold: true; font.pixelSize: 22 }
                }
                Row {
                    width: parent.width
                    height: 22
                    Text { id: _label5; width: 120; height: parent.height; text: "StrmID"; color: "#111111"; font.family: llpixelFont.name; font.bold: true; font.pixelSize: 22 }
                    Text { id: _data5;  height: parent.height; text: "";       color: "#111111"; font.family: llpixelFont.name; font.bold: true; font.pixelSize: 22 }
                }
                Row {
                    width: parent.width
                    height: 22
                    visible: _label6.text !== ""
                    Text { id: _label6; width: 120; height: parent.height; text: "Text";   color: "#111111"; font.family: llpixelFont.name; font.bold: true; font.pixelSize: 22 }
                    Text { id: _data6;  height: parent.height; text: "";       color: "#111111"; font.family: llpixelFont.name; font.bold: true; font.pixelSize: 22 }
                }
                Row {
                    width: parent.width
                    height: 22
                    visible: _label7.text !== ""
                    Text { id: _label7; width: 120; height: parent.height; text: ""; color: "#111111"; font.family: llpixelFont.name; font.bold: true; font.pixelSize: 22 }
                    Text { id: _data7;  height: parent.height; text: ""; color: "#111111"; font.family: llpixelFont.name; font.bold: true; font.pixelSize: 22 }
                }
            }

            // Status lines (bottom of screen)
            Column {
                id: statusContainer
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: labelsColumn.bottom
                anchors.topMargin: 4
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 1
                visible: !mainTab.isQSYing
                Text { id: _ambestatus; text: "No AMBE hardware connected"; color: "#111111"; font.family: llpixelFont.name; font.bold: true; font.pixelSize: 12 }
                Text { id: _mmdvmstatus; text: "No MMDVM connected";        color: "#111111"; font.family: llpixelFont.name; font.bold: true; font.pixelSize: 12 }
                Text { id: _netstatus;   text: "Not Connected to network";   color: "#111111"; font.family: llpixelFont.name; font.bold: true; font.pixelSize: 12 }
            }

            // Integrated Last Heard inside screen
            Column {
                id: lastHeardPanel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: statusContainer.bottom
                anchors.topMargin: 4
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 2
                visible: !mainTab.isQSYing

                // Panel Header/Title - BORDERS REMOVED
                Rectangle {
                    width: parent.width
                    height: 14
                    color: "transparent"
                    border.color: "transparent"
                    border.width: 0

                    Text {
                        text: "LAST HEARD (TG ACTIVE)"
                        color: "#111111"
                        font.family: llpixelFont.name
                        font.pixelSize: 13
                        font.bold: true
                        anchors.centerIn: parent
                    }
                }

                // Table Header Row with Solid Bottom Divider Line
                Column {
                    width: parent.width
                    spacing: 0
                    
                    Row {
                        width: parent.width
                        height: 13

                        Text {
                            width: parent.width * 0.20
                            text: "UTC"
                            color: "#111111"
                            font.family: llpixelFont.name
                            font.pixelSize: 12
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Text {
                            width: parent.width * 0.25
                            text: "CALLSIGN"
                            color: "#111111"
                            font.family: llpixelFont.name
                            font.pixelSize: 12
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Text {
                            width: parent.width * 0.28
                            text: "NAME"
                            color: "#111111"
                            font.family: llpixelFont.name
                            font.pixelSize: 12
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Text {
                            width: parent.width * 0.27
                            text: "COUNTRY"
                            color: "#111111"
                            font.family: llpixelFont.name
                            font.pixelSize: 12
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#111111"
                    }
                }

                // Table Rows Column
                Column {
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: 5

                        delegate: Rectangle {
                            width: parent.width
                            height: 20
                            color: "transparent"
                            border.color: "transparent"
                            border.width: 0

                            Row {
                                anchors.fill: parent
                                anchors.verticalCenter: parent.verticalCenter

                                // UTC
                                Text {
                                    width: parent.width * 0.20
                                    text: (index < lastHeardModel.count && lastHeardModel.get(index)) ? lastHeardModel.get(index).utc : ""
                                    color: "#111111"
                                    font.family: llpixelFont.name
                                    font.pixelSize: 12
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                // Callsign
                                Text {
                                    width: parent.width * 0.25
                                    text: (index < lastHeardModel.count && lastHeardModel.get(index)) ? lastHeardModel.get(index).callsign : ""
                                    color: "#111111"
                                    font.family: llpixelFont.name
                                    font.pixelSize: 12
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                }
                                // Name
                                Text {
                                    width: parent.width * 0.28
                                    text: (index < lastHeardModel.count && lastHeardModel.get(index)) ? lastHeardModel.get(index).name : ""
                                    color: "#111111"
                                    font.family: llpixelFont.name
                                    font.pixelSize: 12
                                    horizontalAlignment: Text.AlignHCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                }
                                // Country
                                Text {
                                    width: parent.width * 0.27
                                    text: (index < lastHeardModel.count && lastHeardModel.get(index)) ? lastHeardModel.get(index).country : ""
                                    color: "#111111"
                                    font.family: llpixelFont.name
                                    font.pixelSize: 12
                                    horizontalAlignment: Text.AlignHCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            Text {
                id: qsySearchingText
                anchors.centerIn: parent
                text: "searching..."
                color: "#111111"
                font.family: llpixelFont.name
                font.bold: true
                font.pixelSize: 28
                visible: mainTab.isQSYing
            }
        }
    }

    // --- BOTTOM CONTROLS ---
    Rectangle {
        id: controlsCard
        x: 0
        y: screenBezel.y + screenBezel.height + 8
        width: parent.width
        height: parent.height - y
        color: "transparent"

        ScrollView {
            anchors.fill: parent
            contentWidth: parent.width
            contentHeight: controlCol.height + 20

            Column {
                id: controlCol
                width: parent.width - 10
                x: 5
                spacing: 10

                // === PTT + DIALS (Always visible on top) ===
                Row {
                    id: pttDialsRow
                    spacing: 16
                    anchors.horizontalCenter: parent.horizontalCenter

                    // PTT key (horizontal rounded rectangle, Walkie-Talkie style)
                    Column {
                        spacing: 4
                        Text { text: "PTT"; color: "white"; font.bold: true; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                        Rectangle {
                            id: _buttonTX
                            width: 100; height: 56; radius: 14
                            color: tx ? "#FF3333" : "#2A2A2A"
                            border.color: tx ? "#FF8888" : "#555555"; border.width: 3
                            property bool tx: false; property int cnt: 0
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            // Walkie-Talkie rubber style: 3 vertical ridges
                            Row {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -8
                                spacing: 6
                                opacity: 0.4
                                Repeater {
                                    model: 3
                                    Rectangle {
                                        width: 5; height: 16; radius: 2.5
                                        color: _buttonTX.tx ? "white" : "black"
                                    }
                                }
                            }
                            
                            Text {
                                text: _buttonTX.tx ? "TX " + _buttonTX.cnt : "TX"
                                color: "white"; font.bold: true; font.pixelSize: 12
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom; anchors.bottomMargin: 8
                            }
                            
                            Timer {
                                id: _txtimer; repeat: true
                                onTriggered: {
                                    ++_buttonTX.cnt;
                                    if(_buttonTX.cnt >= parseInt(settingsTab.txtimerEdit.text)){ _buttonTX.tx = false; droidstar.click_tx(_buttonTX.tx); _txtimer.running = false; }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { if(settingsTab.toggleTX.checked){ _buttonTX.tx = !_buttonTX.tx; droidstar.click_tx(_buttonTX.tx); if(_buttonTX.tx){ _buttonTX.cnt = 0; _txtimer.running = true; } else { _txtimer.running = false; } } }
                                onPressed:  { if(!settingsTab.toggleTX.checked){ _buttonTX.tx = true;  droidstar.press_tx(); } }
                                onReleased: { if(!settingsTab.toggleTX.checked){ _buttonTX.tx = false; droidstar.release_tx(); } }
                            }
                        }
                    }

                    // --- VOL CONTROL ---
                    Column {
                        spacing: 4
                        Text {
                            text: "VOL"; color: "white"
                            font.bold: true; font.pixelSize: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        // Value display
                        Rectangle {
                            width: 68; height: 20; radius: 6
                            color: "#111111"; border.color: "#444444"; border.width: 1
                            anchors.horizontalCenter: parent.horizontalCenter
                            Text {
                                text: Math.round(volValue * 100) + "%"
                                color: "#00FF00"; font.pixelSize: 11; font.bold: true
                                anchors.centerIn: parent
                            }
                        }
                        
                        // Up/Down Buttons
                        Row {
                            spacing: 6
                            anchors.horizontalCenter: parent.horizontalCenter
                            
                            // DOWN
                            Rectangle {
                                width: 30; height: 30; radius: 8
                                color: downVolMouse.pressed ? "#444444" : "#222222"
                                border.color: "#555555"; border.width: 1
                                Text { text: "▼"; color: "white"; font.pixelSize: 12; anchors.centerIn: parent }
                                MouseArea {
                                    id: downVolMouse
                                    anchors.fill: parent
                                    onClicked: {
                                        volValue = Math.max(0.0, volValue - 0.05);
                                    }
                                }
                            }
                            
                            // UP
                            Rectangle {
                                width: 30; height: 30; radius: 8
                                color: upVolMouse.pressed ? "#444444" : "#222222"
                                border.color: "#555555"; border.width: 1
                                Text { text: "▲"; color: "white"; font.pixelSize: 12; anchors.centerIn: parent }
                                MouseArea {
                                    id: upVolMouse
                                    anchors.fill: parent
                                    onClicked: {
                                        volValue = Math.min(1.0, volValue + 0.05);
                                    }
                                }
                            }
                        }
                    }

                    // --- MIC CONTROL ---
                    Column {
                        spacing: 4
                        Text {
                            text: "MIC"; color: "white"
                            font.bold: true; font.pixelSize: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        // Value display
                        Rectangle {
                            width: 68; height: 20; radius: 6
                            color: "#111111"; border.color: "#444444"; border.width: 1
                            anchors.horizontalCenter: parent.horizontalCenter
                            Text {
                                text: Math.round(micValue * 100) + "%"
                                color: "#00FF00"; font.pixelSize: 11; font.bold: true
                                anchors.centerIn: parent
                            }
                        }
                        
                        // Up/Down Buttons
                        Row {
                            spacing: 6
                            anchors.horizontalCenter: parent.horizontalCenter
                            
                            // DOWN
                            Rectangle {
                                width: 30; height: 30; radius: 8
                                color: downMicMouse.pressed ? "#444444" : "#222222"
                                border.color: "#555555"; border.width: 1
                                Text { text: "▼"; color: "white"; font.pixelSize: 12; anchors.centerIn: parent }
                                MouseArea {
                                    id: downMicMouse
                                    anchors.fill: parent
                                    onClicked: {
                                        micValue = Math.max(0.0, micValue - 0.05);
                                        _slidermicGain.value = micValue;
                                        droidstar.set_input_volume(micValue);
                                    }
                                }
                            }
                            
                            // UP
                            Rectangle {
                                width: 30; height: 30; radius: 8
                                color: upMicMouse.pressed ? "#444444" : "#222222"
                                border.color: "#555555"; border.width: 1
                                Text { text: "▲"; color: "white"; font.pixelSize: 12; anchors.centerIn: parent }
                                MouseArea {
                                    id: upMicMouse
                                    anchors.fill: parent
                                    onClicked: {
                                        micValue = Math.min(1.0, micValue + 0.05);
                                        _slidermicGain.value = micValue;
                                        droidstar.set_input_volume(micValue);
                                    }
                                }
                            }
                        }
                    }
                }

                // === COLLAPSIBLE SERVER SETTINGS PANEL ===
                Item {
                    id: serverSettingsPanel
                    width: parent.width
                    height: 38
                    z: 10
                    property bool expanded: false
                    
                    // Clickable Header Bar
                    Rectangle {
                        width: parent.width
                        height: 38
                        color: "#222222"
                        border.color: "#555555"
                        border.width: 1
                        radius: 8
                        
                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8
                            
                            Text {
                                text: "SERVER SETTINGS"
                                color: "white"
                                font.pixelSize: 11
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Item {
                                width: parent.width - 150 - 30 // spacer
                                height: 1
                            }
                            
                            Text {
                                text: serverSettingsPanel.expanded ? "▲" : "▼"
                                color: "white"
                                font.pixelSize: 12
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                serverSettingsPanel.expanded = !serverSettingsPanel.expanded
                            }
                        }
                    }
                    
                    // Collapsible Content
                    Item {
                        id: collapsArea
                        y: 42
                        width: parent.width
                        height: serverSettingsPanel.expanded ? (collapsCol.height + 16) : 0
                        clip: true
                        z: 20
                        
                        Behavior on height {
                            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                        }
                        
                        Rectangle {
                            anchors.fill: parent
                            color: "#161B22"
                            border.color: "#555555"
                            border.width: 1.5
                            radius: 8
                        }
                        
                        Column {
                            id: collapsCol
                            anchors { left: parent.left; right: parent.right; top: parent.top }
                            anchors.margins: 8
                            spacing: 10
                            
                            // === LINE 1: Mode | Slot | CC ===
                            Row {
                                width: parent.width
                                spacing: 4

                                // MODE (Dynamic Width to fill line if Slot & CC are hidden)
                                Item {
                                    width: {
                                        if (!_comboSlot.visible && !_comboCC.visible) {
                                            return parent.width;
                                        } else if (_comboSlot.visible && !_comboCC.visible) {
                                            return parent.width * 0.60;
                                        } else {
                                            return parent.width * 0.35;
                                        }
                                    }
                                    height: 52
                                    Rectangle {
                                        anchors.fill: parent; anchors.topMargin: 10
                                        color: "transparent"
                                        border.color: "white"; border.width: 1; radius: 4
                                    }
                                    Rectangle {
                                        x: 6; y: 3
                                        width: lblMode.width + 4
                                        height: lblMode.height
                                        color: "#161B22"
                                    }
                                    Text {
                                        id: lblMode
                                        x: 8; y: 3
                                        text: "MODE"; color: "white"
                                        font.pixelSize: 10; font.bold: true
                                    }
                                    ComboBox {
                                        id: _comboMode
                                        property bool loaded: false
                                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; top: parent.top; topMargin: 12; margins: 2 }
                                        model: ["M17", "YSF", "FCS", "DMR", "P25", "NXDN", "REF", "XRF", "DCS", "IAX"]
                                        font.pixelSize: 11
                                        background: Rectangle { color: "transparent" }
                                        contentItem: Text {
                                            text: _comboMode.displayText; color: "white"
                                            font.pixelSize: 12; font.bold: true
                                            verticalAlignment: Text.AlignVCenter; leftPadding: 6
                                        }
                                        onCurrentTextChanged: { if(_comboMode.loaded){ droidstar.process_mode_change(_comboMode.currentText); } }
                                    }
                                }

                                // SLOT (DMR Slot)
                                Item {
                                    width: {
                                        if (!_comboCC.visible) {
                                            return parent.width - parent.width * 0.35 - 4;
                                        } else {
                                            return parent.width * 0.30;
                                        }
                                    }
                                    height: 52
                                    visible: _comboSlot.visible
                                    Rectangle {
                                        anchors.fill: parent; anchors.topMargin: 10
                                        color: "transparent"
                                        border.color: "white"; border.width: 1; radius: 4
                                    }
                                    Rectangle {
                                        x: 6; y: 3
                                        width: lblSlot.width + 4
                                        height: lblSlot.height
                                        color: "#161B22"
                                    }
                                    Text {
                                        id: lblSlot
                                        x: 8; y: 3
                                        text: "SLOT"; color: "white"
                                        font.pixelSize: 10; font.bold: true
                                    }
                                    ComboBox {
                                        id: _comboSlot
                                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; top: parent.top; topMargin: 12; margins: 2 }
                                        model: ["S1", "S2"]
                                        font.pixelSize: 11
                                        background: Rectangle { color: "transparent" }
                                        contentItem: Text {
                                            text: _comboSlot.displayText; color: "white"
                                            font.pixelSize: 12; font.bold: true
                                            verticalAlignment: Text.AlignVCenter; leftPadding: 6
                                        }
                                        onCurrentTextChanged: { droidstar.set_slot(_comboSlot.currentIndex); }
                                    }
                                }

                                // CC (DMR Color Code)
                                Item {
                                    width: parent.width - parent.width * 0.35 - parent.width * 0.30 - 8; height: 52
                                    visible: _comboCC.visible
                                    Rectangle {
                                        anchors.fill: parent; anchors.topMargin: 10
                                        color: "transparent"
                                        border.color: "white"; border.width: 1; radius: 4
                                    }
                                    Rectangle {
                                        x: 6; y: 3
                                        width: lblCC.width + 4
                                        height: lblCC.height
                                        color: "#161B22"
                                    }
                                    Text {
                                        id: lblCC
                                        x: 8; y: 3
                                        text: "CC"; color: "white"
                                        font.pixelSize: 10; font.bold: true
                                    }
                                    ComboBox {
                                        id: _comboCC
                                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; top: parent.top; topMargin: 12; margins: 2 }
                                        model: ["CC0","CC1","CC2","CC3","CC4","CC5","CC6","CC7","CC8","CC9","CC10","CC11","CC12","CC13","CC14","CC15"]
                                        font.pixelSize: 11
                                        background: Rectangle { color: "transparent" }
                                        contentItem: Text {
                                            text: _comboCC.displayText; color: "white"
                                            font.pixelSize: 12; font.bold: true
                                            verticalAlignment: Text.AlignVCenter; leftPadding: 6
                                        }
                                        onCurrentTextChanged: { droidstar.set_cc(_comboCC.currentIndex); }
                                    }
                                }
                            }

                            // === LINE 2: TGID | SERVER ===
                            Row {
                                width: parent.width
                                spacing: 4

                                // TGID (Talk Group ID)
                                Item {
                                    width: parent.width * 0.35; height: 52
                                    visible: _dmrtgidEdit.visible
                                    Rectangle {
                                        anchors.fill: parent; anchors.topMargin: 10
                                        color: "transparent"
                                        border.color: "white"; border.width: 1; radius: 4
                                    }
                                    Rectangle {
                                        x: 6; y: 3
                                        width: lblTgid.width + 4
                                        height: lblTgid.height
                                        color: "#161B22"
                                    }
                                    Text {
                                        id: lblTgid
                                        x: 8; y: 3
                                        text: "TGID"; color: "white"
                                        font.pixelSize: 10; font.bold: true
                                    }
                                    TextField {
                                        id: _dmrtgidEdit
                                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; top: parent.top; topMargin: 12; margins: 2 }
                                        background: Rectangle { color: "transparent" }
                                        color: "white"
                                        font.pixelSize: 12; font.bold: true
                                        selectByMouse: true; inputMethodHints: "ImhPreferNumbers"
                                        onEditingFinished: { droidstar.tgid_text_changed(_dmrtgidEdit.text) }
                                    }
                                }

                                // SERVER (Server hosts list)
                                Item {
                                    width: _dmrtgidEdit.visible ? (parent.width - parent.width * 0.35 - 4) : parent.width
                                    height: 52
                                    visible: _comboHost.visible
                                    Rectangle {
                                        anchors.fill: parent; anchors.topMargin: 10
                                        color: "transparent"
                                        border.color: "white"; border.width: 1; radius: 4
                                    }
                                    Rectangle {
                                        x: 6; y: 3
                                        width: lblServer.width + 4
                                        height: lblServer.height
                                        color: "#161B22"
                                    }
                                    Text {
                                        id: lblServer
                                        x: 8; y: 3
                                        text: "SERVER"; color: "white"
                                        font.pixelSize: 10; font.bold: true
                                    }
                                    ComboBox {
                                        id: _comboHost
                                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; top: parent.top; topMargin: 12; margins: 2 }
                                        background: Rectangle { color: "transparent" }
                                        contentItem: Text {
                                            text: _comboHost.displayText; color: "white"
                                            font.pixelSize: 12; font.bold: true
                                            verticalAlignment: Text.AlignVCenter; leftPadding: 6
                                            elide: Text.ElideRight
                                        }
                                        onCurrentTextChanged: {
                                            if(settingsTab.mmdvmBox.checked){ droidstar.set_dst(_comboHost.currentText); }
                                            if(!droidstar.get_modelchange()){ droidstar.process_host_change(_comboHost.currentText); }
                                        }
                                    }
                                }
                            }

                            // === LINE 3: MODULE + CAN + PVT + TOGGLES ===
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 10

                                // Module (MOD) - D-STAR Reflector Module (A, B, C...)
                                Item {
                                    width: 50; height: 52
                                    visible: _comboModule.visible
                                    Rectangle {
                                        anchors.fill: parent; anchors.topMargin: 10
                                        color: "transparent"
                                        border.color: "white"; border.width: 1; radius: 4
                                    }
                                    Rectangle {
                                        x: 4; y: 3
                                        width: lblMod.width + 4
                                        height: lblMod.height
                                        color: "#161B22"
                                    }
                                    Text {
                                        id: lblMod
                                        x: 6; y: 3
                                        text: "MOD"; color: "white"
                                        font.pixelSize: 10; font.bold: true
                                    }
                                    ComboBox {
                                        id: _comboModule
                                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; top: parent.top; topMargin: 12; margins: 2 }
                                        model: [" ","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
                                        background: Rectangle { color: "transparent" }
                                        contentItem: Text {
                                            text: _comboModule.displayText; color: "white"
                                            font.pixelSize: 12; font.bold: true
                                            verticalAlignment: Text.AlignVCenter; leftPadding: 4
                                        }
                                        onCurrentTextChanged: { if(_comboMode.loaded){ droidstar.set_module(_comboModule.currentText); } }
                                    }
                                }

                                // M17 CAN
                                Item {
                                    width: 60; height: 52
                                    visible: _comboM17CAN.visible
                                    Rectangle {
                                        anchors.fill: parent; anchors.topMargin: 10
                                        color: "transparent"
                                        border.color: "white"; border.width: 1; radius: 4
                                    }
                                    Rectangle {
                                        x: 4; y: 3
                                        width: lblCan.width + 4
                                        height: lblCan.height
                                        color: "#161B22"
                                    }
                                    Text {
                                        id: lblCan
                                        x: 6; y: 3
                                        text: "CAN"; color: "white"
                                        font.pixelSize: 10; font.bold: true
                                    }
                                    ComboBox {
                                        id: _comboM17CAN
                                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; top: parent.top; topMargin: 12; margins: 2 }
                                        model: ["0","1","2","3","4","5","6","7"]
                                        background: Rectangle { color: "transparent" }
                                        contentItem: Text {
                                            text: _comboM17CAN.displayText; color: "white"
                                            font.pixelSize: 12; font.bold: true
                                            verticalAlignment: Text.AlignVCenter; leftPadding: 4
                                        }
                                        onCurrentTextChanged: { droidstar.set_modemM17CAN(_comboM17CAN.currentText); }
                                    }
                                }

                                // Private Call Toggle (PVT) - DMR Private Call
                                Item {
                                    width: 40; height: 52
                                    visible: _privateBox.visible
                                    Column {
                                        anchors.fill: parent; spacing: 2
                                        Text {
                                            text: "PVT"; color: "white"; font.bold: true; font.pixelSize: 9
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                        Rectangle {
                                            width: 26; height: 38; radius: 13; color: "#222222"
                                            border.color: "#666"; border.width: 2
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            Rectangle {
                                                width: 22; height: 22; radius: 11; x: 2
                                                y: _privateBox.checked ? 2 : 14
                                                color: _privateBox.checked ? "#00CC00" : "#555555"
                                                Behavior on y { NumberAnimation { duration: 100 } }
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: { _privateBox.checked = !_privateBox.checked; }
                                            }
                                        }
                                    }
                                }

                                // QSY Button
                                Item {
                                    id: qsyContainer
                                    width: 50; height: 52
                                    visible: _dmrtgidEdit.visible

                                    property bool canQSY: mainTab.connectbutton.isconnected && _dmrtgidEdit.text.trim() !== "" && _dmrtgidEdit.text !== mainTab.connectedTG

                                    Column {
                                        anchors.fill: parent
                                        spacing: 2

                                        Text {
                                            text: "QSY"
                                            color: qsyContainer.canQSY ? "#00FF00" : "#888888"
                                            font.bold: true
                                            font.pixelSize: 9
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }

                                        Rectangle {
                                            id: qsyBtn
                                            width: 44
                                            height: 38
                                            radius: 6
                                            color: qsyContainer.canQSY ? (qsyMouse.pressed ? "#004D40" : (qsyMouse.containsMouse ? "#00796B" : "#00695C")) : "#222222"
                                            border.color: qsyContainer.canQSY ? "#00FF00" : "#444444"
                                            border.width: 1.5
                                            anchors.horizontalCenter: parent.horizontalCenter

                                            Text {
                                                text: "QSY"
                                                color: qsyContainer.canQSY ? "white" : "#666666"
                                                font.bold: true
                                                font.pixelSize: 11
                                                anchors.centerIn: parent
                                            }

                                            MouseArea {
                                                id: qsyMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                enabled: qsyContainer.canQSY
                                                onClicked: {
                                                    mainTab.triggerQSY();
                                                }
                                            }
                                        }
                                    }
                                }

                                Loader {
                                    sourceComponent: toggleSwitchComponent
                                    onLoaded: { item.labelText = "SWTX"; item.checked = _swtxBox.checked; item.onClickedFunc = function(){ droidstar.set_swtx(item.checked) } }
                                }
                                Loader {
                                    sourceComponent: toggleSwitchComponent
                                    onLoaded: { item.labelText = "SWRX"; item.checked = _swrxBox.checked; item.onClickedFunc = function(){ droidstar.set_swrx(item.checked) } }
                                }
                                Loader {
                                    sourceComponent: toggleSwitchComponent
                                    onLoaded: { item.labelText = "AGC"; item.checked = _agcBox.checked; item.onClickedFunc = function(){ droidstar.set_agc(item.checked) } }
                                }
                            }

                            // === LINE 4: IAX DTMF ===
                            Row {
                                width: parent.width
                                spacing: 6
                                visible: _editIAXDTMF.visible
                                
                                Item {
                                    width: parent.width * 0.70; height: 52
                                    Rectangle {
                                        anchors.fill: parent; anchors.topMargin: 10
                                        color: "transparent"
                                        border.color: "white"; border.width: 1; radius: 4
                                    }
                                    Rectangle {
                                        x: 6; y: 3
                                        width: lblDtmf.width + 4
                                        height: lblDtmf.height
                                        color: "#161B22"
                                    }
                                    Text {
                                        id: lblDtmf
                                        x: 8; y: 3
                                        text: "DTMF"; color: "white"
                                        font.pixelSize: 10; font.bold: true
                                    }
                                    TextField {
                                        id: _editIAXDTMF
                                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; top: parent.top; topMargin: 12; margins: 2 }
                                        background: Rectangle { color: "transparent" }
                                        color: "white"
                                        font.pixelSize: 12; font.bold: true
                                        selectByMouse: true
                                        onEditingFinished: { droidstar.dtmf_text_changed(_editIAXDTMF.text) }
                                    }
                                }
                                
                                Rectangle {
                                    width: parent.width - parent.width * 0.70 - 6; height: 42; radius: 8
                                    anchors.bottom: parent.bottom
                                    color: sendDtmfMouse.pressed ? "#444444" : "#2A2A2A"
                                    border.color: "#555555"; border.width: 1
                                    Text {
                                        text: "SEND"; color: "white"; font.bold: true; font.pixelSize: 12
                                        anchors.centerIn: parent
                                    }
                                    MouseArea {
                                        id: sendDtmfMouse
                                        anchors.fill: parent
                                        onClicked: { _dtmfsendbutton.click(); }
                                    }
                                }
                            }
                        }
                    }
                }



                // === INVISIBLE ELEMENTS (required by backend) ===
                Item {
                    width: 0; height: 0; visible: false
                    // Dummy object to satisfy backend bindings for sliderMicGain
                    Item {
                        id: _slidermicGain
                        property real value: 0.1
                        onValueChanged: {
                            if (value !== mainTab.micValue) {
                                mainTab.micValue = value;
                            }
                        }
                    }
                    CheckBox { id: _swtxBox }
                    CheckBox { id: _swrxBox }
                    CheckBox { id: _agcBox }
                    CheckBox { id: _privateBox }
                    Text { id: _dtmflabel }
                    Text { id: _element3 }
                    Button { id: _dtmfsendbutton; onClicked: { droidstar.click_dtmf(); } }
                    Button {
                        id: _connectbutton
                        property bool isconnected: false
                        function clickConnect() {
                            isconnected = !isconnected;
                            if (isconnected) {
                                mainTab.connectedTG = _dmrtgidEdit.text;
                            } else {
                                mainTab.connectedTG = "";
                            }
                            droidstar.set_callsign(settingsTab.callsignEdit.text.toUpperCase());
                            droidstar.set_module(_comboModule.currentText);
                            droidstar.set_protocol(_comboMode.currentText);
                            droidstar.set_dmrtgid(_dmrtgidEdit.text);
                            droidstar.set_dmrid(settingsTab.dmridEdit.text);
                            droidstar.set_essid(settingsTab.comboEssid.currentText);
                            droidstar.set_bm_password(settingsTab.bmpwEdit.text);
                            droidstar.set_tgif_password(settingsTab.tgifpwEdit.text);
                            droidstar.set_asl_password(settingsTab.aslpwEdit.text);
                            droidstar.set_latitude(settingsTab.latEdit.text);
                            droidstar.set_longitude(settingsTab.lonEdit.text);
                            droidstar.set_location(settingsTab.locEdit.text);
                            droidstar.set_description(settingsTab.descEdit.text);
                            droidstar.set_url(settingsTab.urlEdit.text);
                            droidstar.set_swid(settingsTab.swidEdit.text);
                            droidstar.set_pkgid(settingsTab.pkgidEdit.text);
                            droidstar.set_dmr_options(settingsTab.dmroptsEdit.text);
                            droidstar.set_dmr_pc(_privateBox.checked);
                            droidstar.set_txtimeout(settingsTab.txtimerEdit.text);
                            droidstar.set_xrf2ref(settingsTab.xrf2ref.checked);
                            droidstar.set_ipv6(settingsTab.ipv6.checked);
                            droidstar.set_vocoder(settingsTab.comboVocoder.currentText);
                            droidstar.set_modem(settingsTab.comboModem.currentText);
                            droidstar.set_playback(settingsTab.comboPlayback.currentText);
                            droidstar.set_capture(settingsTab.comboCapture.currentText);
                            droidstar.set_modemRxFreq(settingsTab.modemRXFreqEdit.text);
                            droidstar.set_modemTxFreq(settingsTab.modemTXFreqEdit.text);
                            droidstar.set_modemRxOffset(settingsTab.modemRXOffsetEdit.text);
                            droidstar.set_modemTxOffset(settingsTab.modemTXOffsetEdit.text);
                            droidstar.set_modemRxDCOffset(settingsTab.modemRXDCOffsetEdit.text);
                            droidstar.set_modemTxDCOffset(settingsTab.modemTXDCOffsetEdit.text);
                            droidstar.set_modemRxLevel(settingsTab.modemRXLevelEdit.text);
                            droidstar.set_modemTxLevel(settingsTab.modemRXLevelEdit.text);
                            droidstar.set_modemRFLevel(settingsTab.modemRFLevelEdit.text);
                            droidstar.set_modemTxDelay(settingsTab.modemTXDelayEdit.text);
                            droidstar.set_modemCWIdTxLevel(settingsTab.modemCWIdTXLevelEdit.text);
                            droidstar.set_modemDstarTxLevel(settingsTab.modemDStarTXLevelEdit.text);
                            droidstar.set_modemDMRTxLevel(settingsTab.modemDMRTXLevelEdit.text);
                            droidstar.set_modemYSFTxLevel(settingsTab.modemYSFTXLevelEdit.text);
                            droidstar.set_modemP25TxLevel(settingsTab.modemYSFTXLevelEdit.text);
                            droidstar.set_modemNXDNTxLevel(settingsTab.modemNXDNTXLevelEdit.text);
                            droidstar.set_modemBaud(settingsTab.modemBaudEdit.text);
                            droidstar.process_connect();
                        }
                    }
                }

                // TTS
                Row {
                    spacing: 5
                    ButtonGroup { id: ttsvoicegroup; onClicked: { droidstar.tts_changed(button.text); } }
                    CheckBox { id: mic;  text: "Mic";  checked: true;  ButtonGroup.group: ttsvoicegroup; visible: mainTab.tts }
                    CheckBox { id: tts1; text: "TTS1";                 ButtonGroup.group: ttsvoicegroup; visible: mainTab.tts }
                    CheckBox { id: tts2; text: "TTS2"; checked: true;  ButtonGroup.group: ttsvoicegroup; visible: mainTab.tts }
                    CheckBox { id: tts3; text: "TTS3";                 ButtonGroup.group: ttsvoicegroup; visible: mainTab.tts }
                }
                TextField {
                    id: _ttstxtedit; width: parent.width; height: 35; visible: mainTab.tts
                    onEditingFinished: { droidstar.tts_text_changed(_ttstxtedit.text) }
                }
            }
        }
    }

    Timer {
        id: _uitimer
        interval: 20; running: true; repeat: true
        property int cnt: 0; property int rxcnt: 0; property int last_rxcnt: 0
        onTriggered: update_level()
        function update_level() {
            if(cnt >= 20) {
                if(rxcnt == last_rxcnt){ droidstar.set_output_level(0); rxcnt = 0; }
                else { last_rxcnt = rxcnt; }
                cnt = 0;
            } else { ++cnt; }
            var l = sMeterContainer.width * droidstar.get_output_level() / 32767.0;
            if(l > _levelMeter.width) { _levelMeter.width = l; }
            else { if(_levelMeter.width > 0) _levelMeter.width -= 8; else _levelMeter.width = 0; }
        }
    }
}
