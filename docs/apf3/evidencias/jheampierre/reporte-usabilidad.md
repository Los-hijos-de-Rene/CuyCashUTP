# Reporte de la suite de usabilidad (tarjeta APF3 #99)

Evidencia de ejecución de `apps/mobile/test/usabilidad` (capítulo D · ISO/IEC 25010).
Rama: `feat/apf3-usabilidad-goldens`.

## Entorno y fecha

| Dato | Valor |
|---|---|
| Fecha de la corrida | 2026-11-03, 23:24–23:26 (UTC−05:00) |
| Sistema | Windows (`win32`), PowerShell |
| Flutter | 3.47.1 · canal stable · revisión `6655482ec0` (2026-08-19) |
| Dart | 3.13.1 |
| DevTools | 2.60.0 |
| Motor | `11d79658c444477b06513d32b52c8c4ccb7276b0` |

Salida literal de `flutter --version`:

```text
Flutter 3.47.1 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 6655482ec0 (3 months ago) • 2026-08-19 10:07:23 -0700
Engine • hash 11d79658c444477b06513d32b52c8c4ccb7276b0 (revision 5d53178869) (2 months ago) • 2026-08-18 23:36:01.000Z
Tools • Dart 3.13.1 • DevTools 2.60.0
```

## Comandos ejecutados

Desde `C:\Users\Jheampierre\Desktop\proyectos\utp-banco-jair\apps\mobile`:

```powershell
flutter test test/usabilidad --reporter expanded > ..\..\docs\apf3\evidencias\jheampierre\usabilidad-expanded.txt 2>&1
flutter test test/usabilidad --machine > ..\..\docs\apf3\evidencias\jheampierre\usabilidad.json 2>&1
flutter --version
```

El comando `--machine` del paso anterior guarda también la salida de
`flutter pub get` que el tool imprime por *stdout* (77 líneas) antes del primer
evento JSON. Para dejar un archivo JSON-lines limpio y consumible por
herramientas se repitió el mismo reporte sin resolución de dependencias:

```powershell
flutter test test/usabilidad --machine --no-pub > ..\..\docs\apf3\evidencias\jheampierre\usabilidad.clean.json 2>&1
```

Archivos de evidencia:

- `usabilidad-expanded.txt` — salida completa del reporter `expanded`.
- `usabilidad.json` — reporte máquina del comando literal (incluye el preámbulo de `pub get`).
- `usabilidad.clean.json` — reporte máquina JSON-lines puro (153 líneas, 0 líneas no JSON).

## Totales reales

| Métrica | Valor |
|---|---|
| Casos ejecutados | **39** |
| Aprobados | **39** |
| Fallidos | **0** |
| Omitidos (*skipped*) | **0** |
| Archivos de prueba | **8** |
| Pantallas cubiertas | **8** (Login, Registro, Inicio, Destinatario, Monto, Confirmar, Movimientos, Perfil) |
| Resultado global | `All tests passed!` · evento `done` con `"success": true` |

Los totales salen del reporte máquina: 47 eventos `testDone`, de los cuales 8
son los pseudo-tests `loading <archivo>` que emite `flutter test` (`hidden:
true`); quedan **39 casos reales**, todos con `result: "success"` y
`skipped: false`.

Desglose por archivo:

| Archivo | Casos | Aprobados | Fallidos |
|---|---:|---:|---:|
| `login_usabilidad_test.dart` | 4 | 4 | 0 |
| `registro_usabilidad_test.dart` | 5 | 5 | 0 |
| `inicio_usabilidad_test.dart` | 5 | 5 | 0 |
| `destinatario_usabilidad_test.dart` | 5 | 5 | 0 |
| `monto_usabilidad_test.dart` | 5 | 5 | 0 |
| `confirmar_usabilidad_test.dart` | 5 | 5 | 0 |
| `movimientos_usabilidad_test.dart` | 5 | 5 | 0 |
| `perfil_usabilidad_test.dart` | 5 | 5 | 0 |
| **Total** | **39** | **39** | **0** |

## Resultados por caso

### Login — `apps/mobile/test/usabilidad/login_usabilidad_test.dart`

