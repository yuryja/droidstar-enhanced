# DroidStarEnhaced - Project Rules & Memory

This file contains the architectural rules and project context to maintain a clean core abstracted from the user interface.

**MANDATORY RULE:** Every time the AI agent or developer makes a significant architectural change, adds a new dependency, or restructures the project, they **MUST** update this file to reflect those changes.

## Commit Guidelines
- Commits **must** be written in **English**.
- They must be written in a technical and professional tone, targeted at developers.
- **NO** emojis in commit messages.
- After every commit, the agent must generate a summary in Markdown `.md` format of the changes made, ready to be copied and pasted into a Pull Request (PR) description.


## Project Architecture

The project is divided into components to allow cross-compilation across different platforms with the same business logic, but with specific graphical interfaces (Mobile vs Desktop).

### 1. `core/` (The C++ Core)
- Contains **ALL** business logic, DSP, vocoders, network protocols (DMR, YSF, P25, etc.), and controllers.
- The main `DroidStar` class is located here (`droidstar.h` and `droidstar.cpp`). This is an internal class name and does NOT need to match the app display name.
- **Rule:** It must not contain QML-specific user interface code or `Qt Quick/GUI` dependencies (except what is strictly necessary for property binding via `QObject`).

### 2. `ui/` (The Presentation Layer)
- `ui/shared/`: Common components, fonts, resources, and images (`bg_texture.bmp`, fonts).
- `ui/mobile/`: QML files designed for Android/iOS (touchscreens, bottom tabs).
- `ui/desktop/`: QML files designed for macOS/Windows/Linux (wide layouts, top menus).

### Compilation (CMakeLists.txt)
- The CMake file uses the `if(ANDROID OR IOS)` condition to include mobile `.qml` files and package them as QRC resources (`qt_add_qml_module`). Otherwise, it loads the desktop version.
- The `main.cpp` file initializes the QML engine and dynamically selects the correct loading path (`MainMobile.qml` or `MainDesktop.qml`).
- On macOS, the `OUTPUT_NAME` is `DroidStarEnhaced`, producing `DroidStarEnhaced.app`.
- **Target OS Compatibility:** macOS builds explicitly set `CMAKE_OSX_DEPLOYMENT_TARGET` to `"11.0"` in `CMakeLists.txt` to ensure compatibility with older macOS versions and prevent crashes on versions prior to macOS Tahoe (macOS 26).

---
*(Last update: Released version 1.1.0, set CMAKE_OSX_DEPLOYMENT_TARGET to 11.0, resolved Homebrew dependencies in packaging, resolved C++ memory leaks and audio device locks, and fixed COLOR button, screen QSY wait feedback, and memory preset reconnect logic)*

---

## Roadmap: macOS Packaging (DMG)

This section documents the **complete and tested** process for generating a functional `.dmg` installer for macOS. Following these steps in order is critical.

### Context and Known Issues

| Issue | Cause | Solution |
|---|---|---|
| App crashes when opened from `/Applications` | `SIGKILL` due to invalid code signature | Re-sign with `codesign` after any modification to the bundle |
| Double loading of Qt (`objc: duplicate class`) | Internal plugins had rpath to `/opt/homebrew` | Fix ALL rpaths with `install_name_tool` loop (any depth) |
| `Library not loaded: @rpath/QtDBus.framework` | `macdeployqt` adds QtDBus as a **symlink**, not a copy | Remove the symlink and copy the real framework from Cellar with `cp -a` |
| `xattr -cr` fails with Permission denied | QtDBus.framework was copied with root permissions | Run `chmod -R 755 && chown -R $USER` on the framework before xattr |
| `codesign --deep` fails: "ambiguous format" | QtDBus.framework inside the bundle is not properly signed | Sign QtDBus individually first, then `--force --deep` the main bundle |
| Users need `xattr -cr` or `sudo` | Gatekeeper quarantine on files copied from DMG | Clean xattrs from the bundle **before** creating the DMG |
| Gatekeeper blocks app with "verify with developer" dialog | App name contains `+` special character | Renamed app to `DroidStarEnhaced` (no special characters) |
| App crashes on clean systems without Homebrew | Absolute paths to `/opt/homebrew` inside frameworks (e.g. QtDBus -> libdbus, QtPdf -> libpng) | Scan `/opt/homebrew` dependencies and bundle/re-link them recursively in `package_dmg.sh` |

### Recommended: Use the packaging script

```bash
# 1. Compile
cmake --build build

# 2. Run the all-in-one packaging script
./package_dmg.sh
```

The script (`package_dmg.sh`) handles all steps: macdeployqt, QtDBus fix, rpath cleanup, README copy, signing, xattr cleanup, and DMG creation.

### Complete Manual Build + Packaging Command

Run from the root of the project. Requires the build to already be configured with CMake.

