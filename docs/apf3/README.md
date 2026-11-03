# APF3 · Plan de trabajo del equipo

Entrega: **un PDF** con los capítulos A–E (guía en `apf3/APF3.pdf`). Este
directorio tiene un spec por tarjeta del tablero, para que cada integrante sepa
**qué entrega, cómo se prueba que está hecho y qué le van a preguntar**.

Tablero: <https://github.com/orgs/Los-hijos-de-Rene/projects/1> · etiqueta `apf3`.

## Mapa rúbrica → capítulo → dueño

| Criterio (pts) | Capítulo del PDF | Artefactos que exige | Tarjetas | Dueño |
|---|---|---|---|---|
| 1. Pruebas funcionales (4) | B | frameworks · casos · capturas · cobertura · métricas | #96, #97 | Gian Piero |
| 2. Integración (4) | C | sistemas externos · frameworks · casos · capturas · reportes · métricas | #100, #101, #103 | Jeremy, Andersson |
| 3. Usabilidad (4) | D | informe · frameworks · casos · capturas · reportes · métricas | #98, #99, #104 | Jheampierre, Jair L. |
| 4. Observaciones APF2 (4) | A | cuadro observación → evidencia | #105 | Jair C. |
| 5. Validación en la nube (2) | E | pruebas funcionales y de integración **en Render/Neon** | #102 | Andersson |
| 6. Sustentación (2) | — | aportes · orden · artefactos · demo v2 en la nube | #107 | todos |
| Consolidación del PDF | — | unir A–E | #106 | Jair C. |
| Evidencia automática (reportes en CI) | B, C, D | resultados y cobertura descargables | #110 | Jair C. |
| Contrato app ↔ backend real | C | interoperabilidad app ↔ API | #111 | Jair C. |
| E2E de interfaz contra la nube | E | validación en nube con automatización y usabilidad | #112 | Jair C. |
| Verificación estática (plantilla de PR, ruff) | B | verificación del modelo en V | #113 | Jair C. |

Specs: [Gian Piero](spec-gian-piero-funcionales.md) ·
[Jheampierre](spec-jheampierre-usabilidad-ui.md) ·
[Jeremy](spec-jeremy-integracion.md) ·
[Andersson](spec-andersson-cloud-y-coexistencia.md) ·
[Jair L.](spec-jair-linares-informe-usabilidad.md) ·
[Jair C.](capitulo-a-observaciones.md) ·
[esqueleto del PDF](esqueleto-pdf.md) · [sustentación](guion-sustentacion.md).

## Prioridad

Las tarjetas APF3 usan una **banda 0.x** del campo *Prioridad* (un número único
por tarjeta, menor = primero), por delante del backlog 1–27 de
[`gestion-del-equipo.md`](../gestion-del-equipo.md): son entregables de la
rúbrica. Orden: #96 (0.1) · #110 (0.15) · #98 (0.2) · #100 (0.3) · #111 (0.35) ·
#102 (0.4) · #112 (0.45) · #104 (0.5) · #97 (0.6) · #105 (0.7) · #99, #101, #103
(0.91–0.93) · #106 (0.95) · #107 (0.96) · #113 (0.97). Si el equipo prefiere
que el backlog funcional vaya primero, se renumera con una sola edición.
Donde los specs dicen P0/P1: P0 = prioridad 0.1–0.7 y 0.95–0.96; P1 = 0.91–0.93 y 0.97.

## Reglas para todos (no negociables)

1. **Cada quien hace y firma lo suyo.** Tu trabajo se sube con **tu** usuario de
   GitHub, en un PR tuyo. Nadie commitea con el nombre de otro ni mueve
   tarjetas ajenas: el tablero y el historial son la evidencia del capítulo A.
   Si trabajas en pareja, el commit lleva `Co-authored-by: Nombre <correo>`.
2. **Mueve tu tarjeta tú:** Ready → In progress (máx. 2 a la vez) → In review
   (al abrir el PR) → Done (al aprobarlo **otra persona**).
3. **Evidencia real:** las capturas y números salen de una corrida que tú hiciste,
   con fecha visible. Un resultado en rojo, bien explicado, vale más que uno
   inventado: el docente califica «métricas, cumplimiento y observaciones».
4. **Guarda tus archivos** en `docs/apf3/evidencias/<tu-nombre>/` (capturas
   `.png`, reportes `.txt/.xml/.html`). El PDF solo los enlaza y los inserta.
5. **Si te bloqueas más de medio día**, avisa en la tarjeta (comentario). Se
   reasigna o se pide ayuda de forma explícita; no se hace «por debajo».
6. Cada PR: `flutter analyze` sin issues, `pytest`/`flutter test` en verde.

## Plantilla de caso de prueba (usar en todos los capítulos)

| ID | Requisito / criterio | Precondición | Pasos | Resultado esperado | Archivo y nombre de la prueba | Resultado (✅/❌) | Evidencia |
|---|---|---|---|---|---|---|---|

## Plantilla de métricas

- **Casos:** total · aprobados · fallidos · omitidos.
- **Cumplimiento** = aprobados ÷ total (en %). Meta declarada: ≥ 90 %.
- **Cobertura** de líneas (backend y app), con el comando que la generó.
- **Observaciones:** hallazgos, defectos corregidos y riesgos que quedan.

## Calendario sugerido (ajustar a la fecha real de entrega)

| Cuándo | Qué |
|---|---|
| Día 1–2 | Cada dueño corre la línea base (`pytest`, `flutter test`) y guarda capturas |
| Día 3–5 | Se escriben/ejecutan las pruebas de cada tarjeta P0 |
| Día 6 | Capítulos redactados; Jair C. empieza a consolidar |
| Día 7 | Tarjetas P1; revisión cruzada de PR |
| Día 8 | PDF completo, ensayo de sustentación con la v2 en la nube |

## Hallazgos que ya salieron (ejemplos para el capítulo de observaciones)

- **UX-02 · botón «volver» del login sin etiqueta** para lectores de pantalla:
  lo detectó `test/usabilidad/login_usabilidad_test.dart` y se corrigió con un
  `tooltip` («Volver», clave `commonBack`). Es el patrón esperado: la prueba
  encuentra, se documenta y se corrige.
