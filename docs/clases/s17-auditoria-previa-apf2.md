# Sesión 17 — Recapitulación Unidad 2 y auditoría previa a APF2
PDF: `apf2/clases/diapositiva17.pdf` · Production Readiness Review

**Logro:** auditar la arquitectura integral (front, back, BD, pruebas, cloud v1) contra la rúbrica APF2.

## Arquitectura de referencia
SPA front ↔ HTTPS/JSON + Bearer JWT ↔ API Gateway/WAF (CORS, TLS, rate limit) ↔ Back-End (Clean Arch, JWT, DTOs) ↔ BD PostgreSQL (pool, ACID). Front consume solo la API pública. Pipeline = fuente de verdad.

## 5 pilares obligatorios
1. **Persistencia:** pool activo, migraciones, transacciones ACID.
2. **Seguridad:** JWT + expiración, BCrypt, RBAC funcional, CORS estricto.
3. **Pruebas:** unitarias de lógica, integración de APIs, mocking de DAO, ≥ 70 % cobertura.
4. **Despliegue:** PaaS/cloud v1, CI/CD activo, secretos seguros, URL pública.
5. **Demo viva:** historias de usuario, flujo E2E real, cero datos dummy, rollback listo.

**Rechazo inmediato:** demo desde `localhost`. Código debe reflejar el OpenAPI/Swagger.

## Errores críticos a evitar
Cold start de PaaS gratuito (precalentar), secretos en Git, CORS mal puesto, participación asimétrica, BD vacía sin casos realistas, devolver siempre 200 ignorando 4xx/5xx.

## Taller
Auditoría cruzada de URL pública (autenticarse, crear registro, forzar 400); check verde en `main`; ensayo de demo de 10 min (3 arq + 5 demo + 2 conclusiones).

## En CuyCash
Render plan Free se duerme a los 15 min (~1 min en despertar): calentar antes del demo. Smoke: `services/api/scripts/smoke_prod.sh`. Matriz: `docs/apf2-cumplimiento.md`.
