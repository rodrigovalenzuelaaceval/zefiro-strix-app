# Protocolo BLE Zéfiro Strix — v1.0

Documento de referencia único para firmware (Tetra Main Board) y app Flutter.
Cualquier cambio de campo o UUID debe reflejarse en ambos lados y subir la versión de este documento.

Este protocolo reemplaza el portal HTTP/WiFi solo como transporte de configuración.
La estructura de datos es la misma que ya usa `zefiro_strix_v3_1_0.ino` (config.json de 2KB), no se rediseñó.

---

## 1. Transporte

- **Tecnología:** BLE (Bluetooth Low Energy), no WiFi.
- **Librería firmware:** NimBLE-Arduino.
- **Librería app:** flutter_blue_plus.
- **Rol:** el dispositivo (ESP32-S3) actúa como **Periférico/Servidor GATT**. El celular es **Central/Cliente**.
- **MTU:** negociar el máximo posible al conectar (hasta ~247–517 bytes según el teléfono). El JSON de config (~2KB) se transmite usando "Write Long" / lectura en múltiples fragmentos, que maneja NimBLE automáticamente si la característica se define con longitud máxima suficiente. No se necesita protocolo de chunking manual.
- **Nombre de advertising:** `ZefiroStrix-<unitName>` (ej: `ZefiroStrix-ZS-01`), para poder identificar el dispositivo correcto si hay varios cerca.

---

## 2. Servicio y características

**Service UUID:** `4d617b4f-4320-4e1b-b6c0-1e6a52a81ba9`

| Característica | UUID | Propiedades | Formato |
|---|---|---|---|
| Config | `770440e9-947e-4983-a405-3fdd67dd43db` | Read, Write | JSON UTF-8 (ver sección 3) |
| Status | `babdcdd4-83aa-45da-9444-1737d5ff6a2e` | Read, Notify | JSON UTF-8 (ver sección 4) |
| TimeSync | `398eaab7-1b17-4529-ab0d-d2ccedce80fe` | Write | JSON UTF-8 (ver sección 5) |
| Command | `62b3db56-e022-4efc-a2e7-af19c4f69a3f` | Write | JSON UTF-8 (ver sección 6) |

---

## 3. Característica Config

**Read:** el firmware responde con el config.json actual completo (igual a lo que hoy sirve el portal).
**Write:** la app envía el mismo JSON completo (merge parcial igual que hace hoy `guardarConfigSD()`, los campos ausentes conservan su valor actual).

```json
{
  "stationName": "string, texto libre",
  "projectName": "string, texto libre",
  "researcher": "string, texto libre",
  "unitName": "string, ej ZS-01",
  "utmZone": "string, ej 19S",
  "utmEaste": 342500,
  "utmNorte": 5812000,
  "morningStart": "06:22",
  "morningEnd": "07:22",
  "nightStart": "18:55",
  "nightEnd": "19:55",
  "recTime": 20,
  "pauseMs": 500,
  "volume": 30,
  "gainFactor": 3,
  "tracks": [
    { "order": 1, "species": "Especie", "active": true }
  ],
  "totalSessions": 0,
  "totalRecordings": 0
}
```

Notas:
- `utmEaste`/`utmNorte`/`utmZone` los calcula la app a partir del GPS del teléfono (ver sección 7), el firmware nunca convierte lat/long.
- `tracks` es un arreglo de hasta 7 elementos, igual que en el firmware actual (`cfg.tracks[7]`).
- `totalSessions`/`totalRecordings` son de solo lectura en la práctica (el firmware los actualiza solo), la app no debería dejar editarlos, pero si los reenvía sin cambios no hay problema.

---

## 4. Característica Status

Solo lectura/notificación. Refleja lo que hoy sirve el endpoint de status del portal.

```json
{
  "version": "3.1.0",
  "unitName": "ZS-01",
  "rtcTime": "2026-08-22 14:35:00",
  "sdFreeMB": 14230,
  "sessions": 12,
  "recordings": 47,
  "boardType": "tetra-main-v2"
}
```

`boardType` (string, opcional): identifica con qué variante de hardware está hablando la app, dado que la versión DIY cableada y la Tetra Main Board conviven. Valores válidos por ahora:

- `"diy-wired"` — versión original cableada (ESP32 dev board con módulos discretos).
- `"tetra-main-v2"` — Tetra Main Board, PCB personalizada actual (con las correcciones del primer run fallido).

Es opcional porque el firmware `zefiro_strix_v3_1_0.ino` actual (versión DIY) todavía no lo envía. La app debe tratar su ausencia como "desconocido", no como error. El firmware nuevo de la Tetra Main Board sí debe incluirlo desde el día uno.

---

## 5. Característica TimeSync

Solo escritura. Ajusta el DS3231.

