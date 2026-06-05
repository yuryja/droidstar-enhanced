#!/bin/bash
set -e

echo "Deploying Qt dependencies..."
macdeployqt "build/DStar+.app" -qmldir=ui

echo "Replacing QtDBus symlink..."
rm -rf "build/DStar+.app/Contents/Frameworks/QtDBus.framework"
cp -a /opt/homebrew/Cellar/qt/6.8.2_1/lib/QtDBus.framework "build/DStar+.app/Contents/Frameworks/"

echo "Fixing QtDBus install name..."
install_name_tool -id "@rpath/QtDBus.framework/Versions/A/QtDBus" \
  "build/DStar+.app/Contents/Frameworks/QtDBus.framework/Versions/A/QtDBus"

echo "Fixing rpaths in plugins..."
find "build/DStar+.app/Contents/PlugIns" -name "*.dylib" | while read -r lib; do
    install_name_tool -delete_rpath "@loader_path/../../../../lib" "$lib" 2>/dev/null || true
    install_name_tool -add_rpath "@loader_path/../../Frameworks"  "$lib" 2>/dev/null || true
done

echo "Fixing permissions..."
chmod -R 755 "build/DStar+.app/Contents/Frameworks/QtDBus.framework"
chown -R $USER "build/DStar+.app/Contents/Frameworks/QtDBus.framework"

echo "Signing QtDBus individually..."
codesign --sign - --force "build/DStar+.app/Contents/Frameworks/QtDBus.framework/Versions/A/QtDBus"

echo "Signing entire bundle..."
codesign --sign - --force --deep "build/DStar+.app"

echo "Clearing Gatekeeper quarantine xattrs..."
xattr -cr "build/DStar+.app"

echo "Creating DMG..."
rm -f build/DStar+.dmg
hdiutil create -volname "DStar+" \
               -srcfolder "build/DStar+.app" \
               -ov -format UDZO \
               build/DStar+.dmg

echo "Done!"
