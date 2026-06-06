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
import QtCore

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

    Settings {
        id: uiSettings
        category: "UI"
        property int colorTheme: 0
        property real volValue: 0.5
        property real micValue: 0.1
    }

    property real volValue: uiSettings.volValue
    onVolValueChanged: { uiSettings.volValue = volValue }

    property real micValue: uiSettings.micValue
    onMicValueChanged: { uiSettings.micValue = micValue }
    property int currentLayout: 0 // 0=Basic, 1=Advanced
    property bool isQSYing: false
    property bool isSetMemMode: false
    property string connectedTG: ""
    property bool isAppConnected: _connectbutton.isconnected

    property int colorTheme: uiSettings.colorTheme
    onColorThemeChanged: {
        uiSettings.colorTheme = colorTheme
    }

    property string themeBgColor: !isAppConnected ? "#9FB58B" : (colorTheme === 0 ? "#A8E6CF" : (colorTheme === 1 ? "#A1C6FF" : (colorTheme === 2 ? "#E6A8D7" : (colorTheme === 3 ? "#FF9E9E" : "#FCE081"))))
    property string themeTextColor: !isAppConnected ? "#2E3A23" : (colorTheme === 0 ? "#1B4332" : (colorTheme === 1 ? "#0A3066" : (colorTheme === 2 ? "#4A104A" : (colorTheme === 3 ? "#5A1A1A" : "#5C4E10"))))
    property string themeMeterColor: !isAppConnected ? "#889A7E" : (colorTheme === 0 ? "#82C7AC" : (colorTheme === 1 ? "#6FA0DB" : (colorTheme === 2 ? "#C985BC" : (colorTheme === 3 ? "#D97878" : "#D3B651"))))

    property int activeMemoryIndex: -1

    function isMemActive(index) {
        if (!mainTab || !mainTab.connectbutton) return false;
        try {
            if (!mainTab.connectbutton.isconnected) return false;
            var mem = droidstar.get_memory(index);
            if (!mem || mem["Mode"] === "" || mem["Mode"] === undefined) return false;
            
            var modeText = _comboMode ? _comboMode.currentText : "";
            if (modeText !== mem["Mode"]) return false;
            
            if (mem["Mode"] === "DMR") {
                var slotIdx = _comboSlot ? _comboSlot.currentIndex : -1;
                var ccIdx = _comboCC ? _comboCC.currentIndex : -1;
                var tgidText = _dmrtgidEdit ? _dmrtgidEdit.text : "";
                if (slotIdx !== mem["Slot"]) return false;
                if (ccIdx !== mem["CC"]) return false;
                if (tgidText !== mem["TGID"]) return false;
            } else if (mem["Mode"] === "P25" || mem["Mode"] === "NXDN") {
                var tgidText = _dmrtgidEdit ? _dmrtgidEdit.text : "";
                if (tgidText !== mem["TGID"]) return false;
            }
            
            var hostText = _comboHost ? _comboHost.currentText : "";
            if (hostText !== mem["Host"]) return false;
            return true;
        } catch (e) {
            return false;
        }
    }

    function applyMemory(index) {
        var mem = droidstar.get_memory(index);
        if (mem["Mode"] !== "" && mem["Mode"] !== undefined) {
            _comboMode.currentIndex = _comboMode.find(mem["Mode"]);
            _comboSlot.currentIndex = mem["Slot"];
            _comboCC.currentIndex = mem["CC"];
            _dmrtgidEdit.text = mem["TGID"];
            
            // Explicitly send values to backend
            droidstar.set_slot(mem["Slot"]);
            droidstar.set_cc(mem["CC"]);
            droidstar.set_dmrtgid(mem["TGID"]);
            droidstar.tgid_text_changed(mem["TGID"]);

            droidstar.process_host_change(mem["Host"]);
            _comboHost.currentIndex = _comboHost.find(mem["Host"]);
        }
    }

    Timer {
        id: memoryQsyTimer
        interval: 5000
        repeat: false
        running: false
        property int targetIndex: -1
        onTriggered: {
            applyMemory(targetIndex);
            mainTab.connectbutton.clickConnect();
            mainTab.isQSYing = false;
        }
    }

    function triggerMemory(index) {
        var mem = droidstar.get_memory(index);
        if (mem["Mode"] === "" || mem["Mode"] === undefined) {
            console.log("Memory slot", index, "is empty, ignoring click.");
            return;
        }
        if (isMemActive(index)) return;
        
        if (mainTab.connectbutton.isconnected) {
            mainTab.isQSYing = true;
            memoryQsyTimer.targetIndex = index;
            mainTab.connectbutton.clickConnect();
            memoryQsyTimer.start();
        } else {
            applyMemory(index);
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
	property alias comboSlotItem: _comboSlotItem
	property alias comboCC: _comboCC
	property alias comboCCItem: _comboCCItem
	property alias dmrtgidEdit: _dmrtgidEdit
	property alias dmrtgidEditItem: _dmrtgidEditItem
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
        source: "../shared/fonts/arcade_pizzadude/ARCADE.TTF"
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
        var dateStr = d.getUTCFullYear() + "-" + 
                      ("0" + (d.getUTCMonth()+1)).slice(-2) + "-" + 
                      ("0" + d.getUTCDate()).slice(-2);
                      
        // Check for duplicates in last entry to prevent consecutive duplicates
        if (lastHeardModel.count > 0) {
            var firstItem = lastHeardModel.get(0);
            if (firstItem.callsign === callsign) {
                // Update time, country and name if available
                lastHeardModel.setProperty(0, "utc", utcTime);
                lastHeardModel.setProperty(0, "date", dateStr);
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
        droidstar.appendToStationLog(dateStr, utcTime, callsign, name, country);
        if (typeof stationLogTab !== "undefined") {
            stationLogTab.refreshLog();
        }
        
        // Insert new entry at the beginning
        lastHeardModel.insert(0, {
            "utc": utcTime,
            "date": dateStr,
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
                        color: checked ? mainTab.themeBgColor : "#555555"
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

            // --- LEFT AMBER SCREEN ---
    Rectangle {
        id: screenBezel
        x: 5; y: 5
        width: (parent.width * 0.60) - 10
        height: 140
        color: "#222222"
        radius: 10
        border.color: "#555555"
        border.width: 2

        Rectangle {
            id: glassCard
            anchors.fill: parent
            anchors.margins: 4
            color: mainTab.themeBgColor
            radius: 4
            border.color: "transparent"

            // Hidden level meter for C++ bindings to calculate properly
            Item {
                id: hiddenSMeter
                anchors.fill: parent
                visible: false
                Rectangle {
                    id: _levelMeter
                    width: 0
                }
            }

            // Hidden labels/data to satisfy C++ property aliases
            Item {
                visible: false
                Text { id: _label1 }
                Text { id: _label2 }
                Text { id: _data2 }
                Text { id: _label5 }
                Text { id: _label6 }
                Text { id: _data6 }
                Text { id: _label7 }
            }

            // Top Left: Callsign/Name
            Text {
                id: _data1
                x: 10
                y: 15
                text: "" 
                color: mainTab.themeTextColor
                font.family: llpixelFont.name
                font.pixelSize: 34
                font.bold: true
                style: Text.Raised; styleColor: "#40000000"
                visible: !mainTab.isQSYing
                onTextChanged: {
                    if (text && text.trim() !== "") {
                        var callsign = text.trim().split(/\s+/)[0].toUpperCase();
                        var c = getCountryFromCallsign(callsign);
                        if (c === "Unknown" && _data6.text !== "") {
                            c = _data6.text;
                        }
                        _data7.text = (c !== "Unknown") ? c : "";
                    } else {
                        _data7.text = "";
                    }
                }
            }

            // Country Variable
            Text {
                id: _data7
                anchors.top: _data1.bottom
                anchors.topMargin: -4
                anchors.left: _data1.left
                color: mainTab.themeTextColor
                font.family: llpixelFont.name
                font.pixelSize: 16
                font.bold: true
                style: Text.Raised; styleColor: "#40000000"
                visible: !mainTab.isQSYing
            }

            // Relocated QSY wait text
            Text {
                id: qsySearchingText
                x: 10
                y: 20
                text: "changing TG, please wait..."
                color: mainTab.themeTextColor
                font.family: llpixelFont.name
                font.pixelSize: 24
                font.bold: true
                style: Text.Raised; styleColor: "#40000000"
                visible: mainTab.isQSYing
            }

            // Top Right: Custom S-Meter
            Column {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.top: parent.top
                anchors.topMargin: 20
                spacing: 2
                scale: 0.85
                transformOrigin: Item.TopRight
                
                Row {
                    id: smeterRow
                    spacing: 4
                    property real levelRatio: _levelMeter.width / Math.max(1, hiddenSMeter.width)
                    
                    Repeater {
                        model: 10
                        Item {
                            width: 14
                            height: 28
                            Rectangle {
                                anchors.bottom: parent.bottom; anchors.bottomMargin: -1
                                anchors.left: parent.left; anchors.leftMargin: 1
                                width: 14
                                height: 10 + (index * 2)
                                color: "#40000000"
                                radius: 2
                            }
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: 14
                                height: 10 + (index * 2)
                                color: (parent.parent.levelRatio > (index / 10.0)) ? mainTab.themeTextColor : mainTab.themeMeterColor
                                radius: 2
                                
                                // Dot inside the bar for 1, 5, 9
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 4
                                    height: 4
                                    radius: 2
                                    color: mainTab.themeBgColor
                                    visible: index === 0 || index === 4 || index === 8
                                }
                            }
                        }
                    }
                }
                Row {
                    width: parent.width
                    Text { text: "1"; color: smeterRow.levelRatio > 0.0 ? mainTab.themeTextColor : mainTab.themeMeterColor; font.pixelSize: 10; font.bold: true; width: 18 * 4; horizontalAlignment: Text.AlignHCenter; style: Text.Raised; styleColor: "#40000000" }
                    Text { text: "5"; color: smeterRow.levelRatio > 0.4 ? mainTab.themeTextColor : mainTab.themeMeterColor; font.pixelSize: 10; font.bold: true; width: 18 * 4; horizontalAlignment: Text.AlignHCenter; style: Text.Raised; styleColor: "#40000000" }
                    Text { text: "9"; color: smeterRow.levelRatio > 0.8 ? mainTab.themeTextColor : mainTab.themeMeterColor; font.pixelSize: 10; font.bold: true; width: 18 * 2; horizontalAlignment: Text.AlignHCenter; style: Text.Raised; styleColor: "#40000000" }
                }
            }

            // Bottom Left: DestID and GatewayID Boxes
            Row {
                x: 10
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                spacing: 15

                // DestID Box
                Item {
                    width: 110
                    height: 54

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 8
                        color: "transparent"
                        border.color: "#000000"
                        border.width: 2
                        radius: 8
                    }
                    Rectangle {
                        x: 10; y: 0
                        width: lblDest.width + 8
                        height: lblDest.height
                        color: mainTab.themeBgColor
                    }
                    Text {
                        id: lblDest
                        x: 14; y: 0
                        text: "DestID"
                        color: "#000000"
                        font.pixelSize: 10
                        font.bold: true
                    }
                    Text {
                        id: _label3
                        visible: false
                    }
                    Text {
                        id: _data3
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 4
                        text: ""
                        color: mainTab.themeTextColor
                        font.family: llpixelFont.name
                        font.pixelSize: 26
                        font.bold: true
                        style: Text.Raised; styleColor: "#40000000"
                    }
                }

                // GatewayID Box
                Item {
                    width: 160
                    height: 54

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 8
                        color: "transparent"
                        border.color: "#000000"
                        border.width: 2
                        radius: 8
                    }
                    Rectangle {
                        x: 10; y: 0
                        width: lblGateway.width + 8
                        height: lblGateway.height + 1
                        color: mainTab.themeBgColor
                    }
                    Text {
                        id: lblGateway
                        x: 14; y: 0
                        text: "GatewayID"
                        color: "#000000"
                        font.pixelSize: 10
                        font.bold: true
                    }
                    Text {
                        id: _label4
                        visible: false
                    }
                    Text {
                        id: _data4
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 4
                        text: ""
                        color: mainTab.themeTextColor
                        font.family: llpixelFont.name
                        font.pixelSize: 26
                        font.bold: true
                        style: Text.Raised; styleColor: "#40000000"
                    }
                }
            }

            // Bottom Right: Statuses
            Column {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                spacing: 2
                
                Text { id: _ambestatus; text: ""; color: mainTab.themeTextColor; font.family: llpixelFont.name; font.pixelSize: 12; font.bold: true; style: Text.Raised; styleColor: "#40000000" }
                Text { id: _mmdvmstatus; text: ""; color: mainTab.themeTextColor; font.family: llpixelFont.name; font.pixelSize: 12; font.bold: true; style: Text.Raised; styleColor: "#40000000" }
                Text { id: _netstatus; text: ""; color: mainTab.themeTextColor; font.family: llpixelFont.name; font.pixelSize: 12; font.bold: true; style: Text.Raised; styleColor: "#40000000" }
                Text { id: _data5; text: ""; color: mainTab.themeTextColor; font.family: llpixelFont.name; font.pixelSize: 12; font.bold: true; style: Text.Raised; styleColor: "#40000000" }
            }



        }
    }

    // --- AUDIO CONTROLS (Under Amber Screen) ---
    Rectangle {
        id: audioControlsCard
        x: 5
        y: 150
        width: (parent.width * 0.60) - 10
        height: 100
        color: "transparent"

        Row {
            anchors.centerIn: parent
            spacing: 20

            // PTT key
            Column {
                spacing: 12
                Text { text: "PTT"; color: "white"; font.bold: true; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                Rectangle {
                    id: _buttonTX
                    width: 64; height: 64; radius: 10
                    color: tx ? "#FF3333" : "#2A2A2A"
                    border.color: tx ? "#FF8888" : "#555555"; border.width: 3
                    property bool tx: false; property int cnt: 0
                    Behavior on color { ColorAnimation { duration: 150 } }
                    
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

            // VOL CONTROL (Horizontal Slider)
            Column {
                spacing: 6
                Text { text: "VOL"; color: "white"; font.bold: true; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                
                Row {
                    transform: Translate { y: 5 }
                    spacing: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    Repeater {
                        model: 11
                        Rectangle {
                            width: 3; height: 6; radius: 1.5
                            color: index <= Math.round(volValue * 10) ? "#FFFFFF" : "#444444"
                        }
                    }
                }
                
                Slider {
                    id: volDial
                    transform: Translate { y: 5 }
                    width: 120; height: 20
                    from: 0.0; to: 1.0; value: volValue
                    anchors.horizontalCenter: parent.horizontalCenter
                    onValueChanged: {
                        volValue = value;
                        droidstar.set_output_volume(volValue);
                    }
                    
                    background: Rectangle {
                        x: volDial.leftPadding
                        y: volDial.topPadding + volDial.availableHeight / 2 - height / 2
                        width: volDial.availableWidth
                        height: 6
                        color: "#181818"
                        radius: 3
                        border.color: "#555555"
                        border.width: 1
                        Rectangle {
                            width: volDial.visualPosition * parent.width
                            height: parent.height
                            color: "#555555"
                            radius: 3
                        }
                    }
                    handle: Rectangle {
                        x: volDial.leftPadding + volDial.visualPosition * (volDial.availableWidth - width)
                        y: volDial.topPadding + volDial.availableHeight / 2 - height / 2
                        width: 20; height: 20
                        color: "#181818"
                        radius: 4
                        border.color: "#555555"
                        border.width: 1.5
                        Rectangle {
                            width: 2; height: 12
                            color: "#FFFFFF"
                            anchors.centerIn: parent
                        }
                    }
                }
            }

            // MIC CONTROL (Horizontal Slider)
            Column {
                spacing: 6
                Text { text: "MIC"; color: "white"; font.bold: true; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                
                Row {
                    transform: Translate { y: 5 }
                    spacing: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    Repeater {
                        model: 11
                        Rectangle {
                            width: 3; height: 6; radius: 1.5
                            color: index <= Math.round(micValue * 10) ? "#FFFFFF" : "#444444"
                        }
                    }
                }
                
                Slider {
                    id: micDial
                    transform: Translate { y: 5 }
                    width: 120; height: 20
                    from: 0.0; to: 1.0; value: micValue
                    anchors.horizontalCenter: parent.horizontalCenter
                    onValueChanged: {
                        micValue = value;
                        _slidermicGain.value = micValue;
                        droidstar.set_input_volume(micValue);
                    }
                    
                    background: Rectangle {
                        x: micDial.leftPadding
                        y: micDial.topPadding + micDial.availableHeight / 2 - height / 2
                        width: micDial.availableWidth
                        height: 6
                        color: "#181818"
                        radius: 3
                        border.color: "#555555"
                        border.width: 1
                        Rectangle {
                            width: micDial.visualPosition * parent.width
                            height: parent.height
                            color: "#555555"
                            radius: 3
                        }
                    }
                    handle: Rectangle {
                        x: micDial.leftPadding + micDial.visualPosition * (micDial.availableWidth - width)
                        y: micDial.topPadding + micDial.availableHeight / 2 - height / 2
                        width: 20; height: 20
                        color: "#181818"
                        radius: 4
                        border.color: "#555555"
                        border.width: 1.5
                        Rectangle {
                            width: 2; height: 12
                            color: "#FFFFFF"
                            anchors.centerIn: parent
                        }
                    }
                }
            }

            // COLOR BUTTON
            Column {
                spacing: 12
                Text { text: "COLOR"; color: "white"; font.bold: true; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                Rectangle {
                    width: 42; height: 42; radius: 10
                    color: "#2A2A2A"
                    border.color: "#555555"; border.width: 3
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            mainTab.colorTheme = (mainTab.colorTheme + 1) % 5;
                        }
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 16; height: 4; radius: 2
                        color: mainTab.themeBgColor
                    }
                }
            }
        }
    }

    // --- RIGHT CONTROLS ---
    Rectangle {
        id: controlsCard
        x: parent.width * 0.60
        y: 5
        width: parent.width * 0.40
        height: parent.height - 10
        color: "transparent"

        ScrollView {
            anchors.fill: parent
            contentWidth: parent.width
            contentHeight: controlCol.height + 20
            clip: true

            Column {
                id: controlCol
                width: parent.width - 10
                x: 5
                spacing: 10

                // Dials and PTT moved to Left Column

                // === STATIC SERVER SETTINGS PANEL ===
                Column {
                    id: serverSettingsPanel
                    width: parent.width
                    spacing: 4
                    z: 10
                    
                    // Content
                    Item {
                        id: collapsArea
                        width: parent.width
                        height: collapsCol.height + 16
                        clip: true
                        z: 20
                        
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
                                        if (!_comboSlotItem.visible && !_comboCCItem.visible) {
                                            return parent.width;
                                        } else if (_comboSlotItem.visible && !_comboCCItem.visible) {
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
                                    id: _comboSlotItem
                                    width: {
                                        if (!_comboCCItem.visible) {
                                            return parent.width - parent.width * 0.35 - 4;
                                        } else {
                                            return parent.width * 0.30;
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
                                    id: _comboCCItem
                                    width: parent.width - parent.width * 0.35 - parent.width * 0.30 - 8; height: 52
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
                                    id: _dmrtgidEditItem
                                    width: parent.width * 0.35; height: 52
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
                                    width: _dmrtgidEditItem.visible ? (parent.width - parent.width * 0.35 - 4) : parent.width
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
                                        property string searchText: ""
                                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; top: parent.top; topMargin: 12; margins: 2 }
                                        background: Rectangle { color: "transparent" }
                                        contentItem: Text {
                                            text: _comboHost.displayText; color: "white"
                                            font.pixelSize: 12; font.bold: true
                                            verticalAlignment: Text.AlignVCenter; leftPadding: 6
                                            elide: Text.ElideRight
                                        }
                                        popup: Popup {
                                            y: _comboHost.height - 1
                                            width: _comboHost.width
                                            implicitHeight: Math.min(300, contentItem.implicitHeight + 10)
                                            padding: 4
                                            background: Rectangle { color: "#2A2A2A"; border.color: "#555555" }
                                            onOpened: { searchInput.text = ""; searchInput.forceActiveFocus(); }
                                            contentItem: Column {
                                                spacing: 4
                                                TextField {
                                                    id: searchInput
                                                    width: parent.width
                                                    height: 28
                                                    placeholderText: "Search..."
                                                    placeholderTextColor: "white"
                                                    color: "white"
                                                    font.pixelSize: 12
                                                    verticalAlignment: TextInput.AlignVCenter
                                                    leftPadding: 6
                                                    background: Rectangle { color: "#181818"; border.color: "#444"; border.width: 1 }
                                                    onTextChanged: _comboHost.searchText = text.toLowerCase()
                                                }
                                                ListView {
                                                    id: listview
                                                    clip: true
                                                    width: parent.width
                                                    implicitHeight: contentHeight > 250 ? 250 : contentHeight
                                                    model: _comboHost.popup.visible ? _comboHost.delegateModel : null
                                                    currentIndex: _comboHost.highlightedIndex
                                                    ScrollIndicator.vertical: ScrollIndicator { }
                                                }
                                            }
                                        }
                                        delegate: ItemDelegate {
                                            width: _comboHost.width
                                            height: visible ? 35 : 0
                                            visible: _comboHost.searchText === "" || modelData.toLowerCase().includes(_comboHost.searchText)
                                            text: modelData
                                            font.pixelSize: 12
                                            contentItem: Text {
                                                text: parent.text
                                                color: parent.highlighted ? "#FFA100" : "white"
                                                elide: Text.ElideRight
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                            background: Rectangle {
                                                color: parent.highlighted ? "#333333" : "transparent"
                                            }
                                            highlighted: _comboHost.highlightedIndex === index
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
                                width: parent.width
                                spacing: 4

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

                                // SET MEM Button
                                Item {
                                    id: setMemContainer
                                    width: parent.width * 0.35; height: 52
                                    visible: _dmrtgidEdit.visible

                                    Column {
                                        anchors.fill: parent
                                        spacing: 2

                                        Text {
                                            text: "SET MEMORY"
                                            color: mainTab.isSetMemMode ? mainTab.themeBgColor : "#888888"
                                            font.bold: true
                                            font.pixelSize: 9
                                            anchors.left: parent.left
                                            anchors.leftMargin: 6
                                        }

                                        Rectangle {
                                            id: setMemBtn
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.rightMargin: 6
                                            height: 38
                                            radius: 8
                                            color: mainTab.isSetMemMode ? Qt.darker(mainTab.themeBgColor, 1.2) : (setMemMouse.pressed ? "#444444" : "#222222")
                                            border.color: mainTab.isSetMemMode ? Qt.lighter(mainTab.themeBgColor, 1.2) : "#444444"
                                            border.width: mainTab.isSetMemMode ? 2 : 1.5

                                            Text {
                                                text: "SET"
                                                color: mainTab.isSetMemMode ? "white" : "#888888"
                                                font.bold: true
                                                font.pixelSize: 12
                                                anchors.centerIn: parent
                                            }

                                            MouseArea {
                                                id: setMemMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onClicked: {
                                                    mainTab.isSetMemMode = !mainTab.isSetMemMode;
                                                    console.log("[SET MEMORY] toggled. isSetMemMode =", mainTab.isSetMemMode);
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
                                Column {
                                    spacing: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - x // Fill remaining width
                                    Text {
                                        text: "LOGBOOK"
                                        color: "white"
                                        font.bold: true
                                        font.pixelSize: 9
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Rectangle {
                                        id: _btnLogbook
                                        width: parent.width
                                        height: 38; radius: 8
                                        color: logbookPopup.opened ? "#444444" : "#2A2A2A"
                                        border.color: logbookPopup.opened ? mainTab.themeBgColor : "#555555"
                                        border.width: logbookPopup.opened ? 2 : 1
                                        Behavior on border.color { ColorAnimation { duration: 150 } }
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        
                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 4
                                            opacity: 0.6
                                            Repeater {
                                                model: 3
                                                Rectangle {
                                                    width: 4; height: 16; radius: 2
                                                    color: "white"
                                                }
                                            }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                if (logbookPopup.opened) logbookPopup.close();
                                                else logbookPopup.open();
                                            }
                                        }
                                    }
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

                            // === LINE 5: MEMORY PRESETS ===
                            Row {
                                width: parent.width
                                height: 52
                                spacing: 4

                                Item {
                                    width: parent.width; height: 52
                                    Rectangle {
                                        anchors.fill: parent; anchors.topMargin: 10
                                        color: "transparent"
                                        border.color: "white"; border.width: 1; radius: 4
                                    }
                                    Rectangle {
                                        x: 6; y: 3
                                        width: lblMemory.width + 4
                                        height: lblMemory.height
                                        color: "#161B22"
                                    }
                                    Text {
                                        id: lblMemory
                                        x: 8; y: 3
                                        text: "MEMORY"; color: "white"
                                        font.pixelSize: 10; font.bold: true
                                    }

                                    Row {
                                        id: memButtonsRow
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        anchors.top: parent.top
                                        anchors.topMargin: 15
                                        height: 32
                                        spacing: 10
                                        
                                        Repeater {
                                            model: 5
                                            Rectangle {
                                                property int slotIndex: index
                                                width: (parent.width - 40) / 5
                                                height: 32
                                                radius: 8
                                                color: "#2A2A2A"
                                                border.color: mainTab.isSetMemMode ? mainTab.themeBgColor : (isMemActive(slotIndex) ? mainTab.themeBgColor : "#555555")
                                                border.width: mainTab.isSetMemMode ? 2 : (isMemActive(slotIndex) ? 2.5 : 1)
                                                
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: (slotIndex + 1).toString()
                                                    color: "white"
                                                    font.bold: true
                                                    font.pixelSize: 12
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        console.log("Memory slot", slotIndex, "clicked. isSetMemMode =", mainTab.isSetMemMode);
                                                        if (mainTab.isSetMemMode) {
                                                            try {
                                                                var modeText = _comboMode ? _comboMode.currentText : "";
                                                                var hostText = _comboHost ? _comboHost.currentText : "";
                                                                var slotVal = _comboSlot ? _comboSlot.currentIndex : 0;
                                                                var ccVal = _comboCC ? _comboCC.currentIndex : 0;
                                                                var tgidVal = _dmrtgidEdit ? _dmrtgidEdit.text : "";
                                                                
                                                                if (slotVal < 0) slotVal = 0;
                                                                if (ccVal < 0) ccVal = 0;
                                                                
                                                                console.log("Saving memory slot:", slotIndex, "Mode:", modeText, "Host:", hostText, "Slot:", slotVal, "CC:", ccVal, "TGID:", tgidVal);
                                                                droidstar.save_memory(slotIndex, modeText, hostText, slotVal, ccVal, tgidVal);
                                                                console.log("Memory saved successfully!");
                                                            } catch (e) {
                                                                console.log("Error saving memory:", e.message);
                                                            }
                                                            mainTab.isSetMemMode = false;
                                                        } else {
                                                            mainTab.triggerMemory(slotIndex);
                                                        }
                                                    }
                                                    onPressAndHold: {
                                                        console.log("Memory slot", slotIndex, "pressAndHold (clear).");
                                                        try {
                                                            droidstar.save_memory(slotIndex, "", "", 0, 0, "");
                                                            console.log("Memory cleared successfully!");
                                                        } catch (e) {
                                                            console.log("Error clearing memory:", e.message);
                                                        }
                                                        mainTab.isSetMemMode = false;
                                                    }
                                                }
                                            }
                                        }
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
                            _dmrtgidEdit.focus = false;
                            mainTab.forceActiveFocus();
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
            var l = hiddenSMeter.width * droidstar.get_output_level() / 32767.0;
            if(l > _levelMeter.width) { _levelMeter.width = l; }
            else { if(_levelMeter.width > 0) _levelMeter.width -= 8; else _levelMeter.width = 0; }
        }
    }

    Popup {
        id: logbookPopup
        parent: mainTab
        x: 5
        y: 260
        width: mainTab.width - 10
        height: 245
        padding: 0
        background: Rectangle { color: "transparent" }
        closePolicy: Popup.CloseOnEscape

        onOpened: {
            mainTab.Window.window.maximumHeight = 505;
            mainTab.Window.window.minimumHeight = 505;
            mainTab.Window.window.height = 505;
        }
        onClosed: {
            mainTab.Window.window.minimumHeight = 310;
            mainTab.Window.window.maximumHeight = 310;
            mainTab.Window.window.height = 310;
        }

        Rectangle {
            anchors.fill: parent
            color: mainTab.themeBgColor
            border.color: "#333333"
            border.width: 4
            radius: 8

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                color: "transparent"
                border.color: Qt.rgba(1,1,1,0.2)
                border.width: 2
                radius: 4
            }

            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6
                
                Text {
                    text: "Last heard:"
                    color: "black"
                    font.pixelSize: 10
                    font.bold: true
                }

                Row {
                    width: parent.width - 10
                    spacing: 0
                    Text { width: parent.width * 0.20; text: "CallSign"; color: "black"; font.pixelSize: 10; font.bold: true }
                    Text { width: parent.width * 0.20; text: "Name"; color: "black"; font.pixelSize: 10; font.bold: true }
                    Text { width: parent.width * 0.20; text: "Country"; color: "black"; font.pixelSize: 10; font.bold: true }
                    Text { width: parent.width * 0.30; text: "Date"; color: "black"; font.pixelSize: 10; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                    Text { width: parent.width * 0.10; text: "Time"; color: "black"; font.pixelSize: 10; font.bold: true }
                }
                
                Rectangle {
                    width: parent.width - 10
                    height: 2
                    color: "black"
                    opacity: 0.5
                }
                
                ListView {
                    width: parent.width - 10
                    height: parent.height - 70
                    clip: true
                    model: lastHeardModel
                    spacing: 6
                    delegate: Row {
                        spacing: 0
                        width: parent.width
                        Text { width: parent.width * 0.20; text: callsign; color: mainTab.themeTextColor; font.family: llpixelFont.name; font.pixelSize: 22; font.bold: true; style: Text.Raised; styleColor: "#40000000"; elide: Text.ElideRight }
                        Text { width: parent.width * 0.20; text: name; color: mainTab.themeTextColor; font.family: llpixelFont.name; font.pixelSize: 22; font.bold: true; style: Text.Raised; styleColor: "#40000000"; elide: Text.ElideRight }
                        Text { width: parent.width * 0.20; text: country; color: mainTab.themeTextColor; font.family: llpixelFont.name; font.pixelSize: 22; font.bold: true; style: Text.Raised; styleColor: "#40000000"; elide: Text.ElideRight }
                        Text { width: parent.width * 0.30; text: typeof date !== "undefined" ? date : ""; color: mainTab.themeTextColor; font.family: llpixelFont.name; font.pixelSize: 22; font.bold: true; style: Text.Raised; styleColor: "#40000000"; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter }
                        Text { width: parent.width * 0.10; text: utc; color: mainTab.themeTextColor; font.family: llpixelFont.name; font.pixelSize: 22; font.bold: true; style: Text.Raised; styleColor: "#40000000"; elide: Text.ElideRight }
                    }
                }
            }
        }
    }

}
