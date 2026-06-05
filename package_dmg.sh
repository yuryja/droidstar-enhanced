#!/bin/bash
set -e

APP="build/DroidStarEnhaced.app"

echo "Deploying Qt dependencies..."
macdeployqt "$APP" -qmldir=ui

echo "Replacing QtDBus symlink..."
rm -rf "$APP/Contents/Frameworks/QtDBus.framework"
cp -a /opt/homebrew/Cellar/qt/6.8.2_1/lib/QtDBus.framework "$APP/Contents/Frameworks/"

echo "Adding missing QtQuickTemplates2 framework (macdeployqt omission)..."
if [ ! -d "$APP/Contents/Frameworks/QtQuickTemplates2.framework" ]; then
    cp -a /opt/homebrew/Cellar/qt/6.8.2_1/lib/QtQuickTemplates2.framework "$APP/Contents/Frameworks/"
fi

echo "Fixing QtDBus install name..."
install_name_tool -id "@rpath/QtDBus.framework/Versions/A/QtDBus" \
  "$APP/Contents/Frameworks/QtDBus.framework/Versions/A/QtDBus"

echo "Fixing ALL bad rpaths in plugins (any depth)..."
find "$APP/Contents/PlugIns" -name "*.dylib" | while read -r lib; do
    while otool -l "$lib" 2>/dev/null | grep -q "path @loader_path/\.\./.*lib"; do
        bad_rpath=$(otool -l "$lib" 2>/dev/null | grep "path @loader_path/\.\./.*lib" | awk '{print $2}')
        for rp in $bad_rpath; do
            install_name_tool -delete_rpath "$rp" "$lib" 2>/dev/null || true
        done
    done
    while otool -l "$lib" 2>/dev/null | grep -q "path /opt/homebrew"; do
        bad_rpath=$(otool -l "$lib" 2>/dev/null | grep "path /opt/homebrew" | awk '{print $2}')
        for rp in $bad_rpath; do
            install_name_tool -delete_rpath "$rp" "$lib" 2>/dev/null || true
        done
    done
    if ! otool -l "$lib" 2>/dev/null | grep -q "@loader_path/../../Frameworks"; then
        install_name_tool -add_rpath "@loader_path/../../Frameworks" "$lib" 2>/dev/null || true
    fi
done

echo "Fixing rpaths in main binary..."
install_name_tool -delete_rpath "/opt/homebrew/lib" "$APP/Contents/MacOS/DroidStarEnhaced" 2>/dev/null || true
if ! otool -l "$APP/Contents/MacOS/DroidStarEnhaced" | grep -q "@executable_path/../Frameworks"; then
    install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP/Contents/MacOS/DroidStarEnhaced" 2>/dev/null || true
fi

echo "Fixing QtDBus permissions..."
chmod -R 755 "$APP/Contents/Frameworks/QtDBus.framework"
chown -R $USER "$APP/Contents/Frameworks/QtDBus.framework"

echo "Fixing QtQuickTemplates2 permissions..."
chmod -R 755 "$APP/Contents/Frameworks/QtQuickTemplates2.framework"
chown -R $USER "$APP/Contents/Frameworks/QtQuickTemplates2.framework"

echo "Copying README_macOS.txt into bundle..."
cp README_macOS.txt "$APP/Contents/Resources/"

echo "Signing QtDBus individually FIRST..."
codesign --sign - --force \
  "$APP/Contents/Frameworks/QtDBus.framework/Versions/A/QtDBus"

echo "Signing entire bundle..."
codesign --sign - --force --deep "$APP"

echo "Clearing Gatekeeper quarantine xattrs..."
xattr -cr "$APP"

echo "Creating DMG..."
rm -f build/DroidStarEnhaced.dmg
hdiutil create -volname "DroidStarEnhaced" \
               -srcfolder "$APP" \
               -ov -format UDZO \
               build/DroidStarEnhaced.dmg

echo "Done! DMG ready at build/DroidStarEnhaced.dmg"
