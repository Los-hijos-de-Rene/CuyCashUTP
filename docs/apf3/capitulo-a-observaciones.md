# Capítulo A · Levantamiento de observaciones del APF2

Tarjeta **#105** (Jair C.). Rúbrica: 4 pts; 100 % = 4, 80 % = 3, 50 % = 2.
El docente califica por el **porcentaje de observaciones levantadas con
evidencia**, así que el cuadro debe listarlas todas, cada una con su prueba.

> **Pendiente de Jair C.:** completar la columna «Observación textual» con lo
> que el docente dijo en la sustentación del APF2 (acta o feedback en el aula
> virtual). Las filas marcadas ⚠ son mías inferidas del repo y deben
> confirmarse; no entregues el cuadro sin ese paso.

## Cuadro resumen

| # | Observación (APF2) | Causa | Acción tomada | Evidencia técnica | Estado |
|---|---|---|---|---|---|
| 1 | Trabajar con **GitHub Projects** y que **todos** los integrantes registren sus avances | El historial mostraba 294/294 commits de una cuenta y 35/35 tarjetas sin responsable (`docs/gestion-del-equipo.md` §1) | Tablero con responsables, prioridad, tamaño y estado; 12 tarjetas APF3 (#96–#107) con dueño y spec; reglas de autoría (`docs/apf3/README.md`); límite de WIP; PR revisado por otra persona | Tablero del proyecto; `git shortlog -sne`; PR por autor; captura del tablero con asignados | 🟡 En curso — se cierra con los **commits y PR reales de cada integrante** al entregar |
| 2 ⚠ | Evidencia de pruebas (unitarias e integración con cobertura) | — | Capítulos B y C con cobertura y reportes | `docs/apf3/evidencias/`, CI | 🟡 |
| 3 ⚠ | Despliegue sin localhost, con pipeline y rollback | — | CD con aprobación, rollback, `/health` con commit | `apf2/capturas/01–18` | ✅ |
| 4 ⚠ | Seguridad web documentada | — | ZAP, cabeceras, `seguridad.md` | `apf2/capturas/19–20` | ✅ |

## Cómo se cierra la fila 1 con honestidad
Hoy el tablero tiene dueños, pero el historial de código sigue concentrado.
Para que la fila sea ✅ **no basta el tablero**: cada integrante debe tener, a la
entrega, al menos un PR propio aprobado por otra persona. Recalcula el día de la
entrega:

```sh
git shortlog -sne origin/main
gh pr list -R Los-hijos-de-Rene/CuyCashUTP --state merged --limit 200 --json author,number,title \
  -q 'group_by(.author.login)|map({a:.[0].author.login,n:length})'
gh project item-list 1 --owner Los-hijos-de-Rene --limit 200 --format json   # asignados y estado
```
Pega el resultado en el PDF como evidencia y di la cifra real, sea cual sea.
Si algún integrante no logra su aporte, el cuadro dice «🟡 parcial» y el motivo.

## Capturas a tomar
1. Tablero (vista *Board*) con columnas y asignados visibles.
2. Vista *Table* con campos Prioridad, Size y Assignees.
3. Una tarjeta abierta con su spec enlazado y el historial de movimiento.
4. Lista de PR cerrados por autor.
