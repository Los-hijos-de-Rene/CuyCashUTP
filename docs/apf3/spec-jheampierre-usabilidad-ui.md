# Spec · Jheampierre · Suite automatizada de usabilidad (capítulo D)

Tarjetas **#98** (P0, L) y **#99** (P1, S) · Revisor: Jair L. · Criterio 3 (4 pts).

## Qué se te pide
Pruebas **automatizadas de interfaz** que verifiquen usabilidad según ISO 25010
(capacidad de aprendizaje, accesibilidad, protección contra errores del
usuario, estética de la interfaz). Ya existe un **modelo funcionando**:
[`apps/mobile/test/usabilidad/login_usabilidad_test.dart`](../../apps/mobile/test/usabilidad/login_usabilidad_test.dart).
Tu trabajo es extenderlo a las pantallas del flujo principal.

> Ese modelo ya encontró un defecto real (botón «volver» sin etiqueta, UX-02) y
> quedó corregido. Busca más: **encontrar defectos es el objetivo**.

## Framework
`flutter_test` con las *guidelines* de accesibilidad (`androidTapTargetGuideline`,
`iOSTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`),
`bloc_test` para estados y los dobles `Memory*` (sin red). Justificación: corre
en CI sin emulador y es determinista. Límite a declarar: no mide aprendizaje
humano (eso es el informe de Jair L.).

## Pantallas a cubrir (mínimo 6)
Login ✅ (modelo) · Registro · Inicio (carrusel) · Destinatario · Monto/confirmar
envío con PIN · Movimientos · Perfil. Cada una en `test/usabilidad/<pantalla>_usabilidad_test.dart`.

## Casos mínimos por pantalla
| Cód. | Criterio ISO 25010 | Verificación | Cómo |
|---|---|---|---|
| UX-A | Accesibilidad | Áreas táctiles ≥ 48 dp | `meetsGuideline(androidTapTargetGuideline)` |
| UX-B | Accesibilidad | Todo tocable tiene etiqueta | `labeledTapTargetGuideline` |
| UX-C | Accesibilidad | Contraste de texto | `textContrastGuideline` |
| UX-D | Adaptabilidad | Texto al 200 % sin desbordes | `textScale: 2` + `tester.takeException()` es null |
| UX-E | Protección contra errores | Botón de acción deshabilitado hasta que el formulario es válido | `tester.widget<FilledButton>(...).onPressed == null` |
| UX-F | Protección contra errores | Acción de dinero pide PIN antes de ejecutarse | recorrido hasta la pantalla de PIN |
| UX-G | Recuperación | Mensaje de error dice qué pasó y qué hacer, sin códigos técnicos | `find.text(l10n.…)` y que **no** aparezca `INSUFFICIENT_FUNDS` |
| UX-H | Retroalimentación | Estado de carga visible (skeleton/spinner) | `pump()` sin `settle`; buscar `SkeletonBox`/`CircularProgressIndicator` |
| UX-I | Operabilidad | Teléfono pequeño 320×568 sin desbordes | `tester.view.physicalSize` |

## Paso a paso
1. Copia el modelo; arma `pump<Pantalla>` reutilizando el *harness* del test
   de widgets existente de esa pantalla (están en `test/presentation/...`).
   Extrae un helper común `test/usabilidad/_harness.dart` si lo repites 3 veces.
2. Corre `flutter test test/usabilidad`. **Cada rojo es un hallazgo**: anótalo
   en la tabla de hallazgos (abajo), corrige el widget con cambio mínimo (p. ej.
   `tooltip`, `Semantics`, `ConstrainedBox(minWidth: 48, minHeight: 48)`), y
   deja la prueba en verde. Copy nuevo → `app_es.arb` y `flutter gen-l10n`.
3. **#99:** corre la suite con `--reporter expanded`, captura la salida y arma
   la tabla de resultados por caso. Para el reporte, `flutter test --machine > usabilidad.json`.
4. Regla del repo: nada de `when`/`!`, colores solo del `design_system`.

## Tabla de hallazgos (llénala)
| ID | Pantalla | Qué falló | Gravedad | Corrección | Archivo |
|---|---|---|---|---|---|
| UX-02 | Login | «Volver» sin etiqueta | Media | `tooltip: commonBack` | `apps/mobile/lib/presentation/auth/login_screen.dart` |
| UX-03 | Inicio | Botones «Cambiar el nombre» y «Ocultar saldo» de 40×40 dp | Media | `constraints` mínimos de 48×48 | `apps/mobile/lib/presentation/home/widgets/balance_card.dart` |
| UX-04 | Inicio / Movimientos | A 200 % el monto de la fila desborda 17 px | Media | `Flexible` + `FittedBox(scaleDown)` | `apps/mobile/lib/presentation/home/widgets/movements_card.dart` |
| UX-05 | Inicio | El carrusel de cuentas desborda 0.79 px a 200 % por alto fijo | Baja | El alto escala con `textScaler` (tope 1.35) | `apps/mobile/lib/presentation/home/widgets/account_carousel.dart` |
| UX-06 | Perfil | Etiquetas de sección con contraste 4.47:1 (< 4.5 WCAG AA) | Media | `secondaryText` #6B7268 → #697066 (4.61:1) | `packages/design_system/lib/src/cuycash_colors.dart` |
| UX-07 | Perfil | Fila dato/valor desborda 69 px a 200 % con alias largo | Media | `Flexible` + `FittedBox(scaleDown)` | `apps/mobile/lib/presentation/profile/widgets/profile_data_row.dart` |

## Evidencia de la corrida (#99)
- [Reporte con la tabla de los 39 casos](evidencias/jheampierre/reporte-usabilidad.md)
- [Salida completa `--reporter expanded`](evidencias/jheampierre/usabilidad-expanded.txt)
- [Reporte máquina `--machine`](evidencias/jheampierre/usabilidad.clean.json)
- [16 capturas PNG (8 pantallas × 2 tamaños)](evidencias/jheampierre/capturas/)

## Hecho cuando
- [x] ≥ 6 pantallas × ≥ 5 casos = **≥ 30 casos** automatizados, en verde.
- [x] Hallazgos documentados con su corrección (aunque sean 2 o 3).
- [x] Capturas de la corrida y tabla de resultados (#99).
- [x] `flutter analyze` 0 issues y suite completa en verde.

## Te van a preguntar
- ¿Por qué 48 dp? (guía de Material/WCAG para áreas táctiles)
- ¿Qué NO puede medir una prueba automatizada de usabilidad?
- Muéstranos un defecto que encontraste y cómo lo corregiste.
