# DroidStar Enhanced - Reglas y Memoria del Proyecto

Este archivo contiene las reglas arquitectónicas y el contexto del proyecto para mantener un núcleo (core) limpio y abstraído de la interfaz de usuario.

**REGLA OBLIGATORIA:** Cada vez que el agente IA o el desarrollador realice un cambio arquitectónico importante, agregue una nueva dependencia o reestructure el proyecto, **DEBE** actualizar este archivo para reflejar dichos cambios.

## Arquitectura del Proyecto

El proyecto está dividido en componentes para permitir la compilación cruzada en diferentes plataformas con la misma lógica de negocio, pero con interfaces gráficas específicas (Móvil vs Escritorio).

### 1. `core/` (El Núcleo C++)
- Contiene **TODA** la lógica de negocio, DSP, vocoders, protocolos de red (DMR, YSF, P25, etc.) y controladores.
- La clase principal `DroidStar` se ubica aquí (`droidstar.h` y `droidstar.cpp`).
- **Regla:** No debe contener código específico de interfaz de usuario QML ni dependencias de `Qt Quick/GUI` (salvo lo estrictamente necesario para enlazar propiedades a través de `QObject`).

### 2. `ui/` (La Capa de Presentación)
- `ui/shared/`: Componentes comunes, fuentes, recursos e imágenes (`bg_texture.bmp`, fuentes).
- `ui/mobile/`: Archivos QML diseñados para Android/iOS (pantallas táctiles, tabs inferiores).
- `ui/desktop/`: Archivos QML diseñados para macOS/Windows/Linux (layouts amplios, menús superiores).

### Compilación (CMakeLists.txt)
- El archivo CMake utiliza la condición `if(ANDROID OR IOS)` para incluir los archivos `.qml` móviles y empaquetarlos como recursos QRC (`qt_add_qml_module`). De lo contrario, carga la versión de escritorio.
- El archivo `main.cpp` inicializa el motor QML y selecciona dinámicamente la ruta de carga correcta (`MainMobile.qml` o `MainDesktop.qml`).

---
*(Última actualización: Reestructuración inicial del Core vs UI)*

---

## Hoja de Ruta: Empaquetado para macOS (DMG)

Esta sección documenta el proceso **completo y probado** para generar un instalador `.dmg` funcional para macOS. Seguir estos pasos en orden es crítico.

### Contexto y Problemas Conocidos

| Problema | Causa | Solución |
|---|---|---|
| App se cierra al abrir desde `/Applications` | `SIGKILL` por firma de código inválida | Re-firmar con `codesign` después de cualquier modificación al bundle |
| Doble carga de Qt (`objc: duplicate class`) | Plugins internos tenían rpath a `/opt/homebrew` | Corregir rpaths con `install_name_tool` en todos los `.dylib` de `PlugIns/` |
| `Library not loaded: @rpath/QtDBus.framework` | `macdeployqt` pone QtDBus como **symlink**, no lo copia | Eliminar el symlink y copiar el framework real desde Cellar con `cp -RL` |
| `xattr -cr` falla con Permission denied | QtDBus.framework se copió con permisos de root | Ejecutar `chmod -R 755 && chown -R $USER` sobre el framework antes del xattr |
| `codesign --deep` falla: "ambiguous format" | QtDBus.framework dentro del bundle no está bien firmado | Firmar QtDBus individualmente primero, luego `--force --deep` el bundle principal |
| Usuarios necesitan `xattr -cr` o `sudo` | Cuarentena de Gatekeeper en archivo copiado de DMG | Limpiar xattrs del bundle **antes** de crear el DMG |

### Comando Completo de Build + Empaquetado

Ejecutar desde la raíz del proyecto. Requiere que el build ya esté configurado con CMake.

```bash
# 1. Compilar
cmake --build build

# 2. Desplegar dependencias de Qt
macdeployqt build/DroidStar.app -qmldir=ui

# 3. Reemplazar el symlink de QtDBus con el framework real
rm -rf build/DroidStar.app/Contents/Frameworks/QtDBus.framework
cp -RL /opt/homebrew/Cellar/qt/6.8.2_1/lib/QtDBus.framework \
       build/DroidStar.app/Contents/Frameworks/QtDBus.framework

# 4. Corregir el install name de QtDBus para que sea relocatable
install_name_tool -id "@rpath/QtDBus.framework/Versions/A/QtDBus" \
  build/DroidStar.app/Contents/Frameworks/QtDBus.framework/Versions/A/QtDBus

# 5. Corregir rpaths en todos los plugins para que no apunten a /opt/homebrew
find build/DroidStar.app/Contents/PlugIns -name "*.dylib" | while read -r lib; do
    install_name_tool -delete_rpath "@loader_path/../../../../lib" "$lib" 2>/dev/null || true
    install_name_tool -add_rpath "@loader_path/../../Frameworks"  "$lib" 2>/dev/null || true
done

# 6. Arreglar permisos de QtDBus (fue copiado como root)
chmod -R 755 build/DroidStar.app/Contents/Frameworks/QtDBus.framework
chown -R $USER build/DroidStar.app/Contents/Frameworks/QtDBus.framework

# 7. Firmar QtDBus individualmente PRIMERO (evita el error "ambiguous format")
codesign --sign - --force \
  build/DroidStar.app/Contents/Frameworks/QtDBus.framework/Versions/A/QtDBus

# 8. Firmar el bundle completo
codesign --sign - --force --deep build/DroidStar.app

# 9. Limpiar xattrs de cuarentena ANTES de crear el DMG
xattr -cr build/DroidStar.app

# 10. Crear el DMG final
rm -f build/DroidStar.dmg
hdiutil create -volname "DroidStar" \
               -srcfolder build/DroidStar.app \
               -ov -format UDZO \
               build/DroidStar.dmg
```

### Instalación para el Usuario Final

1. Abrir `DroidStar.dmg`
2. Arrastrar `DroidStar.app` a `/Applications`
3. Al abrir por primera vez, si macOS muestra *"desarrollador no verificado"*:
   - Ir a **Ajustes del Sistema → Privacidad y Seguridad → Abrir de todos modos**
   - Este paso es necesario solo la primera vez (sin Apple Developer ID)

### Para Eliminar Completamente el Diálogo de Gatekeeper

Requiere una **Apple Developer ID** ($99/año) y el proceso de **notarización**:
```bash
# Con Developer ID registrada:
codesign --sign "Developer ID Application: Yury Jajitzky (TEAMID)" \
         --options runtime --deep --force build/DroidStar.app
xcrun notarytool submit build/DroidStar.dmg --apple-id tu@email.com \
         --password APP_SPECIFIC_PASSWORD --team-id TEAMID --wait
xcrun stapler staple build/DroidStar.dmg
```

### Versión de Qt instalada
- **Qt 6.8.2** via Homebrew: `/opt/homebrew/Cellar/qt/6.8.2_1/`
- Si se actualiza Qt, actualizar la ruta en el paso 3.

### Bundle ID
- `com.yuryjajitzky.DroidStar` — definido en `Info.plist`

---
*(Última actualización: Proceso completo de empaquetado macOS DMG documentado y validado)*
