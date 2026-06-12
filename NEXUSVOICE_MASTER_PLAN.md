# NEXUSVOICE — Master Plan

> Fork de DroidStar con C API thread-safe consumible desde Flutter via `dart:ffi`

---

## Fase 1 — Auditoría y Corrección de Bugs ✅

| # | Hallazgo | Estado |
|---|----------|--------|
| 1 | RPTC duplicado en `DMR::process_udp()` causa pérdida de audio RX en BrandMeister | ✅ |
| 2–5 | Variables `static` locales → member variables en DMR, M17, YSF, P25, REF, DCS, XRF, NXDN | ✅ |
| 6 | `Mode::deleteLater()` doble-free con null checks | ✅ |
| 7 | `m_modethread->quit()` sin `wait()` | ✅ |
| 8 | `delete current_mode` desde thread incorrecto → `deleteLater()` | ✅ |
| 9 | `pcm[]` sin inicializar en `transmit()` → zero-init en 8 protocolos | ✅ |

## Fase 2 — Higiene de Código C++

| # | Tarea | Estado |
|---|-------|--------|
| 2.1 | Headers self-contained (includes faltantes) | ✅ |
| 2.2 | Const correctness (~90 getters marcados `const`) | ✅ |
| 2.3 | nullptr checks (~60 accesos protegidos) | ✅ |
| 2.4 | C-style casts → `static_cast` | ⏭️ Skipped (estilístico, cientos de instancias) |
| 2.5 | Inicialización explícita de miembros (~30 miembros con init in-class) | ✅ |

## Fase 3 — C API Thread-Safe

| # | Tarea | Estado |
|---|-------|--------|
| 3.1 | `nv_context` con `creator_thread` + `async()` / `sync()` dispatch | ✅ |
| 3.2 | ~50 funciones C API envueltas con dispatch a creator thread | ✅ |
| 3.3 | Macros `NV_SETTER_STR/INT/DBL/BOOL` para setters | ✅ |
| 3.4 | Helpers `str_getter` / `json_list_getter` para getters | ✅ |
| 3.5 | `nv_pump_events()` → `QCoreApplication::processEvents()` | ✅ |
| 3.6 | Getters de geolocalización (`nv_get_latitude`, `nv_get_longitude`, `nv_get_location`, `nv_get_description`) | ✅ |
| 3.7 | Build C++ compila limpio (0 warnings) | ✅ |

## Fase 4 — Flutter FFI Bindings

| # | Tarea | Estado |
|---|-------|--------|
| 4.1 | `nv_bindings.dart`: bindings completos (`lookupFunction`) | ✅ |
| 4.2 | `nv_controller.dart`: singleton `ChangeNotifier` + callbacks C→Dart + Timer 50ms pump | ✅ |
| 4.3 | `flutter analyze` — 0 issues | ✅ |

## Fase 5 — Integración Qt/Flutter (Opción B)

| # | Tarea | Estado |
|---|-------|--------|
| 5.1 | Timer periódico 50ms → `nv_pump_events()` → `processEvents()` | ✅ |
| 5.2 | Qt y DroidStar en platform thread de Flutter (sin threads extra) | ✅ |
| 5.3 | `async()`/`sync()` son no-ops (mismo thread) | ✅ |
| 5.4 | App prueba exitosa: audio DMR en vivo recibido y reproducido | ✅ |

## Fase 6 — UI Flutter

| # | Tarea | Estado |
|---|-------|--------|
| 6.1 | Main panel (modo, host, TGID, slot, CC, connect/disconnect) | ✅ |
| 6.2 | Level meter RX con segmentos de color | ✅ |
| 6.3 | PTT button con animación pulso | ✅ |
| 6.4 | Status bar con LED + pills de estado | ✅ |
| 6.5 | Settings panel (callsign, DMR ID, ESSID, passwords, audio devices, volúmenes) | ✅ |
| 6.6 | Settings — geolocalización (lat, lon, location, description) | ✅ |
| 6.7 | Presets panel (5 slots de memoria) | ✅ |
| 6.8 | Logs panel (consola en vivo) | ✅ |
| 6.9 | Layout desktop (sidebar) + mobile (BottomNavigationBar) | ✅ |
| 6.10 | Deprecation `withOpacity` → `withValues(alpha:)` (81 ocurrencias) | ✅ |
| 6.11 | `background` deprecation fix + `inactiveColor` unused removal | ✅ |

## Fase 6.5 — Desacople de Qt (en progreso)

| # | Tarea | Estado |
|---|-------|--------|
| 6.5.1 | QSettings → nlohmann/json (`~/.config/nexusvoice/settings.json`) | ✅ |
| 6.5.0 | HttpManager (QNetworkAccessManager) → cpp-httplib | ✅ |
| 6.5.2 | QThread → std::thread | ❌ |
| 6.5.3 | QUdpSocket/QTcpSocket → asio | ❌ |
| 6.5.4 | QTimer → std::chrono | ❌ |
| 6.5.5 | QAudioSink/QAudioSource → PortAudio | ❌ |
| 6.5.6 | QSerialPort → asio::serial_port | ❌ |
| 6.5.7 | QProcess/QNetworkAccessManager → cpp-httplib (HttpManager reemplazado) | ✅ |
| 6.5.8 | QString/QByteArray → std::string/span | ❌ |
| 6.5.9 | QFile/QDir → std::filesystem | ❌ |
| 6.5.10 | signals/slots → std::function observers | ❌ |
| 6.5.11 | QMutex → std::mutex | ❌ |
| 6.5.12 | Eliminar Qt de CMakeLists.txt | ❌ |

## Fase 7 — Packaging y Distribución (Pendiente)

| # | Tarea | Estado |
|---|-------|--------|
| 7.1 | Bundlear Qt frameworks en `.app` para distribución macOS | ⏳ |
| 7.2 | Signing y notarization | ❌ |
| 7.3 | Documentación README | ❌ |
| 7.4 | Cross-platform testing (iOS/Android/Windows) | ❌ |

## MD380 Vocoder

| # | Tarea | Estado |
|---|-------|--------|
| — | Silenciar `ExceptionRaised()` (firmware usa UDF #0 como retorno normal) | ✅ |

## Leyenda

- ✅ Completado
- ⏳ En progreso
- ❌ No iniciado
- ⏭️ Skipped

---

**Última actualización:** 2026-06-12  
**Stack:** C++17 + Qt 6 + Flutter 3.27+ + dart:ffi  
**Arquitectura:** macOS Apple Silicon (portable a Windows/Linux)
