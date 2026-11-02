# Notas de clase — Curso Integrador II: Software

Docente: Dr. Carlos R. P. Tovar. Destiladas de `apf2/clases/*.pdf` (diapositivas
13–23). **Leer este índice primero; abrir una nota solo si aplica; no leer los PDF.**
Si una nota no basta (tabla, diagrama), recién ahí abrir el PDF indicado.

| Sesión | PDF | Tema | Alimenta | Nota |
|---|---|---|---|---|
| 13 | `diapositivas13.pdf` | Seguridad: CIA, AuthN/AuthZ, JWT, OWASP, hashing, secretos | APF2 c.2 | [s13](s13-seguridad-controles.md) |
| 14 | `diapositivas14.pdf` | TLS, CORS, CSP/XSS, logs/correlation ID, rate limit, WAF | APF2 c.2 | [s14](s14-defensa-trazabilidad.md) |
| 15 | `diapositiva15.pdf` | Pirámide de pruebas, TDD, integración, cobertura ≥70 % | APF2 c.3 | [s15](s15-pruebas.md) |
| 16 | `diapositiva16.pdf` | CI/CD, Blue-Green/Canary, rollback, health check | APF2 c.4 | [s16](s16-cicd-despliegue.md) |
| 17 | `diapositiva17.pdf` | Auditoría previa a APF2 (5 pilares, errores críticos) | APF2 | [s17](s17-auditoria-previa-apf2.md) |
| 18 | `diapositiva18.pdf` | Rúbrica APF2 (20 pts) y protocolo de sustentación | APF2 | [s18](s18-rubrica-apf2.md) |
| 19 | `diapositiva19.pdf` | ISO 25010 Idoneidad funcional, ISO 25023, RTM | APF3 | [s19](s19-idoneidad-funcional.md) |
| 20 | `diapositiva20.pdf` | V&V, modelo en V, UAT, verificación estática | APF3 | [s20](s20-vyv.md) |
| 21 | `diapositiva21.pdf` | ISO 25010 Compatibilidad / interoperabilidad | APF3 | [s21](s21-compatibilidad.md) |
| 22 | `diapositiva22.pdf` | ISO 25010 Coexistencia | APF3 | [s22](s22-coexistencia.md) |
| 23 | `diapositiva23.pdf` | ISO 25010 Usabilidad | APF3 | [s23](s23-usabilidad.md) |

Resumen de lo exigible, con su fuente: [requisitos-del-curso.md](requisitos-del-curso.md).

## Dónde vive cada cosa en el proyecto
Los documentos de entrega siguen en `docs/` (no se duplican aquí):
`apf2-cumplimiento.md` (matriz APF2), `seguridad.md`, `catalogo-controles.md`,
`plan-de-pruebas.md`, `despliegue.md`, `administracion-bd.md`,
`idoneidad-funcional.md` (RTM, ISO 25023), `vyv.md` (plan de V&V, UAT, acta; sesión 20),
`compatibilidad-y-coexistencia.md` (auditoría de las sesiones 21 y 22).

## Cómo mantener esto
- Cada nota: «Qué pide la clase» + conceptos + taller + «En CuyCash» (enlaces).
- Si el docente agrega diapositivas 24+, añadir fila aquí y su nota.
- Las diapositivas 1–12 no están en `apf2/clases`; no hay notas de ellas.
