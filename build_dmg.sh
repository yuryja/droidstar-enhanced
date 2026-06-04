#!/bin/bash
set -e

# 1. Compile
cmake -B build
cmake --build build

# 2. Deploy Qt dependencies
macdeployqt build/DroidStar.app -qmldir=ui

# 3. Replace QtDBus symlink with the real framework
rm -rf build/DroidStar.app/Contents/Frameworks/QtDBus.framework
REAL_QTDBUS="$(readlink -f /opt/homebrew/Cellar/qt/6.11.1/lib/QtDBus.framework)"
cp -R "$REAL_QTDBUS" build/DroidStar.app/Contents/Frameworks/QtDBus.framework

# 4. Fix QtDBus install name so it is relocatable
install_name_tool -id "@rpath/QtDBus.framework/Versions/A/QtDBus" \
  build/DroidStar.app/Contents/Frameworks/QtDBus.framework/Versions/A/QtDBus

# 5. Fix rpaths in all plugins so they do not point to /opt/homebrew
find build/DroidStar.app/Contents/PlugIns -name "*.dylib" | while read -r lib; do
    install_name_tool -delete_rpath "@loader_path/../../../../lib" "$lib" 2>/dev/null || true
    install_name_tool -add_rpath "@loader_path/../../Frameworks"  "$lib" 2>/dev/null || true
done

# 6. Fix QtDBus permissions
chmod -R 755 build/DroidStar.app/Contents/Frameworks/QtDBus.framework
chown -R $USER build/DroidStar.app/Contents/Frameworks/QtDBus.framework

# 7. Resign everything inside Frameworks and PlugIns because install_name_tool breaks signatures
find build/DroidStar.app/Contents/Frameworks -name "*.dylib" -exec codesign --sign - --force {} \;
find build/DroidStar.app/Contents/PlugIns -name "*.dylib" -exec codesign --sign - --force {} \;
codesign --sign - --force build/DroidStar.app/Contents/Frameworks/QtDBus.framework/Versions/A/QtDBus

# 8. Sign the entire bundle
codesign --sign - --force --deep build/DroidStar.app

# 9. Clear Gatekeeper quarantine xattrs BEFORE creating the DMG
xattr -cr build/DroidStar.app

# 10. Create the final DMG
rm -f build/DroidStar.dmg
mkdir -p build/dmg_staging
mv build/DroidStar.app build/dmg_staging/
cp README_macOS.txt build/dmg_staging/README.txt
ln -s /Applications build/dmg_staging/Applications

hdiutil create -volname "DStar+" \
               -srcfolder build/dmg_staging \
               -ov -format UDZO \
               build/DroidStar.dmg
