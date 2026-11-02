# Spec · Gian Piero · Pruebas funcionales (capítulo B)

Tarjetas **#96** (P0, M) y **#97** (P0, S) · Revisor: Jair C. · Criterio 1 de la
rúbrica (4 pts) + parte del criterio 5.

## Qué se te pide
El docente quiere ver **5 artefactos** de pruebas funcionales automatizadas que
validen completitud, corrección e idoneidad (ISO 25010). Tú armas el capítulo B
con material que **ya existe**; lo nuevo es ejecutarlo, capturarlo y medirlo.

| # | Artefacto | De dónde sale | Dónde lo dejas |
|---|---|---|---|
| 1 | Frameworks y por qué | `docs/plan-de-pruebas.md` §2 | Texto del capítulo (½ página) |
| 2 | Listado de casos | RTM de `docs/idoneidad-funcional.md` (26 HU, 96 CA) | Tabla con la plantilla del [README](README.md) |
| 3 | Capturas de ejecución | Tú corres los comandos de abajo | `evidencias/gian-piero/*.png` |
| 4 | Cobertura | `--cov` (backend) y `--coverage` (app) | `evidencias/gian-piero/cobertura-*` |
| 5 | Métricas, cumplimiento, observaciones | `idoneidad-funcional.md` §5 | Tabla de métricas |

## Paso a paso (#96)
1. **Línea base.** En `services/api`:
   ```sh
   .venv/bin/python -m pytest -q --cov --cov-report=term --cov-report=html:cov_html \
     --junitxml=../../docs/apf3/evidencias/gian-piero/pytest.xml
   ```
   Captura la terminal con el resumen y el % total. Abre `cov_html/index.html`
   y captura la tabla por módulo (no subas `cov_html/` al repo).
2. **App.** En `apps/mobile`: `flutter test --coverage` y luego
   `genhtml coverage/lcov.info -o coverage/html` (necesita `brew install lcov`).
   Captura el resumen y el % de líneas.
3. **Casos.** Del RTM, elige **al menos 20 CA** que cubran las 5 HU principales
   y rellena la tabla con *nombre exacto de la prueba* y su resultado real.
   Regla de la casa: un CA cuenta como cumplido **solo si tiene prueba
   automatizada** (`idoneidad-funcional.md`).
4. **Corrección (precisión numérica).** Incluye 3 casos de dinero en céntimos:
   `Money` sin `double`, el envío de S/ 125.50 y el cuadre débito = crédito del
   libro mayor (`test_libro_mayor.py`, `test_aceptacion_uat.py`).
5. **Métricas** (fórmulas de ISO 25023 ya en el documento): completitud
   `X = CA con prueba ÷ CA totales`, corrección `Y = pruebas verdes ÷ pruebas
   totales`. Cópialas **recalculadas hoy**, no las de octubre.
6. **Observaciones.** Escribe honestamente qué no cubre (p. ej. pantallas sin
   ejecutar en emulador, 200 ms sin medir). Eso suma, no resta.

## Paso a paso (#97 · UAT en emulador)
1. Levanta el entorno local: `cd services/api && docker compose up --build` y
   la app con el flavor `local` (comandos en `CLAUDE.md`).
2. Siembra datos: `docker compose exec auth python -m scripts.dev reset-y-seed`
   (Ana `11111111`, Luis `22222222`, PIN `258036`).
3. Ejecuta `docs/verificacion-manual.md` y los UAT-1..3 de `docs/vyv.md` §4.
   En cada paso anota ✅/❌ y **corrige el guion** donde dijera algo falso
   (los pasos de pantalla están «inferidos del código»).
4. Llena el acta de `vyv.md` §5 (escenarios, resultado, discrepancias).

## Hecho cuando
- [ ] Capturas de `pytest` y `flutter test` con fecha y total visibles.
- [ ] Reporte de cobertura de backend **y** app (HTML o tabla en el PDF).
- [ ] Tabla con ≥ 20 casos y resultado real; métricas X e Y recalculadas.
- [ ] UAT-1..3 ejecutados, acta llena, guion corregido.
- [ ] Sección «Observaciones» con al menos 3 limitaciones reales.

## Te van a preguntar
- ¿Por qué `pytest` sobre PostgreSQL 16 y no solo SQLite? (el bloqueo de fila no se prueba en SQLite)
- ¿Qué diferencia hay entre completitud y corrección?
- ¿Un 96 % de cobertura significa que no hay errores? (no: mide líneas ejecutadas, no calidad de las aserciones)
