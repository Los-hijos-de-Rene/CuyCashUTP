# D. Evaluación de la usabilidad  _(Jheampierre #98, #99 · Jair A. Linares #104)_

## D.1 Informe de evaluación de usabilidad
PENDIENTE — heurísticas de Nielsen, 5 usuarios, SUS, tiempos de tarea (`docs/usabilidad.md`).

## D.2 Frameworks
`flutter_test` con las *guidelines* de accesibilidad (`androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`), `bloc_test`, dobles `Memory*`. Límite: no mide aprendizaje humano (eso es D.1).

## D.3 Casos de prueba de interfaz y usabilidad
Modelo existente: `apps/mobile/test/usabilidad/login_usabilidad_test.dart` (UX-01..04). Resto de pantallas: PENDIENTE.

**Hallazgo ya resuelto (UX-02):** el botón «volver» del login no tenía etiqueta para lectores de pantalla; lo detectó la prueba y se corrigió con `tooltip` (`commonBack`).

## D.4 Capturas · D.5 Reportes · D.6 Métricas y observaciones
PENDIENTE — corrida de la suite, tabla de resultados por caso, % de cumplimiento, hallazgos y su corrección.
