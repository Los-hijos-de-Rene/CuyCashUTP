# Guion de sustentación APF3 (#107)

Rúbrica (2 pts, −0.5 por indicación faltante): 1) aportes · 2) orden lógico y
síntesis · 3) sustentar los artefactos · 4) **demo de la v2 en la nube**.
Defensa **individual**: cada integrante debe saber explicar su parte.

## Orden (15 min, ajustar al tiempo que dé el docente)
| Min | Quién | Qué |
|---|---|---|
| 0–1 | Jair C. | Qué es CuyCash, qué hay en producción (v2) y qué se mide en APF3 |
| 1–3 | Jair C. | Observaciones de APF2 y cómo se levantaron: **mostrar el tablero** |
| 3–5 | Gian Piero | Pruebas funcionales: RTM, cobertura, métricas X e Y, UAT |
| 5–7 | Jeremy | Integración: sistemas externos, fallos simulados, contrato OpenAPI |
| 7–9 | Jheampierre + Jair L. | Usabilidad: defecto hallado y corregido (UX-02), SUS y tareas |
| 9–13 | Andersson | **Demo en vivo en la nube** (pestaña incógnito): `/health`, envío entre dos cuentas, cuadre en Neon |
| 13–15 | Jair C. | Limitaciones honestas y trabajo futuro |

## Antes de la demo
- Precalentar Render y el KYC 5 min antes. Tener datos de prueba realistas.
- Plan B: capturas y un video corto de la demo grabado antes.
- No demostrar desde `localhost` (anula los puntos de despliegue).
- Probar ruta protegida sin token (esperado 401) y datos inválidos (422).

## Preguntas que todos deben poder responder
1. ¿Qué cambió entre la v1 (APF2) y la v2 (APF3)?
2. ¿Qué probaron y qué **no** pudieron probar? (200 ms sin medir, huella real, KYC real en CI)
3. ¿Quién hizo qué? Cada uno muestra **su** PR.
4. ¿Cómo garantizan que el dinero cuadra? (partida doble, idempotencia, `ledger.py`)
5. ¿Qué defecto encontraron con las pruebas y cómo lo corrigieron?

## Verdad por delante
Declarar lo que no está probado es parte de la nota (métricas y observaciones).
Es mejor «no lo medimos, y este es el riesgo» que una cifra que no podemos defender.