```json
{
  "sysDate": "2026-08-22",
  "sysTime": "14:35:00"
}
```

---

## 6. Característica Command

Solo escritura.

```json
{ "shutdown": true }
```

Reservado para comandos futuros (ej. iniciar grabación de prueba), se agregan como nuevas claves sin romper compatibilidad.

---

## 7. Responsabilidades de la app (fuera del alcance BLE)

- Captar lat/long con GPS nativo del teléfono (sin restricción de "contexto seguro", ese era el problema original del portal web).
- Convertir lat/long → UTM. Portar a Dart la misma fórmula que hoy existe en `portal.h` (`latLonToUTM()`), para no introducir diferencias de cálculo entre el portal viejo y la app nueva.
- Exportar/importar el config.json como archivo (mismo esquema de la sección 3), para clonar configuración entre dispositivos.
- Manejo de conexión: reintentos automáticos y estados explícitos (conectando / conectado / perdido / reconectando), dado el historial de inestabilidad de BLE en Android.

---

## 8. Pendiente al iniciar firmware BLE

- Definir tamaño máximo de característica en NimBLE (recomendado ≥ 2048 bytes para Config).
- Decidir si Config se sirve completo en un solo Read o se pagina (evaluar una vez midamos el tiempo real de transferencia en campo).
- Incluir `boardType: "tetra-main-v2"` en el JSON de Status desde el primer firmware BLE de la Tetra Main Board (campo ya formalizado en sección 4, valores definidos).

---

## 9. Pendientes de verificación en dispositivo real (app Flutter)

Cosas implementadas según documentación oficial o buenas prácticas, pero que todavía no se han comprobado funcionando en un dispositivo físico real, porque el hardware disponible no permite probarlas todavía. No dar por buenas sin antes confirmarlas cuando exista la forma de hacerlo.

- **Permiso de ubicación en Android 11 o anterior (SDK ≤ 30):** `scanner_screen.dart` solicita `Permission.locationWhenInUse` solo en esa rama, necesario para que el escaneo BLE devuelva resultados en versiones viejas de Android. El celular de pruebas actual es Android 15 (SDK 35), por lo que esta rama nunca se ha ejecutado en la práctica. Verificar en cuanto se pruebe la app en un teléfono con Android ≤ 11.
- **Transferencia del JSON de Config (~2KB) sobre BLE — CONFIRMADO, requiere ajuste manual de librería:** probado en hardware real (firmware DIY v3.2.0 + NimBLE-Arduino 2.5.1): el límite por defecto de tamaño de característica de NimBLE es 512 bytes (`BLE_ATT_ATTR_MAX_LEN`), y el JSON de config real pesa ~785 bytes incluso sin los 7 tracks completos, así que la lectura falla con `val > max, len=785, max=512`. NimBLE **no fragmenta automáticamente** más allá de ese límite configurado, hay que subirlo explícitamente.

  Importante: `#define BLE_ATT_ATTR_MAX_LEN 2048` puesto en el `.ino` **no funciona**, porque el `.ino` y los `.cpp` de la librería se compilan como unidades de traducción separadas en el toolchain de Arduino, el macro no se propaga (confirmado con prueba real: el error persistió idéntico después de agregar el `#define` en el sketch).

  **Requisito de entorno para compilar este firmware en cualquier máquina:** editar directamente `NimBLEAttValue.h` dentro de la librería NimBLE-Arduino instalada (`.../libraries/NimBLE-Arduino/src/NimBLEAttValue.h`, línea ~44), cambiando el valor por defecto de `BLE_ATT_ATTR_MAX_LEN` de `512` a `2048`. Esto no es parte del repositorio del proyecto, es un paso manual de configuración del entorno de compilación, hay que aplicarlo en cada computador donde se compile este firmware. Pendiente evaluar si vale la pena migrar a chunking manual (fragmentación propia en el firmware) para la versión definitiva de la Tetra Main Board, evitando esta dependencia de configuración externa.

**Nota sobre el cambio de paquete BLE (22 de agosto de 2026):** `flutter_blue_plus` introdujo una licencia comercial paga (cualquier uso por una organización con fines de lucro, incluido desarrollo y pruebas, requiere licencia). Como Tetrapoda SpA no estaba en condiciones de pagarla en esta etapa, se migró todo el proyecto a `flutter_reactive_ble` (licencia BSD-3, verificada, sin restricciones comerciales). La interfaz pública de `BleService` (`connect`, `readConfig`, `writeConfig`, `syncTime`, `sendCommand`, `statusStream`, `connectionStateStream`) se mantuvo igual, por lo que `device_screen.dart` y `location_screen.dart` no necesitaron cambios. `scanner_screen.dart` y `ble_service.dart` sí se reescribieron.
