# Anexos

## Plan de cierre antes de la sustentación (viernes 06/11/2026)

| Actividad | Criterio | Responsable | Tarjeta |
|---|---|---|---|
| Asignar #2, #83, #90 y #104; revisión cruzada de PR | 4 | Jair Conislla y equipo | #105 |
| Aprobar el despliegue pendiente (PR #132 y PostgreSQL 18) y repetir el humo | 2, 5 | Andersson Espinoza | #127 |
| Corregir el secreto de firma, publicar `v0.3.0` e instalar desde Firebase | 5 | Jair Conislla | — |
| Sesión con 5 usuarios, SUS y tiempos de tarea | 3 | Jair Abdel Linares | #104 |
| UAT-1..3 en emulador y acta firmada | 1 | Gian Piero Gonzales | #97 |
| UAT en la nube con cuentas con KYC real | 5 | Andersson Espinoza | #102 |
| Recorrido de interfaz contra la nube | 5 | Jair Conislla | #112 |

## Enlaces a los scripts de automatización

| Qué | Enlace |
|---|---|
| Pruebas del backend | <https://github.com/Los-hijos-de-Rene/CuyCashUTP/tree/main/services/api/tests> |
| UAT automatizados | <https://github.com/Los-hijos-de-Rene/CuyCashUTP/blob/main/services/api/tests/test_aceptacion_uat.py> |
| Pruebas de la app | <https://github.com/Los-hijos-de-Rene/CuyCashUTP/tree/main/apps/mobile/test> |
| Usabilidad | <https://github.com/Los-hijos-de-Rene/CuyCashUTP/tree/main/apps/mobile/test/usabilidad> |
| Contrato app ↔ API | <https://github.com/Los-hijos-de-Rene/CuyCashUTP/tree/main/apps/mobile/contract_test> |
| Distribución del APK | <https://github.com/Los-hijos-de-Rene/CuyCashUTP/blob/main/.github/workflows/build-apk.yml> |
| Integración (PR #132) | <https://github.com/Los-hijos-de-Rene/CuyCashUTP/pull/132> |
| Humo en producción | <https://github.com/Los-hijos-de-Rene/CuyCashUTP/blob/main/services/api/scripts/smoke_prod.sh> |
| UAT en la nube | <https://github.com/Los-hijos-de-Rene/CuyCashUTP/blob/main/services/api/scripts/uat_prod.py> |
| Workflows de CI/CD | <https://github.com/Los-hijos-de-Rene/CuyCashUTP/tree/main/.github/workflows> |

## Corridas de CI citadas

| Corrida | Commit | Qué cubre |
|---|---|---|
| <https://github.com/Los-hijos-de-Rene/CuyCashUTP/actions/runs/41938696021> | `e226dd5` | Backend en PostgreSQL 16 |
| <https://github.com/Los-hijos-de-Rene/CuyCashUTP/actions/runs/41938776164> | `80ecb9b` | App, usabilidad y contrato |
| <https://github.com/Los-hijos-de-Rene/CuyCashUTP/actions/runs/41938359770> | PR #132 | Integración |

## Documentos de calidad

`docs/idoneidad-funcional.md` (RTM, ISO 25023) · `docs/vyv.md` (V&V, UAT) · `docs/compatibilidad-y-coexistencia.md` · `docs/plan-de-pruebas.md` · `docs/seguridad.md` · `docs/despliegue.md`.
