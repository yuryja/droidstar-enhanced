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

Item {
	id: aboutTab
	Rectangle{
		id: helpText
		x: 20
		y: 20
		width: parent.width - 40
		height: parent.height - 40
		color: "#252424"
		Flickable{
			anchors.fill: parent
			contentWidth: parent.width
			contentHeight: aboutText.y + aboutText.height
			flickableDirection: Flickable.VerticalFlick
			clip: true
			Text {
				id: aboutText
				width: helpText.width
				wrapMode: Text.WordWrap
				color: "white"
				text: qsTr(	"\nDroidStarEnhaced build " + droidstar.get_software_build() +
						   "\nPlatform:\t" + droidstar.get_platform() +
						   "\nArchitecture:\t" + droidstar.get_arch() +
						   "\nBuild ABI:\t" + droidstar.get_build_abi() +
						   "\n\nEnhanced version maintained by: Yury Jajitzky" +
						   "\nSupport this project: https://paypal.me/yuryjajitzky" +
						   "\n\nBased on the original project by Doug McLain (https://github.com/nostar/DroidStar)" +
						   "\n\nThis project is an enhanced version created with the sole purpose of improving and expanding upon the incredible original work by Doug McLain AD8DP. All original credits and deep gratitude remain with him." +
						   "\n\nCopyright (C) 2019-2021 Doug McLain AD8DP\n" +
						   "Copyright (C) 2026 Yury Jajitzky\n\n" +
							"This program is free software; " +
							"you can redistribute it and/or modify it under the terms of the GNU General " +
							"Public License as published by the Free Software Foundation; either version 2 " +
							"of the License, or (at your option) any later version.\n\n" +
							"This program is distributed in the hope that it will be useful, but WITHOUT " +
							"ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS " +
							"FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.\n\n" +
							"You should have received a copy of the GNU General Public License along with this " +
							"program. If not, see <http://www.gnu.org/licenses/>")
			}
		}
	}
}