```bash
# 1. Compile
cmake --build build

# 2. Deploy Qt dependencies
macdeployqt build/DroidStarEnhaced.app -qmldir=ui

# 3. Replace QtDBus symlink with the real framework
rm -rf build/DroidStarEnhaced.app/Contents/Frameworks/QtDBus.framework
cp -a /opt/homebrew/Cellar/qt/6.8.2_1/lib/QtDBus.framework \
       build/DroidStarEnhaced.app/Contents/Frameworks/

# 4. Fix QtDBus install name so it is relocatable
install_name_tool -id "@rpath/QtDBus.framework/Versions/A/QtDBus" \
  build/DroidStarEnhaced.app/Contents/Frameworks/QtDBus.framework/Versions/A/QtDBus

# 5. Fix rpaths in all plugins (loop to handle all depths)
find build/DroidStarEnhaced.app/Contents/PlugIns -name "*.dylib" | while read -r lib; do
    while otool -l "$lib" 2>/dev/null | grep -q "path @loader_path/\.\./.*lib"; do
        bad=$(otool -l "$lib" 2>/dev/null | grep "path @loader_path/\.\./.*lib" | awk '{print $2}')
        for rp in $bad; do install_name_tool -delete_rpath "$rp" "$lib" 2>/dev/null || true; done
    done
    if ! otool -l "$lib" 2>/dev/null | grep -q "@loader_path/../../Frameworks"; then
        install_name_tool -add_rpath "@loader_path/../../Frameworks" "$lib" 2>/dev/null || true
    fi
done

# 6. Fix main binary rpath
install_name_tool -delete_rpath "/opt/homebrew/lib" \
  build/DroidStarEnhaced.app/Contents/MacOS/DroidStarEnhaced 2>/dev/null || true

# 7. Fix QtDBus permissions
chmod -R 755 build/DroidStarEnhaced.app/Contents/Frameworks/QtDBus.framework
chown -R $USER build/DroidStarEnhaced.app/Contents/Frameworks/QtDBus.framework

# 8. Copy README into bundle
cp README_macOS.txt build/DroidStarEnhaced.app/Contents/Resources/

# 9. Sign QtDBus individually FIRST (avoids "ambiguous format" error)
codesign --sign - --force \
  build/DroidStarEnhaced.app/Contents/Frameworks/QtDBus.framework/Versions/A/QtDBus

# 10. Sign the entire bundle
codesign --sign - --force --deep build/DroidStarEnhaced.app

# 11. Clear Gatekeeper quarantine xattrs BEFORE creating the DMG
xattr -cr build/DroidStarEnhaced.app

# 12. Create the final DMG
rm -f build/DroidStarEnhaced.dmg
hdiutil create -volname "DroidStarEnhaced" \
               -srcfolder build/DroidStarEnhaced.app \
               -ov -format UDZO \
               build/DroidStarEnhaced.dmg
```

### Installation for the End User

1. Open `DroidStarEnhaced.dmg`
2. Drag `DroidStarEnhaced.app` to `/Applications`
3. Upon first launch, if macOS shows *"unverified developer"*:
   - Go to **System Settings → Privacy & Security → Open Anyway**
   - This step is necessary only the first time (without an Apple Developer ID)

### To Completely Remove the Gatekeeper Dialog

Requires an **Apple Developer ID** ($99/year) and the **notarization** process:
```bash
# With Developer ID registered:
codesign --sign "Developer ID Application: Yury Jajitzky (TEAMID)" \
         --options runtime --deep --force build/DroidStarEnhaced.app
xcrun notarytool submit build/DroidStarEnhaced.dmg --apple-id your@email.com \
         --password APP_SPECIFIC_PASSWORD --team-id TEAMID --wait
xcrun stapler staple build/DroidStarEnhaced.dmg
```

### Installed Qt Version
- **Qt 6.8.2** via Homebrew: `/opt/homebrew/Cellar/qt/6.8.2_1/`
- If Qt is updated, update the path in step 3.

### Bundle ID
- `com.yuryjajitzky.DroidStarEnhaced` — defined in `Info.plist`

---
*(Last update: Released version 1.1.0, fixed COLOR button indicator line color, resolved C++ audio leaks and resource locks, and added screen QSY wait overlay)*

## Memory Presets Feature

A 5-slot Memory Preset system is built into both the desktop and mobile interfaces:
- **Backend API:**
  - `void save_memory(int index, const QString &mode, const QString &host, int slot, int cc, const QString &tgid)`
  - `QVariantMap get_memory(int index)`
  - Persisted under settings group `Memory_X` (using `QSettings`).
- **Frontend Behavior:**
  - Standardized memory slot buttons (1 to 5) are placed below the QSY line.
  - Replaced the old QSY button with a **SET MEM** mode button.
  - **Saving Memory:** Pressing `SET MEM` highlights its border and the borders of the memory buttons. Clicking any memory slot in this mode instantly saves the current UI config to that slot and exits the mode.
  - **Clearing Memory:** Long-pressing a memory slot clears its saved configuration.
  - **Loading Memory:** Clicking an active preset triggers a 5-second connection disconnect, displays QSY indicator text, applies the stored preset variables, and reconnects automatically.
  - The previous `memoryConfigPopup` and `emptyMemoryDialog` have been entirely removed in favor of this native workflow.

## Custom PTT Key Setting

A custom keyboard shortcut mapping for Push-To-Talk (PTT) is integrated:
- **Backend API:**
  - `int get_ptt_key()`
  - `void set_ptt_key(int key)`
  - `QString get_key_name(int key)`
  - Persisted under the setting key `"PTT_KEY"` (using `QSettings`).
- **Frontend Behavior:**
  - Placed at the bottom of the Settings tab.
  - Clicking **SET** initiates keyboard capturing (via focus grabber `keyGrabber`). Pressing any key grabs the key code.
  - Clicking **OK** saves the key, and clicking **Clear** removes the mapping.
  - The custom key functions identically to the volume keys in the main view for starting and stopping transmission.
  - **Typing Prevention:** The PTT logic checks `activeFocusItem` in QML to suppress transmission triggers when focusing input fields (`TextField`, `TextInput`, `TextArea`).


