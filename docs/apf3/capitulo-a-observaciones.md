# Capítulo A · Levantamiento de observaciones del APF2

Tarjeta **#105** (Jair C.). Rúbrica: 4 pts; 100 % = 4. El docente califica por el
porcentaje de observaciones levantadas **con evidencia técnica**.

## Observación recibida (sustentación del APF2)
Una sola: **usar bien la metodología de trabajo con GitHub Projects**, asignando
a cada integrante sus tareas y su prioridad por niveles.

Se desglosa en cuatro requisitos verificables; cada uno lleva su evidencia:

| # | Requisito de la observación | Estado antes (diagnóstico, `gestion-del-equipo.md` §1) | Acción | Evidencia a mostrar | Estado |
|---|---|---|---|---|---|
| 1 | Cada tarea tiene **responsable** | 35 de 35 ítems sin *Assignees* | Todo ítem con dueño (uno por ítem) y revisor distinto; tarjetas APF3 #96–#113 con dueño | Vista *Table* con columna Assignees; ítems sin dueño = 0 salvo los que esperan alta (#104) | 🟡 Ver «Pendientes» |
| 2 | **Prioridad por niveles** | Campo *Priority* sin opciones (y de plantilla: GitHub no deja editarlo) | Campo propio **Nivel de prioridad** con P0 · Crítica / P1 · Alta / P2 · Media, aplicado a los 43 ítems comprometidos (30 P0, 8 P1, 5 P2); además el número único de orden (*Prioridad*) | Vista *Table* agrupada por *Nivel de prioridad* | ✅ Aplicado 2026-11-02 |
| 3 | **Todos** avanzan y lo reflejan | 294 de 294 commits y 38 de 38 PR de una cuenta | Spec por integrante con su entregable; límite de 2 en curso; el PR lo aprueba otra persona | `git shortlog -sne`, PR por autor, historial de movimiento de tarjetas | 🟡 Se cierra con los PR reales de cada integrante |
| 4 | Estados, tamaño y sprint al día | *Size*, *Estimate*, fechas y *Sprint* vacíos; Backlog sobre su límite | *Size* y estado en todas las tarjetas; Sprints 5 y 6 en `gestion-del-equipo.md` | Vista *Board* con columnas y vista *Roadmap* | 🟡 *Estimate*/fechas/*Sprint* sin llenar |

**Porcentaje levantado:** se declara al entregar con este cuadro actualizado. No
se afirma 100 % mientras alguna fila siga en 🟡 o ⏳: es mejor decir «3 de 4
requisitos» con evidencia que prometer lo que el tablero no muestra.

## Pendientes antes de entregar
1. Sin dueño quedan #104, #83 y #90 (esperan que Jair L. sea colaborador) y las
   épicas/propuestas (#44–#49, #74, #75), que se ordenan por sus tareas. #89 y
   #50 se asignaron según el plan de `gestion-del-equipo.md`.
2. Crear una vista *Table* agrupada por *Nivel de prioridad* y guardarla (para la captura).
3. Que cada integrante tenga al menos un PR propio aprobado por otra persona.
4. (Opcional) *Sprint* con iteraciones y fechas para que el *Roadmap* muestre barras.

## Cómo recalcular la evidencia el día de la entrega
```sh
git shortlog -sne origin/main
gh pr list -R Los-hijos-de-Rene/CuyCashUTP --state merged --limit 200 --json author \
  -q 'group_by(.author.login)|map({autor:.[0].author.login,prs:length})'
gh project item-list 1 --owner Los-hijos-de-Rene --limit 200 --format json   # assignees, status, priority
```
Pega el resultado en el PDF con su fecha.

## Capturas a tomar
1. *Board* con columnas y asignados visibles.
2. *Table* con Assignees, Priority, Size y Prioridad.
3. Una tarjeta abierta con su spec y su historial.
4. Lista de PR cerrados por autor y `git shortlog`.
