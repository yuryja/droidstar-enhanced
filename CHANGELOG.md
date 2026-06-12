# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- Migration to two-repo architecture: nexusvoice-core (C++ library) and nexusvoice-app (Flutter)
- Removal of Qt dependency from the C++ core
- Flutter frontend for all 5 platforms with shared business logic via dart:ffi

---

## [1.2.0] - 2026-06-12

### Added
- MD380 vocoder support via `md380_vocoder_dynarmic` git submodule (AMBE+2 using real Tytera MD380 firmware via Dynarmic ARM JIT recompiler)
- CMake auto-detection: MD380 vocoder is enabled automatically when Boost is installed; falls back gracefully to mbelib otherwise
- CHANGELOG.md (this file)

### Changed
- Project renamed from DroidStarEnhaced to **NexusVoice**
- CMake project name: `DroidStar` -> `NexusVoice`
- macOS bundle: `com.yuryjajitzky.DroidStarEnhaced` -> `com.yuryjajitzky.NexusVoice`
- Application settings namespace: `droidstarenhaced` -> `nexusvoice`
- Android version code bumped from 90 to 100
- README.md fully rewritten to reflect new name and architecture

### Migration Note
User settings from v1.1.x are stored under `droidstarenhaced` and will not be migrated automatically to the new `nexusvoice` namespace. Users will need to reconfigure settings on first launch.

---

## [1.1.1] - 2026-05-XX

### Fixed
- COLOR button indicator line color not matching selected theme
- C++ audio device resource locks not released on disconnect
- Memory leaks in audio engine on repeated connect/disconnect cycles
- HTTP host list downloads blocked by ATS: switched default URLs to HTTPS
- Added ATS exception in Info.plist for cleartext fallback hosts

### Changed
- Screen QSY wait overlay now displays during memory preset reconnect delay
- `CMAKE_OSX_DEPLOYMENT_TARGET` set to `11.0` to prevent crashes on macOS versions prior to Tahoe

---

## [1.1.0] - 2026-04-XX

### Added
- 5-slot Memory Preset system (save/load/clear per slot)
- SET MEM mode button replacing the old QSY button
- Custom PTT keyboard shortcut mapping (Settings tab)
- PTT typing prevention when input fields are focused

### Removed
- `memoryConfigPopup` and `emptyMemoryDialog` (replaced by native workflow)

---

## [1.0.0] - 2026-03-XX

### Added
- Initial release as DroidStarEnhaced fork of DroidStar
- Redesigned desktop interface with LCD amber screen and ARCADE.TTF font
- Theming system with 5 color palettes
- Last Heard logbook panel (last 5 stations)
- Persistent station log as CSV with export functionality
- ITU callsign prefix parser for country resolution
- HTTPS host list downloads with ATS configuration
- macOS DMG packaging script (package_dmg.sh)
