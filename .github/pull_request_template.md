## Qué cambia y por qué
<!-- 2–3 líneas. Enlaza la tarjeta: "Cierra #N" -->

## Tarjeta y rúbrica
- Tarjeta: #
- Criterio que alimenta (si es APF3): B funcionales · C integración · D usabilidad · E nube

## Verificación (marca lo que ejecutaste; pega el resultado si falla algo)
- [ ] `flutter analyze` sin issues (si tocaste la app)
- [ ] `flutter test` / `pytest` en verde
- [ ] `ruff check` sin errores (si tocaste el backend)
- [ ] Cada CA que cierra tiene prueba automatizada, positiva y negativa

## Interfaz (obligatorio si tocaste pantallas)
- [ ] Adjunté capturas **antes/después** de cada pantalla cambiada
- [ ] El revisor comparó las capturas contra los tokens de `design_system`
- [ ] Probé con texto al 200 % y en pantalla de 320×568: sin desbordes
- [ ] Los estados vacío, carga y error tienen mensaje accionable (sin códigos técnicos)
- [ ] `flutter test test/usabilidad` en verde (o actualicé la suite y sus hallazgos)

## Reglas duras de CLAUDE.md
- [ ] Errores como valores (`Either` + `GlobalFailure`); ningún `throw` cruza capas
- [ ] Estados sealed + `switch` exhaustivo; sin `when`/`maybeWhen`/`!`
- [ ] Dinero como `int` de céntimos (`Money`); ningún `double`
- [ ] Toda escritura de dinero pasa por `ledger.py` y lleva `idempotency_key`
- [ ] Colores y tipografía solo desde `design_system`; copy es-PE en ARB

## Autoría y revisión
- [ ] Lo hizo y lo firma quien tiene la tarjeta (coautores con `Co-authored-by`)
- [ ] Lo revisa **otra persona** (la tarjeta pasa a *In review* al abrir este PR)
