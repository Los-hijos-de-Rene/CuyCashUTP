# Sesión 20 — Verificación y Validación funcional (V&V)
PDF: `apf2/clases/diapositiva20.pdf` · Alimenta APF3

**Logro:** plan de V&V basado en el modelo en V, con casos funcionales y UAT.

## Conceptos
- Estándar IEEE 1012. **Verificación** = ¿construimos bien? (revisiones, análisis estático/SonarQube, unitarias, linters; responsable: dev y QA; continua). **Validación** = ¿construimos lo correcto? (UAT, usabilidad con usuarios, beta; responsable: PO/stakeholders; en hitos).
- **Modelo en V:** requerimientos de negocio ↔ UAT; arquitectura ↔ integración; diseño modular ↔ unitarias. Guía conceptual, no ciclo rígido. En UAT los usuarios validan; aceptar/desplegar lo decide el responsable del producto.
- Riesgos: omitir validación → producto impecable pero inútil; omitir verificación → satisface pero colapsa.
- Verificación estática: PR audits con checklist, linters/SAST (requieren revisión; no garantizan ausencia de defectos), control de dependencias circulares (ArchUnit).
- UAT: guion de casos con datos representativos, criterios de éxito (tiempo y tasa de éxito sin ayuda), **acta de conformidad**.

## Taller pedido
3 escenarios UAT (precondición, pasos, resultado esperado); reglas de linter y criterios de bloqueo de merge; otro equipo ejecuta el guion y registra discrepancias (no sustituye usuarios reales).

## En CuyCash
`docs/verificacion-manual.md` (guion; pasos de pantalla inferidos del código, nunca ejecutado en emulador) y `docs/plan-de-pruebas.md`. `flutter analyze` en cero es la verificación estática.
