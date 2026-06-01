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
	id: settingsTab
	property alias callsignEdit: csedit
	property alias dmridEdit: dmridedit
	property alias comboEssid: comboessid
	property alias bmpwEdit: bmpwedit
	property alias tgifpwEdit: tgifpwedit
	property alias aslpwEdit: aslpwedit
	property alias latEdit: latedit
	property alias lonEdit: lonedit
	property alias locEdit: locedit
	property alias descEdit: descedit
	property alias urlEdit: urledit
	property alias swidEdit: swidedit
	property alias pkgidEdit: pkgidedit
	property alias dmroptsEdit: dmroptsedit
	property alias m173200: m17_3200
	property alias m171600: m17_1600
	property alias mycallEdit: mycalledit
	property alias urcallEdit: urcalledit
	property alias rptr1Edit: rptr1edit
	property alias rptr2Edit: rptr2edit
	property alias usrtxtEdit: usrtxtedit
	property alias txtimerEdit: txtimeredit
	property alias toggleTX: toggletx
	property alias xrf2ref: xrf2Ref
	property alias ipv6: ipV6
	property alias comboVocoder: _comboVocoder
	property alias comboModem: _comboModem
	property alias comboPlayback: _comboPlayback
	property alias comboCapture: _comboCapture
	property alias modemRXFreqEdit: _modemRXFreqEdit
	property alias modemTXFreqEdit: _modemTXFreqEdit
	property alias modemRXOffsetEdit: _modemRXOffsetEdit
	property alias modemTXOffsetEdit: _modemTXOffsetEdit
	property alias modemRXDCOffsetEdit: _modemRXDCOffsetEdit
	property alias modemTXDCOffsetEdit: _modemTXDCOffsetEdit
	property alias modemRXLevelEdit: _modemRXLevelEdit
	property alias modemTXLevelEdit: _modemTXLevelEdit
	property alias modemRFLevelEdit: _modemRFLevelEdit
	property alias modemTXDelayEdit: _modemTXDelayEdit
	property alias modemCWIdTXLevelEdit: _modemCWIdTXLevelEdit
	property alias modemDStarTXLevelEdit: _modemDStarTXLevelEdit
	property alias modemDMRTXLevelEdit: _modemDMRTXLevelEdit
	property alias modemYSFTXLevelEdit: _modemYSFTXLevelEdit
	property alias modemP25TXLevelEdit: _modemP25TXLevelEdit
	property alias modemNXDNTXLevelEdit: _modemNXDNTXLevelEdit
	property alias modemBaudEdit: _modemBaudEdit
    property alias mmdvmBox: _mmdvmBox
    property alias debugBox: _debugBox

	Flickable {
		id: flickable
		anchors.fill: parent
		contentWidth: parent.width
        contentHeight: _debugBox.y +
                       _debugBox.height + 10
		flickableDirection: Flickable.VerticalFlick
		clip: true
		ScrollBar.vertical: ScrollBar {}

		Text {
			id: vocoderLabel
			x: 10
			anchors.verticalCenter: _comboVocoder.verticalCenter
			width: 80
			text: qsTr("Vocoder")
			color: "white"
		}
		ComboBox {
			id: _comboVocoder
			x: 100
			y: 0
			width: parent.width - 110
			height: 30
		}
		Text {
			id: modemLabel
			x: 10
			anchors.verticalCenter: _comboModem.verticalCenter
			width: 80
			text: qsTr("Modem")
			color: "white"
		}
		ComboBox {
			id: _comboModem
			x: 100
			y: 30
			width: parent.width - 110
			height: 30
		}
		Text {
			id: playbackLabel
			x: 10
			anchors.verticalCenter: _comboPlayback.verticalCenter
			width: 80
			text: qsTr("Playback")
			color: "white"
		}
		ComboBox {
			id: _comboPlayback
			x: 100
			y: 60
			width: parent.width - 110
			height: 30
		}
		Text {
			id: captureLabel
			x: 10
			anchors.verticalCenter: _comboCapture.verticalCenter
			width: 80
			text: qsTr("Capture")
			color: "white"
		}
		ComboBox {
			id: _comboCapture
			x: 100
			y: 90
			width: parent.width - 110
			height: 30
		}
		Text {
			id: csLabel
			x: 10
			anchors.verticalCenter: csedit.verticalCenter
			width: 80
			text: qsTr("Callsign")
			color: "white"
		}
		TextField {
			id: csedit
			x: 100
			y: 120
			width: parent.width - 110
			height: 25
			text: qsTr("")
			font.capitalization: Font.AllUppercase
			selectByMouse: true
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: dmridLabel
			x: 10
			anchors.verticalCenter: dmridedit.verticalCenter
			width: 80
			text: qsTr("DMRID")
			color: "white"
		}
		TextField {
			id: dmridedit
			x: 100
			y: 150
			width: parent.width - 110
			height: 25
			selectByMouse: true
			inputMethodHints: "ImhPreferNumbers"
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: essidLabel
			x: 10
			anchors.verticalCenter: comboessid.verticalCenter
			width: 80
			text: qsTr("ESSID")
			color: "white"
		}
		ComboBox {
			id: comboessid
			x: 100
			y: 180
			width: parent.width - 110
			height: 30
			function build_model(){
				var ids = ["None"];
				for(var i = 0; i < 100; ++i){
					ids[i+1] = i.toString().padStart(2, "0");
				}
					comboessid.model = ids;
					comboessid.currentIndex = comboessid.find(droidstar.get_essid());
			}

			Component.onCompleted: build_model();
			onCurrentTextChanged: {
				//console.log("set essid called");
				//droidstar.set_essid(comboessid.currentText);
			}
		}
		Text {
			id: bmpwLabel
			x: 10
			anchors.verticalCenter: bmpwedit.verticalCenter
			width: 80
			text: qsTr("BM Pass")
			color: "white"
		}
		TextField {
			id: bmpwedit
			x: 100
			y: 210
			width: parent.width - 110
			height: 25
			selectByMouse: true
			echoMode: TextInput.Password
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: tgifpwLabel
			x: 10
			anchors.verticalCenter: tgifpwedit.verticalCenter
			width: 80
			text: qsTr("TGIF Pass")
			color: "white"
		}
		TextField {
			id: tgifpwedit
			x: 100
			y: 240
			width: parent.width - 110
			height: 25
			selectByMouse: true
			echoMode: TextInput.Password
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: aslpwLabel
			x: 10
			anchors.verticalCenter: aslpwedit.verticalCenter
			width: 80
			text: qsTr("ASL Pass")
			color: "white"
		}
		TextField {
			id: aslpwedit
			x: 100
			y: 270
			width: parent.width - 110
			height: 25
			selectByMouse: true
			echoMode: TextInput.Password
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: latLabel
			x: 10
			anchors.verticalCenter: latedit.verticalCenter
			width: 80
			text: qsTr("Latitude")
			color: "white"
		}
		TextField {
			id: latedit
			x: 100
			y: 300
			width: parent.width - 110
			height: 25
			selectByMouse: true
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: lonLabel
			x: 10
			anchors.verticalCenter: lonedit.verticalCenter
			width: 80
			text: qsTr("Longitude")
			color: "white"
		}
		TextField {
			id: lonedit
			x: 100
			y: 330
			width: parent.width - 110
			height: 25
			selectByMouse: true
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: locLabel
			x: 10
			anchors.verticalCenter: locedit.verticalCenter
			width: 80
			text: qsTr("Location")
			color: "white"
		}
		TextField {
			id: locedit
			x: 100
			y: 360
			width: parent.width - 110
			height: 25
			selectByMouse: true
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: descLabel
			x: 10
			anchors.verticalCenter: descedit.verticalCenter
			width: 80
			text: qsTr("Description")
			color: "white"
		}
		TextField {
			id: descedit
			x: 100
			y: 390
			width: parent.width - 110
			height: 25
			selectByMouse: true
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: urlLabel
			x: 10
			anchors.verticalCenter: urledit.verticalCenter
			width: 80
			text: qsTr("URL")
			color: "white"
		}
		TextField {
			id: urledit
			x: 100
			y: 420
			width: parent.width - 110
			height: 25
			selectByMouse: true
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: swidLabel
			x: 10
			anchors.verticalCenter: swidedit.verticalCenter
			width: 80
			text: qsTr("SoftwareID")
			color: "white"
		}
		TextField {
			id: swidedit
			x: 100
			y: 450
			width: parent.width - 110
			height: 25
			selectByMouse: true
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: pkgidLabel
			x: 10
			anchors.verticalCenter: pkgidedit.verticalCenter
			width: 80
			text: qsTr("PackageID")
			color: "white"
		}
		TextField {
			id: pkgidedit
			x: 100
			y: 480
			width: parent.width - 110
			height: 25
			selectByMouse: true
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: dmroptslabel
			x: 10
			anchors.verticalCenter: dmroptsedit.verticalCenter
			width: 80
			text: qsTr("DMR+ Opts")
			color: "white"
		}
		TextField {
			id: dmroptsedit
			x: 100
			y: 510
			width: parent.width - 110
			height: 25
			selectByMouse: true
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: mycallLabel
			x: 10
			anchors.verticalCenter: mycalledit.verticalCenter
			width: 80
			text: qsTr("MYCALL")
			color: "white"
		}
		TextField {
			id: mycalledit
			x: 100
			y: 540
			width: parent.width - 110
			height: 25
			selectByMouse: true
			font.capitalization: Font.AllUppercase
			onEditingFinished: {
				droidstar.set_mycall(mycalledit.text.toUpperCase())
			}
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: urcallLabel
			x: 10
			anchors.verticalCenter: urcalledit.verticalCenter
			width: 80
			text: qsTr("URCALL")
			color: "white"
		}
		TextField {
			id: urcalledit
			x: 100
			y: 570
			width: parent.width - 110
			height: 25
			selectByMouse: true
			font.capitalization: Font.AllUppercase
			onEditingFinished: {
				droidstar.set_urcall(urcalledit.text.toUpperCase())
			}
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: rptr1Label
			x: 10
			anchors.verticalCenter: rptr1edit.verticalCenter
			width: 80
			text: qsTr("RPTR1")
			color: "white"
		}
		TextField {
			id: rptr1edit
			x: 100
			y: 600
			width: parent.width - 110
			height: 25
			selectByMouse: true
			font.capitalization: Font.AllUppercase
			onEditingFinished: {
				droidstar.set_rptr1(rptr1edit.text.toUpperCase())
			}
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: rptr2Label
			x: 10
			anchors.verticalCenter: rptr2edit.verticalCenter
			width: 80
			text: qsTr("RPTR2")
			color: "white"
		}
		TextField {
			id: rptr2edit
			x: 100
			y: 630
			width: parent.width - 110
			height: 25
			selectByMouse: true
			font.capitalization: Font.AllUppercase
			onEditingFinished: {
				droidstar.set_rptr2(rptr2edit.text.toUpperCase())
			}
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: usrtxtLabel
			x: 10
			anchors.verticalCenter: usrtxtedit.verticalCenter
			width: 80
			text: qsTr("USRTXT")
			color: "white"
		}
		TextField {
			id: usrtxtedit
			x: 100
			y: 660
			width: parent.width - 110
			height: 25
			selectByMouse: true
			onEditingFinished: {
				droidstar.set_usrtxt(usrtxtedit.text)
			}
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: txtimerLabel
			x: 10
			anchors.verticalCenter: txtimeredit.verticalCenter
			width: 80
			text: qsTr("TX Timeout")
			color: "white"
		}
		TextField {
			id: txtimeredit
			x: 100
			y: 690
			width: parent.width - 110
			height: 25
			selectByMouse: true
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: m17rateLabel
			x: 10
			y: 720
			width: 100
			height: 25
			text: qsTr("M17/YSF rate")
			color: "white"
			verticalAlignment: Text.AlignVCenter
		}
		ButtonGroup {
			id: m17rateGroup
			onClicked: {
                button.text === "Voice Full" ? droidstar.m17_rate_changed(true) : droidstar.m17_rate_changed(false)
			}
		}
		CheckBox {
			id: m17_3200
			x: 120
			y: m17rateLabel.y
			//width: 100
			height: 30
			spacing: 6
			text: qsTr("Voice Full")
			checked: true
			ButtonGroup.group: m17rateGroup
			topPadding: 0
			bottomPadding: 0
		}
		CheckBox {
			id: m17_1600
			x: 220
			y: m17rateLabel.y
			//width: 100
			height: 30
			spacing: 6
			text: qsTr("Voice/Data")
			ButtonGroup.group: m17rateGroup
			topPadding: 0
			bottomPadding: 0
		}
		Button {
			id: updatehostsButton
			x: 10
			y: 750
			width: 150
			height: 30
			text: qsTr("Update hosts")
			onClicked: {
				droidstar.update_host_files()
				updateDialog.open()
			}
		}
		Button {
			id: updatedmridsButton
			x: 170
			y: updatehostsButton.y
			width: 150
			height: 30
			text: qsTr("Update ID files")
			onClicked: {
				droidstar.update_dmr_ids()
				updateDialog.open()
			}
		}
		CheckBox {
			id: toggletx
			x: 10
			y: 780
			//width: 100
			height: 30
			spacing: 6
			text: qsTr("Enable TX toggle mode")
			onClicked:{
				droidstar.set_toggletx(toggleTX.checked);
			}
			topPadding: 0
			bottomPadding: 0
		}
		CheckBox {
			id: xrf2Ref
			x: 10
			y: 810
			//width: 100
			height: 30
			spacing: 6
			text: qsTr("Use REF for XRF")
			topPadding: 0
			bottomPadding: 0
		}
		CheckBox {
			id: ipV6
			x: 10
			y: 840
			//width: 100
			height: 30
			spacing: 6
			text: qsTr("Use IPv6 when available")
			topPadding: 0
			bottomPadding: 0
		}
		Text {
			id: _modemRXFreqLabel
			x: 10
			y: 870
			width: 60
			height: 25
			text: qsTr("RX Freq")
			color: "white"
			verticalAlignment: Text.AlignVCenter
		}
		TextField {
			id: _modemRXFreqEdit
			x: _modemRXFreqLabel.width+20
			y: _modemRXFreqLabel.y
			width: 100
			height: 25
			selectByMouse: true
			inputMethodHints: "ImhPreferNumbers"
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: _modemTXFreqLabel
			x: _modemRXFreqEdit.x + _modemRXFreqEdit.width + 10
			y: _modemRXFreqLabel.y
			width: 60
			height: 25
			text: qsTr("TX Freq")
			color: "white"
			verticalAlignment: Text.AlignVCenter
		}
		TextField {
			id: _modemTXFreqEdit
			x: _modemTXFreqLabel.x + _modemTXFreqLabel.width
			y: _modemRXFreqLabel.y
			width: 100
			height: 25
			selectByMouse: true
			inputMethodHints: "ImhPreferNumbers"
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: _modemRXOffsetLabel
			x: 10
			y: 900
			width: 100
			height: 25
			text: qsTr("RX Offset")
			color: "white"
			verticalAlignment: Text.AlignVCenter
		}
		TextField {
			id: _modemRXOffsetEdit
			x: _modemRXOffsetLabel.x + _modemRXOffsetLabel.width
			y: _modemRXOffsetLabel.y
			width: 60
			height: 25
			selectByMouse: true
			//inputMethodHints: "ImhPreferNumbers"
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: _modemTXOffsetLabel
			x: _modemRXOffsetEdit.x + _modemRXOffsetEdit.width + 10
			y: _modemRXOffsetLabel.y
			width: 100
			height: 25
			text: qsTr("TX Offset")
			color: "white"
			verticalAlignment: Text.AlignVCenter
		}
		TextField {
			id: _modemTXOffsetEdit
			x: _modemTXOffsetLabel.x + _modemTXOffsetLabel.width
			y: _modemRXOffsetLabel.y
			width: 60
			height: 25
			selectByMouse: true
			//inputMethodHints: "ImhPreferNumbers"
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: _modemRXLevelLabel
			x: 10
			y: 930
			width: 100
			height: 25
			text: qsTr("RX Level")
			color: "white"
			verticalAlignment: Text.AlignVCenter
		}
		TextField {
			id: _modemRXLevelEdit
			x: _modemRXLevelLabel.x + _modemRXLevelLabel.width
			y: _modemRXLevelLabel.y
			width: 60
			height: 25
			selectByMouse: true
			inputMethodHints: "ImhPreferNumbers"
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: _modemTXLevelLabel
			x: _modemRXLevelEdit.x + _modemRXLevelEdit.width + 10
			y: _modemRXLevelLabel.y
			width: 100
			height: 25
			text: qsTr("TX Level")
			color: "white"
			verticalAlignment: Text.AlignVCenter
		}
		TextField {
			id: _modemTXLevelEdit
			x: _modemTXLevelLabel.x + _modemTXLevelLabel.width
			y: _modemRXLevelLabel.y
			width: 60
			height: 25
			selectByMouse: true
			inputMethodHints: "ImhPreferNumbers"
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: _modemRXDCOffsetLabel
			x: 10
			y: 960
			width: 100
			height: 25
			text: qsTr("RX DC Offset")
			color: "white"
			verticalAlignment: Text.AlignVCenter
		}
		TextField {
			id: _modemRXDCOffsetEdit
			x: _modemRXDCOffsetLabel.x + _modemRXDCOffsetLabel.width
			y: _modemRXDCOffsetLabel.y
			width: 60
			height: 25
			selectByMouse: true
			inputMethodHints: "ImhPreferNumbers"
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: _modemTXDCOffsetLabel
			x: _modemRXDCOffsetEdit.x + _modemRXDCOffsetEdit.width + 10
			y: _modemRXDCOffsetLabel.y
			width: 100
			height: 25
			text: qsTr("TX DC Offset")
			color: "white"
			verticalAlignment: Text.AlignVCenter
		}
		TextField {
			id: _modemTXDCOffsetEdit
			x: _modemTXDCOffsetLabel.x + _modemTXDCOffsetLabel.width
			y: _modemRXDCOffsetLabel.y
			width: 60
			height: 25
			selectByMouse: true
			inputMethodHints: "ImhPreferNumbers"
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: _modemRFLevelLabel
			x: 10
			y: 990
			width: 100
			height: 25
			text: qsTr("RF Level")
			color: "white"
			verticalAlignment: Text.AlignVCenter
		}
		TextField {
			id: _modemRFLevelEdit
			x: _modemRFLevelLabel.x + _modemRFLevelLabel.width
			y: _modemRFLevelLabel.y
			width: 60
			height: 25
			selectByMouse: true
			inputMethodHints: "ImhPreferNumbers"
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: _modemTXDelayLabel
			x: _modemRFLevelEdit.x + _modemRFLevelEdit.width + 10
			y: _modemRFLevelLabel.y
			width: 100
			height: 25
			text: qsTr("TX Delay")
			color: "white"
			verticalAlignment: Text.AlignVCenter
		}
		TextField {
			id: _modemTXDelayEdit
			x: _modemTXDelayLabel.x + _modemTXDelayLabel.width
			y: _modemRFLevelLabel.y
			width: 60
			height: 25
			selectByMouse: true
			inputMethodHints: "ImhPreferNumbers"
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: _modemCWIdTXLevelLabel
			x: 10
			y: 1020
			width: 100
			height: 25
			text: qsTr("CWIdTXLevel")
			color: "white"
			verticalAlignment: Text.AlignVCenter
		}
		TextField {
			id: _modemCWIdTXLevelEdit
			x: _modemCWIdTXLevelLabel.x + _modemCWIdTXLevelLabel.width
			y: _modemCWIdTXLevelLabel.y
			width: 60
			height: 25
			selectByMouse: true
			inputMethodHints: "ImhPreferNumbers"
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: _modemDStarTXLevelLabel
			x: _modemCWIdTXLevelEdit.x + _modemCWIdTXLevelEdit.width + 10
			y: _modemCWIdTXLevelLabel.y
			width: 100
			height: 25
			text: qsTr("DStarTXLevel")
			color: "white"
			verticalAlignment: Text.AlignVCenter
		}
		TextField {
			id: _modemDStarTXLevelEdit
			x: _modemDStarTXLevelLabel.x + _modemDStarTXLevelLabel.width
			y: _modemCWIdTXLevelLabel.y
			width: 60
			height: 25
			selectByMouse: true
			inputMethodHints: "ImhPreferNumbers"
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: _modemDMRTXLevelLabel
			x: 10
			y: 1050
			width: 100
			height: 25
			text: qsTr("DMRTXLevel")
			color: "white"
			verticalAlignment: Text.AlignVCenter
		}
		TextField {
			id: _modemDMRTXLevelEdit
			x: _modemDMRTXLevelLabel.x + _modemDMRTXLevelLabel.width
			y: _modemDMRTXLevelLabel.y
			width: 60
			height: 25
			selectByMouse: true
			inputMethodHints: "ImhPreferNumbers"
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: _modemYSFTXLevelLabel
			x: _modemDMRTXLevelEdit.x + _modemDMRTXLevelEdit.width + 10
			y: _modemDMRTXLevelLabel.y
			width: 100
			height: 25
			text: qsTr("YSFTXLevel")
			color: "white"
			verticalAlignment: Text.AlignVCenter
		}
		TextField {
			id: _modemYSFTXLevelEdit
			x: _modemYSFTXLevelLabel.x + _modemYSFTXLevelLabel.width
			y: _modemDMRTXLevelLabel.y
			width: 60
			height: 25
			selectByMouse: true
			inputMethodHints: "ImhPreferNumbers"
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: _modemP25TXLevelLabel
			x: 10
			y: 1070
			width: 100
			height: 25
			text: qsTr("P25TXLevel")
			color: "white"
			verticalAlignment: Text.AlignVCenter
		}
		TextField {
			id: _modemP25TXLevelEdit
			x: _modemP25TXLevelLabel.x + _modemP25TXLevelLabel.width
			y: _modemP25TXLevelLabel.y
			width: 60
			height: 25
			selectByMouse: true
			inputMethodHints: "ImhPreferNumbers"
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: _modemNXDNTXLevelLabel
			x: _modemP25TXLevelEdit.x + _modemP25TXLevelEdit.width + 10
			y: _modemP25TXLevelLabel.y
			width: 100
			height: 25
			text: qsTr("NXDNTXLevel")
			color: "white"
			verticalAlignment: Text.AlignVCenter
		}
		TextField {
			id: _modemNXDNTXLevelEdit
			x: _modemNXDNTXLevelLabel.x + _modemNXDNTXLevelLabel.width
			y: _modemP25TXLevelLabel.y
			width: 60
			height: 25
			selectByMouse: true
			inputMethodHints: "ImhPreferNumbers"
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
		Text {
			id: _modemBaudLabel
			x: 10
			y: 1100
			width: 100
			height: 25
			text: qsTr("Baud")
			color: "white"
			verticalAlignment: Text.AlignVCenter
		}
		TextField {
			id: _modemBaudEdit
			x: _modemBaudLabel.x + _modemBaudLabel.width
			y: _modemBaudLabel.y
			width: 60
			height: 25
			selectByMouse: true
			inputMethodHints: "ImhPreferNumbers"
			topPadding: 0
			bottomPadding: 0
			verticalAlignment: TextInput.AlignVCenter
		}
        CheckBox {
            id: _mmdvmBox
            x: 10
			y: 1130
            width: parent.width
            height: 30
            spacing: 6
            text: qsTr("MMDVM_DIRECT")
            onClicked:{
                droidstar.set_mmdvm_direct(_mmdvmBox.checked)
            }
            topPadding: 0
            bottomPadding: 0
        }
        CheckBox {
            id: _debugBox
            x: 10
			y: 1160
            width: parent.width
            height: 30
            spacing: 6
            text: qsTr("Debug output to stderr")
            onClicked:{
                droidstar.set_debug(_debugBox.checked)
            }
            topPadding: 0
        }
	}
}
