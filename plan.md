# Plan: DroidStar for macOS M1 (Apple Silicon)

## 1. Environment Setup

### 1.1 Prerequisites
- [ ] macOS 11.0+ (Monterey or later recommended)
- [ ] Xcode Command Line Tools installed
- [ ] Homebrew installed

### 1.2 Install Xcode CLI Tools
```bash
xcode-select --install
```
Verify:
```bash
xcode-select -p
# Should return: /Applications/Xcode.app/Contents/Developer
```

### 1.3 Install Qt 6.x for Apple Silicon
```bash
# Via Homebrew (easiest for M1)
brew install qt@6

# Or download the official installer from: https://www.qt.io/download
# Make sure to select components for macOS + Apple Silicon
```

Verify Qt:
```bash
qmake --version
# Should show Qt version 6.x
```

### 1.4 Additional Installations (Homebrew)
```bash
brew install cmake
brew install pkg-config
brew install codec2
```

---

## 2. Obtaining the Source Code

### 2.1 Clone the Main Repository
```bash
cd ~/Projects  # or your working directory
git clone https://github.com/nostar/DroidStar.git
cd DroidStar
```

**Alternative:** If you prefer the fork with DMR improvements:
```bash
git clone https://github.com/rohithzmoi/Droidstar-DMR.git
cd Droidstar-DMR
```

### 2.2 Inspect the Structure
```bash
ls -la
cat README.md  # Read repo-specific instructions
```

---

## 3. Configuration for Apple Silicon

### 3.1 Verify Compatibility
- The code is written in pure C++, native for M1.
- Qt 6.6+ has full support for Apple Silicon.
- There shouldn't be any architecture issues.

### 3.2 Environment Variables (if needed)
```bash
export PATH="/usr/local/opt/qt@6/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/qt@6/lib"
export CPPFLAGS="-I/usr/local/opt/qt@6/include"
```

---

## 4. Compilation

### 4.1 Clean Previous Build (if exists)
```bash
make clean
rm -rf build/
rm Makefile
```

### 4.2 Generate the Makefile
```bash
qmake DroidStar.pro
# or if using CMake:
cmake . -DCMAKE_BUILD_TYPE=Release
```

### 4.3 Compile
```bash
make -j$(sysctl -n hw.ncpu)
# This uses all available cores (M1 = 8 cores)
```

**Estimated time:** 5-15 minutes depending on config.

### 4.4 Verify Compilation
```bash
ls -la DroidStar.app
# A .app folder should exist if everything went well
```

---

## 5. Creating the Application Bundle (.app)

### 5.1 Prepare the Bundle for macOS
```bash
macdeployqt DroidStar.app -dmg
# This creates DroidStar.dmg ready for distribution
```

### 5.2 Native macOS Integration (Optional)
Add to `droidstar.pro` or create a custom `.plist` file:
```bash
# Edit Info.plist in DroidStar.app/Contents/
plutil -convert xml1 DroidStar.app/Contents/Info.plist
# Then open and customize with Xcode or a text editor
```

---

## 6. Enhancements for macOS M1

### 6.1 Compilation Optimizations
Modify `DroidStar.pro` for M1:
```qmake
# Add before SOURCES:
QMAKE_CXXFLAGS += -mcpu=apple-m1
QMAKE_CFLAGS += -mcpu=apple-m1
CONFIG += optimize_full
```

### 6.2 Native macOS Integration
- **Notifications:** Integrate `NSUserNotification` for RX/TX audio.
- **Dock Menu:** Add quick-access for mode switching.
- **Dark Mode:** Automatically supported with Qt 6.
- **Keyboard:** Native shortcuts (Cmd+Q, Cmd+W, etc.).

**File to create:** `macos_integration.mm` (Objective-C++)
```objcpp
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// Native notifications
void sendMacOSNotification(QString title, QString message) {
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = [NSString stringWithUTF8String:title.toUtf8().data()];
    notification.informativeText = [NSString stringWithUTF8String:message.toUtf8().data()];
    [center deliverNotification:notification];
}
```

