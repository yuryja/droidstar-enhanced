# DStar+ — Multiplatform Amateur Radio Client

**DStar+** is a modern, cross-platform digital amateur radio client that connects to M17, YSF/FCS, DMR, P25, NXDN, D-STAR (REF/XRF/DCS), and AllStar (IAX2) reflectors and nodes over UDP. It runs natively on macOS (Apple Silicon and Intel), Windows, and Linux, with mobile support for Android and iOS.

This project is a significantly enhanced fork of the original **DroidStar** by Doug McLain ([@nostar](https://github.com/nostar)), rebuilt with a redesigned desktop interface, persistent logging, a refined LCD-style visual language, and a streamlined macOS build pipeline.

---

## Credits & License

- **Original author:** Doug McLain ([@nostar](https://github.com/nostar)) — [DroidStar](https://github.com/nostar/DroidStar)
- **DMR enhancements upstream:** [rohithzmoi/Droidstar-DMR](https://github.com/rohithzmoi/Droidstar-DMR)
- **DStar+ fork maintainer:** Yury Jajitzky ([@yuryja](https://github.com/yuryja))

This software is licensed under the **GNU General Public License v2.0 (GPLv2)**. See [LICENSE](LICENSE) for details.

---

## What's New in DStar+

The original DroidStar is a solid engine — DStar+ builds on top of it with a focus on usability and visual clarity for desktop users:

### Redesigned Desktop Interface
- Premium **LCD amber screen** with a pixel-art font (ARCADE.TTF) embedded in the QRC resource system
- Smooth **horizontal slider controls** for volume and microphone gain with visual indicator bars
- LCD-style **raised shadow text** for all on-screen data (S-Meter, mode, slot, callsign)
- **Theming system** with 5 selectable color palettes: Amber, Blue, Pink, Pastel Red, Pastel Yellow
- Matching **COLOR and POWER buttons** with visual state feedback

### Logbook Panel
- Toggleable **Last Heard** panel that slides open below the main interface
- Displays the last 5 received stations: Callsign, Name, Country, Date, Time
- Column layout optimized for legibility — Date column centered, Time right-aligned

### Persistent Station Log
- Automatic CSV database at `~/.config/dudetronics/station_log.csv`
- Dedicated Station Log tab with sortable history (newest first)
- One-click CSV export to Documents folder, with a confirmation dialog to clear records

### Controls & UX
- **QSY button** with 3-stripe visual design and real-time talkgroup switching
- **SWTX, SWRX, AGC** toggle buttons styled to match the active screen theme
- Physical volume buttons mapped as PTT on mobile (toggle or hold modes)
- ITU callsign prefix parser for automatic country resolution

---

## Supported Protocols

| Protocol | Modes |
|---|---|
| M17 | Voice + SMS (type 0x05 packets) |
| YSF / FCS | DN and VW modes |
| DMR | BrandMeister, DMR+, TGIF and others |
| P25 | Phase 1 |
| NXDN | Voice |
| D-STAR | REF, XRF, DCS reflectors |
| AllStar | IAX2 client + Web Transceiver mode |

AMBE hardware support: ThumbDV, DVstick 30, DVSI, and any compatible USB AMBE device.
MMDVM hotspot and direct modem mode are also supported.

---

## Requirements

| Tool | Version |
|---|---|
| Qt | 6.5 or later (6.8.x recommended) |
| CMake | 3.16 or later |
| Xcode Command Line Tools | (macOS only) |
| Homebrew | (macOS recommended) |

---

## Installation

### macOS — Development Build

Install Qt via Homebrew (recommended for Apple Silicon):

```bash
brew install qt
```

Clone and configure the project:

```bash
git clone https://github.com/yuryja/droidstar-enhanced.git
cd droidstar-enhanced
cmake -B build -DCMAKE_PREFIX_PATH=$(brew --prefix qt)
```

Build and run:

```bash
cmake --build build
open build/DroidStar.app
```

The app will open directly. No extra steps needed for local development.

---

### macOS — Production DMG

The following script produces a fully self-contained, distributable `.dmg` installer.
Run it from the project root after a successful build.

```bash
# 1. Build
cmake --build build

# 2. Deploy Qt frameworks into the bundle
macdeployqt build/DroidStar.app -qmldir=ui

# 3. Copy QtDBus (macdeployqt leaves it as a symlink — this fixes it)
rm -rf build/DroidStar.app/Contents/Frameworks/QtDBus.framework
cp -RL /opt/homebrew/Cellar/qt/6.8.2_1/lib/QtDBus.framework \
       build/DroidStar.app/Contents/Frameworks/QtDBus.framework

# 4. Make QtDBus relocatable
install_name_tool -id "@rpath/QtDBus.framework/Versions/A/QtDBus" \
  build/DroidStar.app/Contents/Frameworks/QtDBus.framework/Versions/A/QtDBus

# 5. Fix plugin rpaths to point inside the bundle (not to Homebrew)
find build/DroidStar.app/Contents/PlugIns -name "*.dylib" | while read -r lib; do
    install_name_tool -delete_rpath "@loader_path/../../../../lib" "$lib" 2>/dev/null || true
    install_name_tool -add_rpath "@loader_path/../../Frameworks" "$lib" 2>/dev/null || true
done

# 6. Fix ownership and permissions on QtDBus (copied as root)
chmod -R 755 build/DroidStar.app/Contents/Frameworks/QtDBus.framework
chown -R $USER build/DroidStar.app/Contents/Frameworks/QtDBus.framework

# 7. Sign QtDBus before the full bundle (avoids "ambiguous format" error)
codesign --sign - --force \
  build/DroidStar.app/Contents/Frameworks/QtDBus.framework/Versions/A/QtDBus

# 8. Sign the full bundle
codesign --sign - --force --deep build/DroidStar.app

# 9. Strip quarantine attributes before packaging
xattr -cr build/DroidStar.app

# 10. Create the DMG
rm -f build/DroidStar.dmg
hdiutil create -volname "DStar+" \
               -srcfolder build/DroidStar.app \
               -ov -format UDZO \
               build/DroidStar.dmg
```

> **Note:** If you update Qt via Homebrew, update the path in step 3 accordingly.

---

### Linux

Install Qt6 and required packages:

```bash
# Debian / Ubuntu / Raspberry Pi OS
sudo apt install libqt6* qml6* qt6-*-dev
```

Build:

```bash
git clone https://github.com/yuryja/droidstar-enhanced.git
cd droidstar-enhanced
cmake -B build
cmake --build build
./build/DroidStar
```

---

### Windows

Install [Qt 6.x for Windows](https://www.qt.io/download-open-source) using the Qt online installer. Then:

```powershell
cmake -B build -DCMAKE_PREFIX_PATH="C:/Qt/6.x.x/msvc20xx_64"
cmake --build build --config Release
windeployqt build/Release/DroidStar.exe
```

---

### Android

A complete Android build requires the Android NDK and SDK. Gradle build files are included in the `android/` directory. Refer to the Qt documentation for [Qt for Android](https://doc.qt.io/qt-6/android.html) for setup details.

---

## Installing on macOS (End Users)

1. Download `DStar+.dmg` from the [Releases](https://github.com/yuryja/droidstar-enhanced/releases) page
2. Open the `.dmg` and drag **DStar+.app** to your **Applications** folder
3. On first launch, if macOS shows *"developer cannot be verified"*:
   - Go to **System Settings → Privacy & Security → Open Anyway**
   - This is a one-time step. The app is not signed with an Apple Developer ID.

---

## Vocoder Plugin

DStar+ supports a software vocoder plugin API compatible with the original DroidStar plugin format.

> **Important:** Only use vocoder plugins you are properly licensed to use. No vocoder plugin is included in this repository.

To install a vocoder, add a download URL to the **Vocoder URL** field in Settings and click **Download Vocoder**. The file will be placed in:

- **macOS / Linux:** `~/.config/dudetronics/`
- **Windows:** `%APPDATA%\dudetronics\`

The plugin filename format is: `vocoder_plugin.<platform>.<arch>`

Supported platforms: `linux`, `darwin`, `winnt`, `android`, `ios`  
Supported architectures: `x86_64`, `arm`, `arm64`

---

## Configuration Notes

| Setting | Description |
|---|---|
| **Callsign** | Your valid amateur radio callsign. Required for all modes. |
| **DMR ID** | Your registered DMR ID. Required for DMR connections. |
| **Talkgroup** | For DMR, enter the talkgroup number (e.g. 91 for BrandMeister Worldwide). |
| **MYCALL / URCALL / RPTR1 / RPTR2** | For D-STAR modes. Pre-populated on connect but editable. |
| **IAX Nodes** | Defined in the Hosts tab. Format: `IAX <node> <ip|wt> <port> <user> <pass>` |

---

## Project Structure

```
droidstar-enhanced/
├── core/           # All C++ business logic: DSP, vocoders, network protocols
├── ui/
│   ├── shared/     # Common fonts, textures, and resources
│   ├── desktop/    # QML UI for macOS, Windows, Linux
│   └── mobile/     # QML UI for Android and iOS
├── Info.plist      # macOS bundle metadata
├── CMakeLists.txt  # Cross-platform build configuration
└── Gemini.md       # Internal build notes and packaging roadmap
```

---

## Contributing

Pull requests are welcome. Please keep all code, comments, and commit messages in **English**. This project follows the architecture conventions described in [Gemini.md](Gemini.md).

---

*DStar+ is built on the shoulders of open-source ham radio software. Special thanks to Doug McLain and all contributors to the DroidStar ecosystem.*
