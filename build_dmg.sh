#!/bin/bash
set -e

# 1. Compile
cmake -B build
cmake --build build

# 2. Deploy Qt dependencies
macdeployqt build/DStar+.app -qmldir=ui

# 3. Replace QtDBus symlink with the real framework
rm -rf build/DStar+.app/Contents/Frameworks/QtDBus.framework
REAL_QTDBUS="$(readlink -f /opt/homebrew/Cellar/qt/6.11.1/lib/QtDBus.framework)"
cp -R "$REAL_QTDBUS" build/DStar+.app/Contents/Frameworks/QtDBus.framework

# 4. Fix QtDBus install name so it is relocatable
install_name_tool -id "@rpath/QtDBus.framework/Versions/A/QtDBus" \
  build/DStar+.app/Contents/Frameworks/QtDBus.framework/Versions/A/QtDBus

# 5. Fix rpaths in all plugins so they do not point to /opt/homebrew
find build/DStar+.app/Contents/PlugIns -name "*.dylib" | while read -r lib; do
    install_name_tool -delete_rpath "@loader_path/../../../../lib" "$lib" 2>/dev/null || true
    install_name_tool -add_rpath "@loader_path/../../Frameworks"  "$lib" 2>/dev/null || true
done

# 6. Fix QtDBus permissions
chmod -R 755 build/DStar+.app/Contents/Frameworks/QtDBus.framework
chown -R $USER build/DStar+.app/Contents/Frameworks/QtDBus.framework

# 7. Resign everything inside Frameworks and PlugIns because install_name_tool breaks signatures
find build/DStar+.app/Contents/Frameworks -name "*.dylib" -exec codesign --sign - --force {} \;
find build/DStar+.app/Contents/PlugIns -name "*.dylib" -exec codesign --sign - --force {} \;
codesign --sign - --force build/DStar+.app/Contents/Frameworks/QtDBus.framework/Versions/A/QtDBus

# 8. Sign the entire bundle
codesign --sign - --force --deep build/DStar+.app

# 9. Clear Gatekeeper quarantine xattrs BEFORE creating the DMG
xattr -cr build/DStar+.app

# 10. Create the final DMG
rm -f build/DStar+.dmg
mkdir -p build/dmg_staging
mv build/DStar+.app "build/dmg_staging/DStar+.app"
cp README_macOS.txt build/dmg_staging/README.txt
ln -s /Applications build/dmg_staging/Applications

hdiutil create -volname "DStar+" \
               -srcfolder build/dmg_staging \
               -ov -format UDZO \
               build/DStar+.dmg
