# Sesión 15 — Validación del servicio y estrategias de pruebas
PDF: `apf2/clases/diapositiva15.pdf` · Alimenta APF2 criterio 3

**Logro:** estrategia de pruebas automatizadas (unitarias + integración) sobre la API back-end.

## Conceptos
- Verificación («construir bien») vs validación («el producto correcto»). Costo de corregir bugs crece exponencialmente.
- **Exigencia central de APF2:** endpoints con pruebas de integración **pasando en GitHub Actions**.
- **Pirámide de Fowler:** ~70 % unitarias (sin BD ni red), ~20 % integración/APIs, ~10 % E2E.
- **TDD:** Red → Green → Refactor. Código no testeable = mal diseño.
- **Test doubles:** Mock (verifica llamadas), Stub (respuestas fijas), Spy.
- **Integración REST:** nunca contra la BD de producción; usar Testcontainers/Docker efímero o BD en memoria; cada prueba limpia sus datos. Verificar códigos HTTP (200/201/400/401/404), esquema del JSON, payloads corruptos.
- **Cobertura:** > 70 % en servicios críticos, pero medir comportamiento real, no líneas triviales.

## Taller pedido
≥ 3 unitarias de dominio con mocks del repo; integración de login y un POST (código + token); reporte de cobertura > 70 %.

## En CuyCash
Ver `docs/plan-de-pruebas.md`. Backend: `services/api` con pytest (SQLite; Postgres 16 real en CI, ver CLAUDE.md). App: `flutter test --coverage`.
