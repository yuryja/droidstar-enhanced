# NexusVoice — Multiplatform Amateur Radio Client

**NexusVoice** is a modern, cross-platform digital amateur radio client that connects to M17, YSF/FCS, DMR, P25, NXDN, D-STAR (REF/XRF/DCS), and AllStar (IAX2) reflectors and nodes over UDP. It runs natively on macOS (Apple Silicon and Intel), Windows, and Linux, with mobile support for Android and iOS.

This project is a significantly enhanced fork of the original **DroidStar** by Doug McLain ([@nostar](https://github.com/nostar)), rebuilt with a redesigned desktop interface, persistent logging, a refined LCD-style visual language, a streamlined macOS build pipeline, and support for the MD380 hardware-grade AMBE+2 vocoder.

<p align="center">
  <img src="images/screenshot.png" alt="NexusVoice Screenshot" width="700"/>
</p>

---

## Credits and License

- **Original author:** Doug McLain ([@nostar](https://github.com/nostar)) — [DroidStar](https://github.com/nostar/DroidStar)
- **DMR enhancements upstream:** [rohithzmoi/Droidstar-DMR](https://github.com/rohithzmoi/Droidstar-DMR)
- **MD380 vocoder:** Doug McLain ([@nostar](https://github.com/nostar)) — [md380_vocoder_dynarmic](https://github.com/nostar/md380_vocoder_dynarmic)
- **NexusVoice maintainer:** Yury Jajitzky ([@yuryja](https://github.com/yuryja))

This software is licensed under the **GNU General Public License v2.0 (GPLv2)**. See [LICENSE](LICENSE) for details.

---

## What is New in NexusVoice

### MD380 Hardware-Grade Vocoder
- AMBE+2 encoding and decoding using the actual **Tytera MD380 radio firmware** via the Dynarmic ARM JIT recompiler
- Same vocoder quality as a physical DMR radio — not a mathematical approximation
- Automatic fallback to software vocoder (mbelib) if the firmware is not present
- Works on x86_64 and ARM64 (Windows, macOS, Linux, Android)

### Redesigned Desktop Interface
- Premium **LCD amber screen** with a pixel-art font (ARCADE.TTF) embedded in the QRC resource system
- Smooth **horizontal slider controls** for volume and microphone gain with visual indicator bars
- LCD-style **raised shadow text** for all on-screen data (S-Meter, mode, slot, callsign)
- **Theming system** with 5 selectable color palettes: Amber, Blue, Pink, Pastel Red, Pastel Yellow
- Matching **COLOR and POWER buttons** with visual state feedback

### Logbook Panel
- Toggleable **Last Heard** panel that slides open below the main interface
- Displays the last 5 received stations: Talkgroup (TG), Callsign, Name, Country, Date, Time
- Automatic country lookup via ITU callsign prefix parser

### Persistent Station Log
- Automatic CSV database at `~/.config/yuryjajitzky/nexusvoice/station_log.csv`
- Dedicated Station Log tab with sortable history (newest first)
- One-click CSV export to Documents folder with a confirmation dialog to clear records

### Controls and UX
- **5-Slot Memory Preset System**: Save current configurations (Mode, Host, Slot, CC, TGID) into slots 1-5 by toggling `SET MEMORY` mode, and reload them with a single click
- **Custom Keyboard PTT Shortcut**: Configure any keyboard key as a PTT button in Settings
- **SWTX, SWRX, AGC** toggle buttons styled to match the active screen theme
- Physical volume buttons mapped as PTT on mobile (toggle or hold modes)

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

## Vocoder

NexusVoice supports three vocoder modes, selected automatically in order of preference:

| Mode | Quality | Requirement |
|---|---|---|
| AMBE USB dongle (ThumbDV, DVstick 30) | Best (licensed hardware) | Physical USB device |
| MD380 firmware via Dynarmic JIT | Very good (real codec) | `brew install boost` at build time |
| mbelib software vocoder | Acceptable | None (built-in fallback) |

To enable the MD380 vocoder:

```bash
brew install boost
cmake -B build -DCMAKE_PREFIX_PATH=$(brew --prefix qt)
cmake --build build
```

CMake will detect Boost automatically. If Boost is not found, the build continues with mbelib.

> **Legal note:** The MD380 firmware (D002.032.bin) is proprietary. It is downloaded automatically during the build from public sources. You are responsible for compliance with local regulations regarding its use.

---

## Requirements

| Tool | Version |
|---|---|
| Qt | 6.5 or later (6.8.x recommended) |
| CMake | 3.16 or later |
| Boost | 1.70 or later (optional, for MD380 vocoder) |
| Xcode Command Line Tools | macOS only |
| Homebrew | macOS recommended |

---

## Build Instructions

### macOS

```bash
# Install dependencies
brew install qt boost

# Clone with submodules
git clone --recurse-submodules https://github.com/yuryja/nexusvoice.git
cd nexusvoice

# Configure
cmake -B build -DCMAKE_PREFIX_PATH=$(brew --prefix qt)

# Build
cmake --build build

# Run
open build/NexusVoice.app
```

### macOS — Production DMG

```bash
cmake --build build
./package_dmg.sh
```

The script handles: `macdeployqt`, QtDBus fix, plugin pruning, rpath cleanup, code signing, xattr cleanup, and DMG creation.

### Linux

```bash
sudo apt install libqt6* qml6* qt6-*-dev libboost-filesystem-dev

git clone --recurse-submodules https://github.com/yuryja/nexusvoice.git
cd nexusvoice
cmake -B build
cmake --build build
./build/NexusVoice
```

### Windows

Install [Visual Studio 2022 Community](https://visualstudio.microsoft.com/) with the "Desktop development with C++" workload. Install [Flutter](https://flutter.dev) if building the Flutter frontend.

```powershell
cmake -B build -DCMAKE_PREFIX_PATH="C:/Qt/6.x.x/msvc20xx_64"
cmake --build build --config Release
```

### Android

Refer to [Qt for Android documentation](https://doc.qt.io/qt-6/android.html). Gradle build files are included in the `android/` directory.

---

## Installing on macOS (End Users)

1. Download `NexusVoice.dmg` from the [Releases](https://github.com/yuryja/nexusvoice/releases) page
2. Open the `.dmg` and drag **NexusVoice.app** to your **Applications** folder
3. On first launch, if macOS shows "developer cannot be verified":
   - Go to **System Settings -> Privacy and Security -> Open Anyway**
   - This is a one-time step. The app is not signed with an Apple Developer ID.

---

## Project Structure

```
nexusvoice/                     (this repo, transitional — will split into two)
  core/                         All C++ business logic: DSP, vocoders, protocols
  ui/
    shared/                     Common fonts, textures, and resources
    desktop/                    QML UI for macOS, Windows, Linux
    mobile/                     QML UI for Android and iOS
  Frameworks/
    md380_vocoder_dynarmic/     Git submodule: MD380 AMBE+2 vocoder via Dynarmic
  Info.plist                    macOS bundle metadata
  CMakeLists.txt                Cross-platform build configuration
  package_dmg.sh                macOS DMG packaging script
  GEMINI.md                     Architecture rules and project memory
  CHANGELOG.md                  Version history
```

### Planned Architecture (v2.0)

The project is being migrated to a clean two-repo architecture:

```
nexusvoice-core    Pure C++ library with stable C API, no Qt dependency
nexusvoice-app     Flutter frontend consuming nexusvoice-core via dart:ffi
```

See [GEMINI.md](GEMINI.md) for the full migration plan and architectural decisions.

---

## Contributing

Pull requests are welcome. Please follow these conventions:

- All code, comments, and commit messages must be in **English**
- No emojis in commit messages
- Each commit must be atomic (one logical change per commit)
- Follow the architecture conventions in [GEMINI.md](GEMINI.md)
- Update GEMINI.md after any significant architectural change

---

## Support this Project

NexusVoice is free, open-source software maintained in spare time. If you find it useful, donations are welcome.

**PayPal:** [paypal.me/yuryja](https://paypal.me/yuryja)

---

*NexusVoice is built on the shoulders of open-source ham radio software. Special thanks to Doug McLain and all contributors to the DroidStar ecosystem.*
