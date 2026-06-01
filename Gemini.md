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