| Código | Pantalla | Descripción | Archivo de prueba | Resultado |
|---|---|---|---|---|
| UX-01 | Login | Áreas táctiles ≥ 48 dp (`androidTapTargetGuideline`) | `test/usabilidad/login_usabilidad_test.dart` | ✅ |
| UX-02 | Login | Todo control tocable tiene etiqueta (`labeledTapTargetGuideline`) | `test/usabilidad/login_usabilidad_test.dart` | ✅ |
| UX-03 | Login | Contraste de texto suficiente (`textContrastGuideline`) | `test/usabilidad/login_usabilidad_test.dart` | ✅ |
| UX-04 | Login | Texto al 200 % sin desbordes | `test/usabilidad/login_usabilidad_test.dart` | ✅ |

> Ojo: los códigos de caso del test de login (`UX-01`…`UX-04`) usan el mismo
> espacio de nombres que los hallazgos `UX-02`…`UX-07` del spec. Son cosas
> distintas: `UX-01…` identifica un caso de prueba; `UX-03…` en la sección
> «Hallazgos corregidos» identifica un defecto. Se conserva el nombre original
> del test para no romper la trazabilidad de la corrida.

### Registro (paso «Datos») — `apps/mobile/test/usabilidad/registro_usabilidad_test.dart`

| Código | Pantalla | Descripción | Archivo de prueba | Resultado |
|---|---|---|---|---|
| UX-REG-01 | Registro | Áreas táctiles ≥ 48 dp, etiquetas y contraste | `test/usabilidad/registro_usabilidad_test.dart` | ✅ |
| UX-REG-02 | Registro | Texto al 200 % sin desbordes (4 campos visibles) | `test/usabilidad/registro_usabilidad_test.dart` | ✅ |
| UX-REG-03 | Registro | Teléfono 320×568 sin desbordes | `test/usabilidad/registro_usabilidad_test.dart` | ✅ |
| UX-REG-04 | Registro | Avanzar con datos inválidos explica qué corregir, sin códigos técnicos | `test/usabilidad/registro_usabilidad_test.dart` | ✅ |
| UX-REG-05 | Registro | El botón «Continuar» queda al alcance tras el scroll | `test/usabilidad/registro_usabilidad_test.dart` | ✅ |

### Inicio (carrusel de cuentas) — `apps/mobile/test/usabilidad/inicio_usabilidad_test.dart`

| Código | Pantalla | Descripción | Archivo de prueba | Resultado |
|---|---|---|---|---|
| UX-INICIO-01 | Inicio | Áreas táctiles, etiquetas y contraste | `test/usabilidad/inicio_usabilidad_test.dart` | ✅ |
| UX-INICIO-02 | Inicio | Texto al 200 % sin desbordes; el saldo sigue visible | `test/usabilidad/inicio_usabilidad_test.dart` | ✅ |
| UX-INICIO-03 | Inicio | Teléfono 320×568 sin desbordes | `test/usabilidad/inicio_usabilidad_test.dart` | ✅ |
| UX-INICIO-04 | Inicio | Mientras carga se ve la silueta (`HomeSkeleton`), no un vacío ni spinner | `test/usabilidad/inicio_usabilidad_test.dart` | ✅ |
| UX-INICIO-05 | Inicio | El error de red dice qué hacer y no filtra códigos técnicos | `test/usabilidad/inicio_usabilidad_test.dart` | ✅ |

### Destinatario (¿A quién?) — `apps/mobile/test/usabilidad/destinatario_usabilidad_test.dart`

| Código | Pantalla | Descripción | Archivo de prueba | Resultado |
|---|---|---|---|---|
| UX-DEST-01 | Destinatario | Áreas táctiles, etiquetas y contraste | `test/usabilidad/destinatario_usabilidad_test.dart` | ✅ |
| UX-DEST-02 | Destinatario | Texto al 200 % sin desbordes | `test/usabilidad/destinatario_usabilidad_test.dart` | ✅ |
| UX-DEST-03 | Destinatario | Teléfono 320×568 sin desbordes | `test/usabilidad/destinatario_usabilidad_test.dart` | ✅ |
| UX-DEST-04 | Destinatario | «Buscar» solo aparece con un alias válido | `test/usabilidad/destinatario_usabilidad_test.dart` | ✅ |
| UX-DEST-05 | Destinatario | Un DNI desconocido explica qué pasó y qué hacer | `test/usabilidad/destinatario_usabilidad_test.dart` | ✅ |

### Monto (¿Cuánto?) — `apps/mobile/test/usabilidad/monto_usabilidad_test.dart`

