# Spec · Andersson · Validación en la nube y coexistencia

Tarjetas **#102** (P0, M) y **#103** (P1, S) · Revisor: Jeremy · Criterio 5
(2 pts, validación en Cloud) + coexistencia del criterio 2.

## Qué se te pide
**#102.** Probar que la **v2 en producción** (Render + Neon) funciona: pruebas
funcionales y de integración corridas **contra la URL pública**, no contra
localhost (el docente lo penaliza). Evidencia con capturas y tabla.

**#103.** Cerrar brechas de coexistencia ya identificadas en
[`compatibilidad-y-coexistencia.md`](../compatibilidad-y-coexistencia.md) §6.

## #102 · paso a paso
1. **Precalienta.** El plan gratuito duerme: `curl https://cuycashutp.onrender.com/health`
   y espera hasta 1 min. Anota el commit que devuelve (`version`).
2. **Humo (solo lectura):** `services/api/scripts/smoke_prod.sh`. Captura toda la salida.
3. **Funcional contra la nube.** Crea `services/api/scripts/uat_prod.py` que, con
   `httpx` y `BASE_URL`, ejecute **UAT-1 y UAT-2** (`tests/test_aceptacion_uat.py`
   es el modelo): registrar dos usuarios de prueba, depositar, enviar, ver
   movimientos, intentar sin saldo. Reglas: usuarios con DNI de prueba
   reservados (documéntalos), PIN no real, nada de datos de personas reales.
   **Pregunta al equipo antes de escribir en producción**; si prefieren no
   ensuciar la base, ejecuta contra una rama de Neon.
4. **Integridad del libro mayor en Neon.** Consulta SQL de `services/api/scripts/monitoreo.sql`:
   suma de débitos = suma de créditos. Captura el resultado en el panel de Neon.
5. **Seguridad de borde:** HTTP→HTTPS 301, cabeceras, ruta sin token → 401
   (ya en el humo). Añade una prueba con **datos inválidos** (DNI de 7 dígitos → 422).
6. **Pipeline:** captura la última corrida de `cd-backend.yml` (aprobación en
   `production`) y `GET /health` mostrando el commit desplegado.
7. **App → nube:** instala el APK de producción, haz un envío y captura la
   pantalla de detalle y la fila en Neon (como en `apf2/capturas/22` y `23`).

Entregable: `docs/apf3/evidencias/andersson/` + capítulo E (1–2 páginas):
URL, commit, tabla de verificaciones (esperado/obtenido), capturas, observaciones
(cold start, latencia medida).

## #103 · coexistencia (acciones 1 y 4 de §6)
| Cambio | Archivo | Prueba de que funciona |
|---|---|---|
| Proceso sin root | `services/api/Dockerfile` (`RUN useradd -r app` + `USER app`) y `.dockerignore` | `docker build` y `docker run … whoami` ≠ root; `/health` responde |
| Tope de memoria | `docker-compose.yml`: `mem_limit: 512m` en `auth` | `docker stats` |
| Pool de conexiones | `app/db/base.py`: `pool_size`/`max_overflow` por variable de entorno, ajustados al límite de Neon ÷ instancias | Test que lee los valores |

**Cuidado:** no despliegues sin probar la imagen (`despliegue.md`); el deploy
solo sale por GitHub Actions con aprobación. Si Docker no está instalado, dilo
en la tarjeta: no se puede marcar hecho sin probarlo.

## Hecho cuando
- [ ] Capítulo E con humo, UAT contra la nube, SQL de cuadre y capturas.
- [ ] `/health` en la captura muestra el commit de la v2 que se defenderá.
- [ ] #103 con prueba de la imagen o declarada como no probada.

## Te van a preguntar
- ¿Qué pasa si Render se duerme durante la demo? (precalentar; plan B: capturas)
- ¿Cómo sabes que el cuadre del libro mayor es correcto? (partida doble, `ledger.py`)
- ¿Por qué no se despliega a mano? (CD con aprobación y rollback)
