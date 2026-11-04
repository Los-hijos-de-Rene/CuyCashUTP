# A. Levantamiento de observaciones del APF2

**Observación recibida en la sustentación:** usar bien la metodología de trabajo
con GitHub Projects, asignando a cada integrante sus tareas y su prioridad por niveles.

| # | Requisito | Antes | Acción | Evidencia | Estado |
|---|---|---|---|---|---|
| 1 | Cada tarea con responsable | 35 de 35 ítems sin *Assignee* | Un dueño por ítem, revisor distinto; tarjetas APF3 #96–#113 con dueño | Captura de la vista *Table* (columna Assignees) — PENDIENTE | 🟡 |
| 2 | Prioridad por niveles | Campo *Priority* sin opciones | Campo **Nivel de prioridad** (P0 Crítica / P1 Alta / P2 Media) en los 43 ítems comprometidos, más número único de orden | Captura agrupada por *Nivel de prioridad* — PENDIENTE | ✅ |
| 3 | Todos avanzan | 294 de 294 commits de una cuenta | Spec por integrante; límite de 2 en curso; PR de cada integrante a `main` | Tabla «Autoría» de abajo (corte 2026-11-04) | 🟡 4 de 6 con PR fusionado; 0 PR con revisión de otra persona |
| 4 | Estado, tamaño, estimación, sprint | Campos vacíos | *Size* en todo; *Estimate* en días (S 1, M 2½, L 5); *Sprint* 5 y 6; 16 tarjetas APF3 en Sprint 6 | Captura de *Roadmap* — PENDIENTE | 🟡 |

## Autoría (corte 2026-11-04, `gh pr list` y `git shortlog`)

| Integrante | PR fusionados desde el 30/10 (APF3) | Commits desde el 30/10 | PR abiertos |
|---|---|---|---|
| Jair Conislla | 9 | 30 | — |
| Andersson | 4 (#121, #122, …) | 14 | — |
| Jheampierre | 3 (#123, #124, #125) | 4 | — |
| Gian Piero | 1 (#120) | 2 | — |
| Jeremy | 0 | 0 | #126 (CI en rojo, comentarios dejados) |
| Jair Abdel Linares | 0 | 0 | sin acceso al repositorio aún |

Reparto: Jair C. concentra 9 de 17 PR (53 %) en APF3; en todo el historial son 47 de 55 (85 %). La meta del equipo es ≤ 40 % (`gestion-del-equipo.md`): **no se cumple todavía** y se declara.

**Revisión por otra persona:** los 6 PR de los demás integrantes (#120–#125) se fusionaron con **0 revisiones** registradas en GitHub. Se declara como brecha: la regla de `main` exige solo el CI, no una aprobación. Acción: revisión cruzada documentada antes de la entrega.

**Porcentaje levantado:** PENDIENTE (se declara al entregar; no se afirma 100 % con filas 🟡).

Detalle y comandos para recalcular la evidencia: `docs/apf3/capitulo-a-observaciones.md`.
