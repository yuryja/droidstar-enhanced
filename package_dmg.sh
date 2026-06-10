#!/bin/bash
set -e

APP="build/DroidStarEnhaced.app"
HOMEBREW_LIB="/opt/homebrew/lib"
HOMEBREW_QT="/opt/homebrew/Cellar/qt/6.8.2_1/lib"
FRAMEWORKS="$APP/Contents/Frameworks"

# ─── Helper: fix permissions on a framework/dylib copied from Homebrew ────────
fix_perms() {
    chmod -R 755 "$1" && chown -R $USER "$1"
}

# ─── 1. Deploy Qt dependencies ───────────────────────────────────────────────
echo "[1/9] Deploying Qt dependencies..."
macdeployqt "$APP" -qmldir=ui

echo "[1b/9] Pruning unused Qt plugins (prevents missing framework errors)..."
QUICK_PLUGINS="$APP/Contents/PlugIns/quick"
QML_RESOURCES="$APP/Contents/Resources/qml"
# Keep only the plugins actually used by the app
KEEP="libqtqmlcoreplugin|libqtquick2plugin|libqtquickcontrols2plugin|libqtquickcontrols2implplugin|libqtquicktemplates2plugin|libqtquickcontrols2nativestyleplugin|libqtquickcontrols2macosstyleplugin|libqtquickcontrols2macosstyleimplplugin|libqquicklayoutsplugin|libqmlshapesplugin|libqmlplugin|libmodelsplugin|libworkerscriptplugin|libquickwindowplugin|libqtquickdialogsplugin|libqtquickdialogs2quickimplplugin|libqtquickcontrols2materialstyleplugin|libqtquickcontrols2materialstyleimplplugin|libqtquickcontrols2basicstyleplugin|libqtquickcontrols2basicstyleimplplugin"
# Prune from PlugIns/quick
find "$QUICK_PLUGINS" -name "*.dylib" | while read f; do
    base=$(basename "$f")
    if ! echo "$base" | grep -qE "$KEEP"; then
        rm -f "$f"
    fi
done
# Also remove entire QML resource directories for unused modules
for dir in VirtualKeyboard LocalStorage Scene3D Effects Timeline PDF "Controls/Universal" "Controls/iOS" "Controls/Imagine" "Controls/Fusion" "Controls/FluentWinUI3"; do
    rm -rf "$QML_RESOURCES/QtQuick/$dir" 2>/dev/null || true
done

# ─── 2. Replace QtDBus symlink with the real framework ───────────────────────
echo "[2/9] Replacing QtDBus symlink..."
rm -rf "$FRAMEWORKS/QtDBus.framework"
cp -a "$HOMEBREW_QT/QtDBus.framework" "$FRAMEWORKS/"
fix_perms "$FRAMEWORKS/QtDBus.framework"
install_name_tool -id "@rpath/QtDBus.framework/Versions/A/QtDBus" \
  "$FRAMEWORKS/QtDBus.framework/Versions/A/QtDBus"

# ─── 3. Add missing Qt frameworks that macdeployqt omits ─────────────────────
echo "[3/9] Adding Qt frameworks missing from macdeployqt..."
for fw in QtQuickTemplates2; do
    if [ ! -d "$FRAMEWORKS/${fw}.framework" ]; then
        echo "  -> Copying missing framework: ${fw}"
        cp -a "$HOMEBREW_QT/${fw}.framework" "$FRAMEWORKS/"
        fix_perms "$FRAMEWORKS/${fw}.framework"
    fi
done

