# Sesión 18 — Evaluación APF2: producción v1 y validación
PDF: `apf2/clases/diapositiva18.pdf`

**Peso:** 20 % del promedio final. Habilita la Unidad 3 (ISO 25010).

## Rúbrica (20 pts = 5 × 4)
| Criterio | Elementos |
|---|---|
| 1. Datos | DAO/Repo, pool activo, transacción ACID |
| 2. Seguridad | AuthN/JWT, AuthZ/RBAC, BCrypt hash, OWASP Top 10 |
| 3. Pruebas | Unitarias, integración, mocking, ≥ 70 % cobertura |
| 4. Cloud v1 | URL pública, CI/CD, cero downtime, health check |
| 5. Dominio | Demo fluida, defensa individual, preguntas, documentación |

## Protocolo (15 min)
Arquitectura 3 min (diagrama C4 y componentes) → demo en vivo desde URL pública 6 min → preguntas y código 4 min → feedback 2 min. **A los 9 min se corta la exposición** y pasa a la auditoría. Preguntas directas a cualquier integrante (autoría y dominio).

## Qué se audita en caliente
- Consultas SQL con prepared statements (cero concatenación).
- Middleware de autenticación: verificación del JWT y extracción del rol.
- Pruebas sin `@Disabled`/`skip`.
- Resiliencia: datos inválidos desde el front; ruta protegida sin `Authorization` → **401**.
- Historial de GitHub Actions (builds continuos).
- Se abre la URL en pestaña incógnito.

## En CuyCash
Matriz de cumplimiento: `docs/apf2-cumplimiento.md`.
