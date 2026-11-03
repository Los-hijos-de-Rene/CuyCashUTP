# Anexos

## Enlaces a los scripts de automatización (repositorio)
| Qué | Dónde |
|---|---|
| Pruebas del backend (API, seguridad, concurrencia) | `services/api/tests/` |
| UAT automatizados | `services/api/tests/test_aceptacion_uat.py` |
| Pruebas de la app (unitarias, bloc, widgets) | `apps/mobile/test/` |
| Usabilidad (UI) | `apps/mobile/test/usabilidad/` |
| Contrato app ↔ API | `apps/mobile/contract_test/` |
| Humo en producción | `services/api/scripts/smoke_prod.sh` |
| CI/CD | `.github/workflows/ci.yml`, `cd-backend.yml`, `rollback-backend.yml`, `seguridad.yml` |
| Reportes de CI | artefactos `reportes-backend`, `reportes-app`, `reporte-contrato` de cada corrida |

## Documentos de calidad
`docs/idoneidad-funcional.md` (RTM, ISO 25023) · `docs/vyv.md` (V&V, UAT) · `docs/compatibilidad-y-coexistencia.md` · `docs/plan-de-pruebas.md` · `docs/seguridad.md` · `docs/despliegue.md`.