| Código | Pantalla | Descripción | Archivo de prueba | Resultado |
|---|---|---|---|---|
| UX-MONTO-01 | Monto | Áreas táctiles, etiquetas y contraste | `test/usabilidad/monto_usabilidad_test.dart` | ✅ |
| UX-MONTO-02 | Monto | Texto al 200 % sin desbordes | `test/usabilidad/monto_usabilidad_test.dart` | ✅ |
| UX-MONTO-03 | Monto | Teléfono 320×568 sin desbordes | `test/usabilidad/monto_usabilidad_test.dart` | ✅ |
| UX-MONTO-04 | Monto | «Continuar» deshabilitado hasta que el monto es válido | `test/usabilidad/monto_usabilidad_test.dart` | ✅ |
| UX-MONTO-05 | Monto | Un monto fuera del límite indica el máximo y bloquea el avance | `test/usabilidad/monto_usabilidad_test.dart` | ✅ |

### Confirmar envío con PIN — `apps/mobile/test/usabilidad/confirmar_usabilidad_test.dart`

| Código | Pantalla | Descripción | Archivo de prueba | Resultado |
|---|---|---|---|---|
| UX-CONF-01 | Confirmar | Áreas táctiles, etiquetas y contraste | `test/usabilidad/confirmar_usabilidad_test.dart` | ✅ |
| UX-CONF-02 | Confirmar | Texto al 200 % sin desbordes | `test/usabilidad/confirmar_usabilidad_test.dart` | ✅ |
| UX-CONF-03 | Confirmar | Teléfono 320×568 sin desbordes | `test/usabilidad/confirmar_usabilidad_test.dart` | ✅ |
| UX-CONF-04 | Confirmar | No se puede confirmar hasta tener los 6 dígitos | `test/usabilidad/confirmar_usabilidad_test.dart` | ✅ |
| UX-CONF-05 | Confirmar | El dinero no se mueve sin el PIN completo (1 llamada, PIN correcto) | `test/usabilidad/confirmar_usabilidad_test.dart` | ✅ |

### Movimientos — `apps/mobile/test/usabilidad/movimientos_usabilidad_test.dart`

| Código | Pantalla | Descripción | Archivo de prueba | Resultado |
|---|---|---|---|---|
| UX-MOV-01 | Movimientos | Áreas táctiles, etiquetas y contraste | `test/usabilidad/movimientos_usabilidad_test.dart` | ✅ |
| UX-MOV-02 | Movimientos | Texto al 200 % sin desbordes; el título sigue visible | `test/usabilidad/movimientos_usabilidad_test.dart` | ✅ |
| UX-MOV-03 | Movimientos | Teléfono 320×568 sin desbordes | `test/usabilidad/movimientos_usabilidad_test.dart` | ✅ |
| UX-MOV-04 | Movimientos | Mientras carga se ve la silueta (`MovementsSkeleton`) | `test/usabilidad/movimientos_usabilidad_test.dart` | ✅ |
| UX-MOV-05 | Movimientos | El historial de una cuenta muestra su saldo | `test/usabilidad/movimientos_usabilidad_test.dart` | ✅ |

### Perfil — `apps/mobile/test/usabilidad/perfil_usabilidad_test.dart`

| Código | Pantalla | Descripción | Archivo de prueba | Resultado |
|---|---|---|---|---|
| UX-PERFIL-01 | Perfil | Áreas táctiles, etiquetas y contraste | `test/usabilidad/perfil_usabilidad_test.dart` | ✅ |
| UX-PERFIL-02 | Perfil | Texto al 200 % sin desbordes; el DNI sigue visible | `test/usabilidad/perfil_usabilidad_test.dart` | ✅ |
| UX-PERFIL-03 | Perfil | Teléfono 320×568 sin desbordes | `test/usabilidad/perfil_usabilidad_test.dart` | ✅ |
| UX-PERFIL-04 | Perfil | Cerrar sesión pide confirmación antes de actuar | `test/usabilidad/perfil_usabilidad_test.dart` | ✅ |
| UX-PERFIL-05 | Perfil | El perfil muestra el alias y permite editarlo | `test/usabilidad/perfil_usabilidad_test.dart` | ✅ |

## Hallazgos corregidos

Los defectos que encontró la suite y su corrección (tabla del
[spec](../../spec-jheampierre-usabilidad-ui.md), columna «Corrección»). El archivo
tocado se tomó del commit `53410eb` (`test(usabilidad): suite de 7 pantallas y
correccion de UX-03 a UX-07 (#98)`).

