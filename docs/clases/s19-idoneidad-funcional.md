# Sesión 19 — ISO 25010: Idoneidad funcional
PDF: `apf2/clases/diapositiva19.pdf` · Inicio de Unidad 3 · Alimenta APF3

**Logro:** evaluar calidad funcional con métricas ISO/IEC 25023 sobre las HU del proyecto.

## Conceptos
- Subcaracterísticas: **Completitud** (¿cubre todos los requisitos?), **Corrección** (¿cálculos exactos?), **Idoneidad/pertinencia** (¿ayuda al usuario a su tarea?). Completitud mide «cuánto se hizo»; idoneidad «qué tan útil es».
- Flujo: Requisito/US → especificación BDD (Given/When/Then) → implementación → oráculo de prueba. Trazabilidad bidireccional requisito ↔ código ↔ caso de prueba (**RTM**).
- **Completitud X = funciones implementadas y probadas / funciones especificadas**, objetivo ≥ 0.95.
- **Indicador de pruebas aprobadas Y = aprobadas / ejecutadas.** Es de proceso; la corrección real exige oráculos y revisión de defectos críticos.
- Cada US: al menos un test positivo y uno negativo. Precisión numérica: redondeos monetarios, transiciones de estado válidas (evitar `0.1+0.2 != 0.3`).
- Idoneidad de la tarea: sin pasos redundantes, valores por defecto coherentes, errores en lenguaje del usuario (no trazas de BD).

## Taller pedido
RTM de 5 HU principales vs endpoints y pruebas; auditoría de precisión decimal; índice de completitud ISO 25023 de v1 vs alcance planificado.

## En CuyCash
Ya hecho: `docs/idoneidad-funcional.md` (RTM por CA contra 26 HU, solo cuenta con prueba automatizada). Dinero = `int` de céntimos / `Money` (regla dura 10).