### 6.3 UI Enhancements for macOS
- Review color palette (Light/Dark mode).
- Adjust font sizes for Retina displays.
- Implement trackpad gestures (zoom, swipe).

### 6.4 M1 Performance
- The M1 handles natively compiled C++ very well.
- Verify CPU usage with Activity Monitor:
  ```bash
  open /Applications/Utilities/Activity\ Monitor.app
  ```

---

## 7. Testing and Debugging

### 7.1 Run the Application
```bash
./DroidStar.app/Contents/MacOS/DroidStar
```

### 7.2 Debug in Xcode (Optional)
```bash
# Open the project in Xcode
open DroidStar.pro
```

### 7.3 Logs
Look for logs in:
```bash
~/Library/Application\ Support/DroidStar/
tail -f ~/Library/Application\ Support/DroidStar/droidstar.log
```

### 7.4 Common Troubleshooting

| Issue | Solution |
|----------|----------|
| `qmake: command not found` | Verify: `export PATH="/usr/local/opt/qt@6/bin:$PATH"` |
| `codec2 not found` | Install: `brew install codec2` |
| Slow compilation | Verify RAM/CPU with Activity Monitor |
| `.app` doesn't run | Check: `codesign -v DroidStar.app` |

---

## 8. Planned Enhancements (Post-Compilation)

### 8.1 macOS UI/UX
- [ ] Custom sidebar (native style)
- [ ] Buttons with SF Symbols (Apple Design System)
- [ ] Context menu (right-click)
- [ ] Fullscreen support

### 8.2 Native Features
- [ ] System Notifications (enhanced QSystemTrayIcon)
- [ ] Spotlight indexing (for logs/QSO)
- [ ] AirDrop support (if applicable)
- [ ] Handoff between devices (if applicable)

### 8.3 Performance
- [ ] Profile with Xcode Instruments
- [ ] Optimize audio threads (CoreAudio)
- [ ] Reduce RX/TX latency

### 8.4 Packaging
- [ ] Create a distributable `.dmg`
- [ ] Sign with Developer Certificate (optional)
- [ ] Notarize the app (if planning to distribute)

---

## 9. Distribution (Future)

### 9.1 Option 1: Manual Distribution
```bash
codesign -s - DroidStar.app  # Self-sign (for development)
macdeployqt DroidStar.app -dmg
# Share DroidStar.dmg
```

### 9.2 Option 2: App Store (Requires Apple Dev Account)
- Changes in `Info.plist`
- Official signed code
- Mandatory notarization

### 9.3 Option 3: Homebrew Cask
- Once stable, package as a homebrew tap

---

## 10. Quick Commands

```bash
# Initial Setup
brew install qt@6 cmake codec2
export PATH="/usr/local/opt/qt@6/bin:$PATH"

# Compilation
cd ~/Projects/DroidStar
qmake DroidStar.pro
make -j8

# Run
./DroidStar.app/Contents/MacOS/DroidStar

# Create DMG for distribution
macdeployqt DroidStar.app -dmg

# Clean for rebuild
make clean && rm Makefile && rm -rf DroidStar.app
```

---

## 11. Next Phases (Based on Progress)

1. **Successful compilation** → M1 Testing
2. **Testing OK** → Implement macOS enhancements
3. **Enhancements implemented** → Performance optimization
4. **Stable** → Distribution/packaging

---

## Notes

- **Qt Version:** Use Qt 6.6+ for best M1 support.
- **Codec2:** Critical for DMR audio.
- **Time Investment:** 1-3 hours for compilation + initial enhancements.
- **Support:** Check GitHub issues if there are specific problems.

---

## Resources

- [Qt macOS Deployment](https://doc.qt.io/qt-6/macos-deployment.html)
- [Original DroidStar Repo](https://github.com/nostar/DroidStar)
- [Apple Silicon Support](https://developer.apple.com/support/apple-silicon/)
- [Codec2 Documentation](https://www.rowetel.com/wordpress/?page_id=452)

---

**Status:** Initial Plan  
**Last Update:** 2026-05-30  
**Architecture:** Apple Silicon (M1/M2/M3)