| ID | Pantalla | Qué falló | Gravedad | Corrección | Archivo tocado |
|---|---|---|---|---|---|
| UX-03 | Inicio | Los botones «Cambiar el nombre» y «Ocultar saldo» medían 40×40 dp, por debajo de los 48 dp | Media | `constraints` mínimos de 48×48 (`BoxConstraints(minWidth: 48, minHeight: 48)`) | `apps/mobile/lib/presentation/home/widgets/balance_card.dart` |
| UX-04 | Inicio / Movimientos | A 200 % el monto de la fila desbordaba 17 px | Media | `Flexible` + `FittedBox(scaleDown)` y `maxLines: 1` | `apps/mobile/lib/presentation/home/widgets/movements_card.dart` |
| UX-05 | Inicio | El carrusel de cuentas desbordaba 0.79 px a 200 % por alto fijo | Baja | El alto escala con `textScaler` (`MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.35)`) | `apps/mobile/lib/presentation/home/widgets/account_carousel.dart` |
| UX-06 | Perfil | Etiquetas de sección con contraste 4.47:1 (< 4.5 WCAG AA) | Media | `secondaryText` #6B7268 → #697066 (4.61:1) | `packages/design_system/lib/src/cuycash_colors.dart` |
| UX-07 | Perfil | La fila dato/valor desbordaba 69 px a 200 % con alias largo | Media | `Flexible` + `FittedBox(scaleDown)` y `maxLines: 1` | `apps/mobile/lib/presentation/profile/widgets/profile_data_row.dart` |

Contexto: **UX-02** (Login, «Volver» sin etiqueta) ya estaba corregido con
`tooltip: commonBack` antes de esta tarjeta y por eso el caso `UX-02` del test
de login aparece en verde.

Las cinco correcciones son cambios mínimos de widget/estilo; no cambian la
lógica de negocio ni los contratos. La suite queda en verde con ellas.

## Verificación de los totales

El markdown se contrastó con `usabilidad.clean.json` contando eventos
`testDone` y usando los campos `result` y `skipped`:

- `testDone` totales: 47 → 8 con `hidden: true` (pseudo-tests de carga) → **39 casos reales**.
- `result`: 39 `success`, 0 `failure`, 0 `error`.
- `skipped`: 39 con `skipped: false` → **0 omitidos**.
- Evento final `done`: `{"success": true, "type": "done"}`.
- `usabilidad.json` (comando literal) contiene los mismos 39 casos; sus 77
  primeras líneas son salida de `pub get`, no eventos del protocolo.

**Discrepancias encontradas: ninguna en los totales.** Los dos archivos JSON y
el reporter `expanded` coinciden en 39 casos ejecutados y 39 aprobados.

Incidencias de la corrida (no afectan a los totales):

1. `flutter test` ejecuta un `pub get` implícito que reescribió
   `pubspec.lock` (7 dependencias) y añadió exclusiones del analizador en
   `apps/mobile/analysis_options.yaml`. Son efectos del tool, no del código de
   la app; se revirtieron con `git checkout -- pubspec.lock apps/mobile/analysis_options.yaml`
   para no ensuciar la rama. Al reproducir la evidencia volverán a aparecer.
2. Ese mismo `pub get` imprime su salida por *stdout*, por eso el archivo
   `usabilidad.json` del comando literal no es JSON-lines puro; de ahí
   `usabilidad.clean.json`.

## Cómo reproducir

```powershell
cd C:\Users\Jheampierre\Desktop\proyectos\utp-banco-jair\apps\mobile

# 1) Salida legible completa
flutter test test/usabilidad --reporter expanded > ..\..\docs\apf3\evidencias\jheampierre\usabilidad-expanded.txt 2>&1

# 2) Reporte máquina (JSON-lines)
flutter test test/usabilidad --machine > ..\..\docs\apf3\evidencias\jheampierre\usabilidad.json 2>&1

# 2b) Opcional: JSON-lines limpio, sin el preámbulo de pub get
flutter test test/usabilidad --machine --no-pub > ..\..\docs\apf3\evidencias\jheampierre\usabilidad.clean.json 2>&1
```

Resultado esperado: `+39: All tests passed!` y `"success": true` en el evento
`done`.