# ─── 4. Auto-detect and copy missing transitive dependencies ───────────────────
echo "[4/9] Scanning and copying missing transitive dependencies..."
# Run multiple passes until no new deps are added (handles chains of deps)
CHANGED=1
while [ "$CHANGED" = "1" ]; do
    CHANGED=0
    find "$APP/Contents/MacOS" "$FRAMEWORKS" "$APP/Contents/PlugIns" "$APP/Contents/Resources" \
        -type f 2>/dev/null | while read lib; do
        if [[ "$lib" == */Headers/* ]]; then continue; fi
        if ! file "$lib" | grep -qE "Mach-O|dynamically linked shared library"; then continue; fi

        # Change own ID if it is absolute in /opt/homebrew
        own_id=$(otool -D "$lib" 2>/dev/null | tail -n 1)
        if [[ "$own_id" == /opt/homebrew* ]]; then
            if [[ "$lib" == *.framework/* ]]; then
                fw_path=$(echo "$lib" | sed -E 's|.*/(Qt[^/]+\.framework/.*)|\1|')
                new_id="@rpath/$fw_path"
            else
                new_id="@rpath/$(basename "$lib")"
            fi
            echo "  -> Changing own ID of $(basename "$lib") to $new_id"
            install_name_tool -id "$new_id" "$lib" 2>/dev/null || true
            echo "1" > build/.changed
        fi

        # Scan for dependencies
        otool -L "$lib" 2>/dev/null | tail -n +2 | awk '{print $1}' | while read dep; do
            if [[ "$dep" == /usr/lib/* || "$dep" == /System/* ]]; then continue; fi
            if [[ "$dep" == @executable_path* || "$dep" == @loader_path* ]]; then continue; fi

            if [[ "$dep" == /opt/homebrew* || "$dep" == @rpath* ]]; then
                depname=$(basename "$dep")
                
                if [[ "$dep" == *.framework/* ]]; then
                    fw_name=$(echo "$dep" | sed -E 's|.*/(Qt[^/]+\.framework).*|\1|' | cut -d. -f1)
                    if [ ! -d "$FRAMEWORKS/${fw_name}.framework" ]; then
                        if [ -d "$HOMEBREW_QT/${fw_name}.framework" ]; then
                            echo "  -> Copying missing framework: $fw_name"
                            cp -a "$HOMEBREW_QT/${fw_name}.framework" "$FRAMEWORKS/"
                            fix_perms "$FRAMEWORKS/${fw_name}.framework"
                            echo "1" > build/.changed
                        fi
                    fi
                    fw_rel_path=$(echo "$dep" | sed -E 's|.*/(Qt[^/]+\.framework/.*)|\1|')
                    new_dep_path="@rpath/$fw_rel_path"
                else
                    destpath="$FRAMEWORKS/$depname"
                    srcpath=""
                    if [[ "$dep" == /opt/homebrew* ]]; then
                        srcpath="$dep"
                    fi
                    if [ ! -f "$srcpath" ] && [ -f "$HOMEBREW_LIB/$depname" ]; then
                        srcpath="$HOMEBREW_LIB/$depname"
                    fi

                    if [ -f "$srcpath" ] && [ ! -f "$destpath" ]; then
                        echo "  -> Copying missing dylib: $depname"
                        cp "$srcpath" "$destpath"
                        fix_perms "$destpath"
                        echo "1" > build/.changed
                    fi
                    new_dep_path="@rpath/$depname"
                fi

                if [ "$dep" != "$new_dep_path" ]; then
                    echo "  -> Updating dependency in $(basename "$lib"): $dep -> $new_dep_path"
                    install_name_tool -change "$dep" "$new_dep_path" "$lib" 2>/dev/null || true
                    echo "1" > build/.changed
                fi
            fi
        done
    done
    if [ -f build/.changed ]; then
        CHANGED=1
        rm build/.changed
    fi
done

# ─── 5. Fix bad rpaths in plugins ────────────────────────────────────────────
echo "[5/9] Fixing bad rpaths in plugins and resources..."
find "$APP/Contents/PlugIns" "$APP/Contents/Resources" \( -name "*.dylib" -o -type f -path "*.framework/Versions/A/*" \) 2>/dev/null | while read -r lib; do
    if [[ "$lib" == */Headers/* ]]; then continue; fi
    while otool -l "$lib" 2>/dev/null | grep -q "path @loader_path/\.\./.*lib"; do
        bad_rpath=$(otool -l "$lib" 2>/dev/null | grep "path @loader_path/\.\./.*lib" | awk '{print $2}')
        for rp in $bad_rpath; do install_name_tool -delete_rpath "$rp" "$lib" 2>/dev/null || true; done
    done
    while otool -l "$lib" 2>/dev/null | grep -q "path /opt/homebrew"; do
        bad_rpath=$(otool -l "$lib" 2>/dev/null | grep "path /opt/homebrew" | awk '{print $2}')
        for rp in $bad_rpath; do install_name_tool -delete_rpath "$rp" "$lib" 2>/dev/null || true; done
    done
    if ! otool -l "$lib" 2>/dev/null | grep -q "@loader_path/../../Frameworks"; then
        install_name_tool -add_rpath "@loader_path/../../Frameworks" "$lib" 2>/dev/null || true
    fi
done

# ─── 6. Fix main binary rpath ─────────────────────────────────────────────────
echo "[6/9] Fixing main binary rpath..."
install_name_tool -delete_rpath "/opt/homebrew/lib" "$APP/Contents/MacOS/DroidStarEnhaced" 2>/dev/null || true
if ! otool -l "$APP/Contents/MacOS/DroidStarEnhaced" | grep -q "@executable_path/../Frameworks"; then
    install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP/Contents/MacOS/DroidStarEnhaced" 2>/dev/null || true
fi

# ─── 7. PREFLIGHT CHECK: verify all @rpath deps resolve inside the bundle ─────
echo "[7/9] Running preflight dependency check..."
rm -f build/.missing
find "$FRAMEWORKS" "$APP/Contents/PlugIns" "$APP/Contents/Resources" "$APP/Contents/MacOS" \
    \( -name "*.dylib" -o -name "DroidStarEnhaced" -o -type f -path "*.framework/Versions/A/*" \) 2>/dev/null | while read bin; do
    if [[ "$bin" == */Headers/* ]]; then continue; fi
    otool -L "$bin" 2>/dev/null | awk '/@rpath/{print $1}' | sed 's|@rpath/||' | while read dep; do
        depbase=$(basename "$dep")
        if [[ "$dep" == *.framework/* ]]; then
            fw=$(echo "$dep" | cut -d/ -f1)
            if [ ! -d "$FRAMEWORKS/$fw" ]; then
                echo "  !! MISSING FRAMEWORK: $fw (required by $(basename $bin))"
                echo "1" > build/.missing
            fi
        elif [ ! -f "$FRAMEWORKS/$depbase" ]; then
            echo "  !! MISSING DYLIB: $depbase (required by $(basename $bin))"
            echo "1" > build/.missing
        fi
    done
done
if [ -f build/.missing ]; then
    echo ""
    echo "ERROR: Preflight check failed. Fix missing dependencies before packaging."
    exit 1
fi
echo "  -> All dependencies resolved. Bundle is complete."

# ─── 11. Clear Gatekeeper quarantine xattrs BEFORE creating the DMG ───────────
echo "[8/9] Copying README, signing and clearing quarantine..."
cp README_macOS.txt "$APP/Contents/Resources/" 2>/dev/null || true
codesign --sign - --force "$APP/Contents/Frameworks/QtDBus.framework/Versions/A/QtDBus" 2>/dev/null || true
codesign --sign - --force --deep "$APP"
xattr -cr "$APP" 2>/dev/null || true

# ─── 12. Create the final DMG ────────────────────────────────────────────────
echo "[9/9] Creating final DMG..."
rm -f "build/DroidStarEnhaced.dmg"
hdiutil create -volname "DroidStarEnhaced" \
               -srcfolder "$APP" \
               -ov -format UDZO \
               "build/DroidStarEnhaced.dmg"

echo ""
echo "Done! DMG ready at build/DroidStarEnhaced.dmg"
