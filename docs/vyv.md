# Plan de Verificación y Validación (V&V)

**Sesión 20 · Curso Integrador II.** Plan formal de V&V basado en el modelo en
V (IEEE 1012 como referencia): qué se **verifica** (¿construimos bien?), qué se
**valida** (¿construimos lo correcto?), con qué evidencia y qué falta. Se apoya
en [`idoneidad-funcional.md`](idoneidad-funcional.md) (sesión 19) y alimenta
el informe de APF3.

Corte: 2026-10-23, rama `feat/idoneidad-funcional-iso25010`.

---

## 1. Modelo en V aplicado a CuyCash

| Nivel de especificación | Artefacto del proyecto | Nivel de prueba | Evidencia hoy |
|---|---|---|---|
| Necesidad del negocio | 26 HU y 96 CA ([`idoneidad-funcional.md`](idoneidad-funcional.md) §1) | **Aceptación (UAT)** | §4: 3 escenarios, API automatizada; pantallas pendientes |
| Arquitectura | ADR 0001/0002, contrato `/v1`, libro mayor ([`modelo-datos.md`](modelo-datos.md)) | **Integración** | 363 pruebas de API contra HTTP y base real (Postgres 18 en CI); contrato `Memory*` ↔ `Http*` en la app |
| Diseño modular | `feature/<x>/{domain,application,infrastructure}`, `Money`, `ledger.py` | **Unitarias** | 901 de la app (incl. bloc y widgets) + 35 de paquetes |
| Código | Dart y Python | **Verificación estática** | §3 |

Es una guía conceptual, no un ciclo rígido: el equipo trabaja en sprints.

## 2. Verificación y validación: quién y cuándo

| | Verificación | Validación |
|---|---|---|
| Pregunta | ¿Construimos bien el producto? | ¿Construimos el producto correcto? |
| Técnicas | Análisis estático, pruebas automatizadas, PR, `pip-audit`, ZAP | UAT con guion, criterios de aceptación, acta |
| Responsable | Equipo de desarrollo y QA | Product Owner y usuarios representativos |
| Cuándo | Continua, en cada PR | En hitos (fin de sprint, despliegue v1/v2) |
| Estado | **Automatizada y en verde** (§3) | **Parcial**: servidor sí, pantallas y usuarios no (§4–§6) |

**Hueco de rol:** el equipo aún no designó Product Owner
([`gestion-del-equipo.md`](gestion-del-equipo.md) §3). Sin PO nadie puede firmar
el acta de conformidad (§5): la validación formal depende de ese nombramiento.

## 3. Verificación estática y criterios de bloqueo del merge

Reglas acordadas y quién las hace cumplir:

| Regla | Herramienta | Dónde corre | Bloquea el merge |
|---|---|---|---|
| Cero issues de análisis (`strict-casts`, `strict-raw-types`, `flutter_lints`) | `flutter analyze` | CI, job *App (Flutter)* | Sí (vía *CI listo*) |
| Toda la suite en verde | `flutter test`, `pytest` | CI (backend sobre PostgreSQL 18) | Sí |
| Esquema ↔ modelo (`schema.sql` regenerado) | `test_consistencia_ddl.py` | CI | Sí |
| Sin dependencias con avisos publicados | `pip-audit` | CI y CD | Sí |
| Rutas `/v1` sin token devuelven 401 | `test_sesion_requerida.py` | CI | Sí |
| Dinero sin `double`, sin `throw` entre capas, sin `when`/`!` | Reglas duras de `CLAUDE.md` | **Revisión humana de PR** | No automático |
| Escaneo dinámico (ZAP activo/pasivo) | `seguridad.yml` | Semanal y manual | No (informa) |

Resultado de la verificación en este corte (ejecutada hoy, no copiada):

| Verificación | Resultado |
|---|---|
| `flutter analyze` | 0 issues |
| `pytest` (backend, SQLite) | 363 aprobadas, 3 omitidas |
| `flutter test` (app) | 901 aprobadas, 2 omitidas (frecuentes ocultos) |
| Paquetes (`core_kernel`, `design_system`) | 23 + 12 aprobadas |
| **Total** | **1 299 aprobadas, 0 fallidas, 5 omitidas a propósito** |

**Brechas de verificación estática (a declarar):**

1. **El backend no tiene linter ni análisis estático propio** (ni ruff, flake8,
   mypy ni bandit): solo `pip-audit`. Propuesta: `ruff` en CI, bloqueante.
2. **La regla de `main` exige 0 revisiones aprobatorias**
   (`required_approving_review_count: 0` en el ruleset). La revisión entre pares
   existe por costumbre, no por regla. Propuesta: exigir 1 aprobación.
3. **No hay plantilla de PR con checklist de calidad.** Propuesta: añadir
   `.github/pull_request_template.md` con las reglas duras de la tabla anterior.
4. Las reglas «sin `when`/`!`» y «sin `double` para dinero» no tienen
   comprobación automática (se podrían forzar con reglas de `analysis_options`).

## 4. Guion UAT (3 escenarios)

Formato de la sesión: precondición, pasos y resultado esperado. Cada uno tiene
su **versión automatizada** del lado del servidor
(`services/api/tests/test_aceptacion_uat.py`) y su versión de pantalla en
[`verificacion-manual.md`](verificacion-manual.md).

