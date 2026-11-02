# Spec · Jair Abdel Linares · Informe de evaluación de usabilidad (capítulo D)

Tarjeta **#104** (P0, M) · Revisor: Jheampierre · Criterio 3 (4 pts): es el
**artefacto 1 de 6** («Informe de evaluación de usabilidad»); sin él el capítulo
pierde un punto.

> **Antes de empezar:** pide a Jair C. que te invite como colaborador del repo
> y que te asigne la tarjeta. Tu trabajo es **humano** (usuarios reales); el de
> Jheampierre es automatizado. Se complementan.

## Qué se te pide
Un informe de 3–5 páginas que evalúe la usabilidad de CuyCash con método, datos
y conclusiones. Plantilla propia en `docs/usabilidad.md` (tú la creas).

## Método (hazlo en este orden)
1. **Evaluación heurística (Nielsen).** Recorre la app (flavor `mock`, PIN `000000`)
   y puntúa las 10 heurísticas de 0 (sin problema) a 4 (catastrófico) con 1
   ejemplo de pantalla cada una. Es lo que pide la sesión 23 (`docs/clases/s23-usabilidad.md`).
2. **Taller de la clase: 2 puntos de error + control de prevención** en el flujo
   «enviar dinero». Ejemplos que ya existen en la app: PIN de confirmación,
   nombre del destinatario enmascarado, mismo tipo de moneda obligatorio. Añade
   los tuyos (¿qué pasa si confundo DNI con alias? ¿y si me equivoco de monto?).
3. **Sesión con 5 usuarios** (compañeros o familiares que no vieron la app):
   - Tarea 1: registrarse/ingresar. Tarea 2: ver su saldo. Tarea 3: enviar S/ 10 a otra cuenta.
   - Por tarea mide: **¿completó sin ayuda?** (sí/no), **tiempo** (cronómetro), **errores** (nº de toques equivocados).
   - Dales un teléfono con la app y no expliques nada. Observa y anota.
4. **Encuesta SUS** (10 preguntas, escala 1–5) a esos mismos 5. Fórmula:
   impares: (puntaje − 1); pares: (5 − puntaje); suma × 2.5 → 0–100. Meta: ≥ 68
   (promedio de la industria). Hoja de cálculo en `evidencias/jair-linares/`.
5. **Curva de aprendizaje:** compara el tiempo de la tarea 3 de cada usuario en
   su 1.er y 2.º intento (que la repitan una vez más).

## Estructura del informe
1. Objetivo y alcance · 2. Método y participantes (perfil, sin nombres reales
si prefieren) · 3. Resultados: tabla de tareas (éxito %, tiempo medio, errores),
SUS, heurísticas · 4. Hallazgos priorizados (qué cambiar primero) ·
5. Relación con las pruebas automatizadas de Jheampierre ·
6. Limitaciones (muestra de 5, no representativa de toda la población).

## Métricas a reportar
- Tasa de éxito por tarea (meta ≥ 80 %), tiempo medio, errores medios.
- Puntaje SUS medio (meta ≥ 68). Mediana y rango.
- Nº de hallazgos por gravedad.

## Hecho cuando
- [ ] `docs/usabilidad.md` con las 6 secciones.
- [ ] Datos crudos (hoja de tareas y SUS) en `evidencias/jair-linares/`.
- [ ] Fotos o capturas de la sesión (sin rostros ni datos personales).
- [ ] Al menos 3 hallazgos con propuesta de mejora; avisa a Jheampierre para
      convertirlos en pruebas.

## Te van a preguntar
- ¿Qué es SUS y qué significa 68?
- ¿Por qué 5 usuarios? (Nielsen: ~85 % de los problemas con 5, pero no es muestra estadística)
- ¿Qué mejorarías primero y por qué?
