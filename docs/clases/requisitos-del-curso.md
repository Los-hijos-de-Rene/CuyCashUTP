# Requisitos del curso (lo que se evalúa)

Fuente entre paréntesis = sesión. Es lo exigible; el detalle está en cada nota.

## APF2 — 20 pts, 20 % del promedio final (s18)
5 criterios × 4 pts. Sustentación grupal de 15 min, con evaluación individual.

| # | Criterio | Qué se mira |
|---|---|---|
| 1 | Datos | DAO/Repo, pool activo, transacciones ACID, migraciones, consultas con prepared statements (cero concatenación) |
| 2 | Seguridad | AuthN con JWT + expiración, AuthZ/RBAC, hash BCrypt/Argon2, mitigación OWASP Top 10, CORS estricto |
| 3 | Pruebas | Unitarias (lógica, con mocks) + integración de APIs, ≥ 70 % de cobertura en servicios críticos, sin `skip`/`@Disabled` |
| 4 | Cloud v1 | URL pública, pipeline CI/CD, cero downtime, health check, rollback |
| 5 | Dominio | Demo fluida, defensa individual, respuesta a preguntas, documentación |

**Rechazo inmediato:** demostrar desde `localhost` anula los puntos de despliegue (s17).

Protocolo (s18): arquitectura 3 min (C4 + componentes) → demo en vivo en la nube
6 min (a los 9 min se corta) → preguntas y código 4 min → feedback 2 min.
Demo desde la URL de producción en pestaña incógnito. El panel prueba: datos
inválidos desde el front, ruta protegida sin `Authorization` (esperado 401),
historial de GitHub Actions, revisión de SQL y del middleware JWT.

Otros requisitos de s17: código fiel al OpenAPI/Swagger; datos de prueba
realistas (no BD vacía); errores 4xx/5xx reales (no 200 siempre); todo el
equipo domina arquitectura y código; precalentar el PaaS gratuito (cold start).

## APF3 — Unidad 3, calidad ISO 25010 (s19–s23)
Alimentan el informe técnico y las evidencias de APF3. Sesiones vistas:
idoneidad funcional (RTM + ISO 25023), V&V (UAT), compatibilidad, coexistencia,
usabilidad. Cada una termina en un taller de auditoría por equipo.

## Entregables de taller que el docente pidió (por sesión)
- s13: flujo de autenticación + payload JWT + expiración; matriz RBAC de 3 roles; mitigación OWASP del framework.
- s14: dominios CORS exactos; herramienta de logs + ejemplo JSON de «error de autenticación»; endpoint crítico y su límite de tasa.
- s15: ≥ 3 pruebas unitarias con mocks; integración de login y de un POST; reporte de cobertura > 70 %.
- s16: `deploy.yml` en push a `main`; despliegue cloud con secretos; `/health` y simulacro de commit fallido.
- s17: auditoría cruzada de URL pública; check verde en `main`; ensayo de demo de 10 min (3 arq + 5 demo + 2 conclusiones).
- s19: RTM de 5 HU principales; auditoría de precisión numérica; índice de completitud ISO 25023.
- s20: 3 escenarios UAT; reglas de linter/bloqueo de merge; revisión cruzada del guion.
- s21: sistemas externos, riesgo de interoperabilidad de cada uno, plan de mitigación.
- s22: librerías en conflicto; control de memoria; ¿dos instancias en el mismo host?
- s23: 2 puntos de error posible + control de prevención; curva de aprendizaje.