### UAT-1 · Enviar dinero a otro titular (HU06, HU05, HU18)

| | |
|---|---|
| Precondición | A tiene S/ 500.00. B está registrado con una cuenta en soles. |
| Pasos | 1. A busca a B por DNI. 2. Elige su cuenta. 3. Envía S/ 125.50 y confirma con PIN. 4. Ambos abren su historial. |
| Esperado | A ve a B **enmascarado** (`L*** A*** Q***`). A queda con S/ 374.50 y B con S/ 125.50. A ve **un** movimiento de débito y B uno de crédito con el nombre completo de A. Débitos = créditos en el libro. |
| Criterios de éxito | Tarea completada sin ayuda; 0 errores; importes idénticos en ambos lados. |
| Automatizado | `test_uat1_enviar_dinero_a_otro_titular_y_que_ambos_lados_cuadren` |
| Pantalla | Pasos 6–9 de `verificacion-manual.md` (**sin ejecutar**) |

### UAT-2 · Envío sin saldo suficiente (HU06 CA3, HU17 CA1)

| | |
|---|---|
| Precondición | A tiene S/ 50.00. |
| Pasos | 1. A intenta enviar S/ 500.00. 2. Reintenta con la misma operación. |
| Esperado | Error `INSUFFICIENT_FUNDS` legible, sin trazas ni SQL. Saldos intactos. El historial de A solo tiene el depósito. |
| Criterios de éxito | El usuario entiende qué pasó y qué hacer; no se mueve dinero. |
| Automatizado | `test_uat2_sin_saldo_el_envio_se_rechaza_con_un_error_claro_y_sin_mover_dinero` |
| Pantalla | **Sin guion manual todavía**: añadirlo a `verificacion-manual.md` al ejecutar el paso 8 con un monto mayor al saldo. |

### UAT-3 · Protección del acceso (HU03 CA3, seguridad)

| | |
|---|---|
| Precondición | A con sesión y saldo S/ 1,000.00. |
| Pasos | 1. Pedir datos sin sesión. 2. Intentar mover dinero con PIN errado hasta agotar los intentos. 3. Probar el PIN correcto. |
| Esperado | 401 sin sesión. `INVALID_CREDENTIALS` en cada intento fallido. Al agotarlos, 423 `IDENTIFIER_LOCKED` y **ni el PIN correcto pasa**. El dinero no se movió. |
| Criterios de éxito | La cuenta se defiende sola; el mensaje no revela datos. |
| Automatizado | `test_uat3_el_acceso_se_protege_sin_sesion_con_pin_errado_y_con_bloqueo` |
| Desviación | La especificación pide bloqueo al 5.º intento; el código bloquea al 3.º (más estricto, declarado en [`seguridad.md`](seguridad.md)). |

## 5. Acta de conformidad (plantilla)

Documento formal de aprobación funcional del sprint. **Sin firmar**: no hay PO
designado y no se ha hecho UAT con usuarios.

| Campo | Valor |
|---|---|
| Sprint / versión | — |
| Escenarios ejecutados | UAT-1, UAT-2, UAT-3 |
| Entorno | Local (emulador) / Producción (Render) |
| Ejecutó | — |
| Resultado por escenario | Aprobado / Observado / Rechazado |
| Discrepancias | — |
| Decisión del PO | Aceptar / Aceptar con observaciones / Rechazar |
| Firma y fecha | — |

## 6. Revisión entre pares del guion

Otro equipo ejecuta el guion y registra discrepancias. **No sustituye** pruebas
con usuarios representativos. Hoy: **pendiente**. Registrar el resultado aquí:

| Fecha | Equipo revisor | Escenario | Discrepancia | Resuelta |
|---|---|---|---|---|
| — | — | — | — | — |

## 7. Qué NO está validado (riesgo declarado)

| Qué | Por qué | Cómo cerrarlo |
|---|---|---|
| Las pantallas de los 3 escenarios | `verificacion-manual.md` nunca se ejecutó; sus pasos están **inferidos** del código | Ejecutar el guion en emulador y anotar el resultado |
| Aceptación por un usuario real | No hay PO ni sesión de UAT | Nombrar PO; 3–5 usuarios representativos ejecutan UAT-1 |
| Diálogo real de `local_auth` | Las pruebas usan `MemoryBiometricGate` | Prueba en un teléfono físico |
| 200 ms por transacción y 1.5 s de autenticación | Sin medición automatizada | Prueba de carga contra el despliegue |
| Tasa de éxito y tiempo de tarea (métricas UAT) | Sin sesión con usuarios | Medirlas en la sesión de UAT |

La automatización cubre el **servidor**: demuestra que las reglas se cumplen,
no que un usuario consiga completar la tarea. Por eso `Y = 1.00` (pruebas
verdes) no equivale a validación.

## 8. Próximos pasos (por costo/beneficio)

1. Ejecutar `verificacion-manual.md` en un emulador (cierra la mayor brecha E2E).
2. Designar PO y firmar la primera acta con UAT-1.
3. `ruff` en CI y 1 aprobación obligatoria en `main`.
4. Plantilla de PR con el checklist de reglas duras.
5. Revisión cruzada del guion con otro equipo y registro en §6.
