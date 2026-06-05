# DStar+ Enhanced - Project Rules & Memory

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
- The main `DroidStar` class is located here (`droidstar.h` and `droidstar.cpp`).
- **Rule:** It must not contain QML-specific user interface code or `Qt Quick/GUI` dependencies (except what is strictly necessary for property binding via `QObject`).

### 2. `ui/` (The Presentation Layer)
- `ui/shared/`: Common components, fonts, resources, and images (`bg_texture.bmp`, fonts).
- `ui/mobile/`: QML files designed for Android/iOS (touchscreens, bottom tabs).
- `ui/desktop/`: QML files designed for macOS/Windows/Linux (wide layouts, top menus).

### Compilation (CMakeLists.txt)
- The CMake file uses the `if(ANDROID OR IOS)` condition to include mobile `.qml` files and package them as QRC resources (`qt_add_qml_module`). Otherwise, it loads the desktop version.
- The `main.cpp` file initializes the QML engine and dynamically selects the correct loading path (`MainMobile.qml` or `MainDesktop.qml`).

---
*(Last update: Initial Core vs UI restructuring)*

---

## Roadmap: macOS Packaging (DMG)

This section documents the **complete and tested** process for generating a functional `.dmg` installer for macOS. Following these steps in order is critical.

### Context and Known Issues

| Issue | Cause | Solution |
|---|---|---|
| App crashes when opened from `/Applications` | `SIGKILL` due to invalid code signature | Re-sign with `codesign` after any modification to the bundle |
| Double loading of Qt (`objc: duplicate class`) | Internal plugins had rpath to `/opt/homebrew` | Fix rpaths with `install_name_tool` in all `.dylib` in `PlugIns/` |
| `Library not loaded: @rpath/QtDBus.framework` | `macdeployqt` adds QtDBus as a **symlink**, not a copy | Remove the symlink and copy the real framework from Cellar with `cp -RL` |
| `xattr -cr` fails with Permission denied | QtDBus.framework was copied with root permissions | Run `chmod -R 755 && chown -R $USER` on the framework before xattr |
| `codesign --deep` fails: "ambiguous format" | QtDBus.framework inside the bundle is not properly signed | Sign QtDBus individually first, then `--force --deep` the main bundle |
| Users need `xattr -cr` or `sudo` | Gatekeeper quarantine on files copied from DMG | Clean xattrs from the bundle **before** creating the DMG |

### Complete Build + Packaging Command

Run from the root of the project. Requires the build to already be configured with CMake.

```bash
# 1. Compile
cmake --build build

# 2. Deploy Qt dependencies
macdeployqt build/DStar+.app -qmldir=ui

# 3. Replace QtDBus symlink with the real framework
rm -rf build/DStar+.app/Contents/Frameworks/QtDBus.framework
cp -a /opt/homebrew/Cellar/qt/6.8.2_1/lib/QtDBus.framework \
       build/DStar+.app/Contents/Frameworks/

# 4. Fix QtDBus install name so it is relocatable
install_name_tool -id "@rpath/QtDBus.framework/Versions/A/QtDBus" \
  build/DStar+.app/Contents/Frameworks/QtDBus.framework/Versions/A/QtDBus

# 5. Fix rpaths in all plugins so they do not point to /opt/homebrew
find build/DStar+.app/Contents/PlugIns -name "*.dylib" | while read -r lib; do
    install_name_tool -delete_rpath "@loader_path/../../../../lib" "$lib" 2>/dev/null || true
    install_name_tool -add_rpath "@loader_path/../../Frameworks"  "$lib" 2>/dev/null || true
done

# 6. Fix QtDBus permissions (it was copied as root)
chmod -R 755 build/DStar+.app/Contents/Frameworks/QtDBus.framework
chown -R $USER build/DStar+.app/Contents/Frameworks/QtDBus.framework

# 7. Sign QtDBus individually FIRST (avoids "ambiguous format" error)
codesign --sign - --force \
  build/DStar+.app/Contents/Frameworks/QtDBus.framework/Versions/A/QtDBus

# 8. Sign the entire bundle
codesign --sign - --force --deep build/DStar+.app

# 9. Clear Gatekeeper quarantine xattrs BEFORE creating the DMG
xattr -cr build/DStar+.app

# 10. Create the final DMG
rm -f build/DStar+.dmg
hdiutil create -volname "DStar+" \
               -srcfolder build/DStar+.app \
               -ov -format UDZO \
               build/DStar+.dmg
```

### Installation for the End User

1. Open `DroidStar.dmg`
2. Drag `DStar+.app` to `/Applications`
3. Upon first launch, if macOS shows *"unverified developer"*:
   - Go to **System Settings → Privacy & Security → Open Anyway**
   - This step is necessary only the first time (without an Apple Developer ID)

### To Completely Remove the Gatekeeper Dialog

Requires an **Apple Developer ID** ($99/year) and the **notarization** process:
```bash
# With Developer ID registered:
codesign --sign "Developer ID Application: Yury Jajitzky (TEAMID)" \
         --options runtime --deep --force build/DStar+.app
xcrun notarytool submit build/DStar+.dmg --apple-id your@email.com \
         --password APP_SPECIFIC_PASSWORD --team-id TEAMID --wait
xcrun stapler staple build/DStar+.dmg
```

### Installed Qt Version
- **Qt 6.8.2** via Homebrew: `/opt/homebrew/Cellar/qt/6.8.2_1/`
- If Qt is updated, update the path in step 3.

### Bundle ID
- `com.yuryjajitzky.DStarPlus` — defined in `Info.plist`

---
*(Last update: Complete macOS DMG packaging process documented and validated)*
