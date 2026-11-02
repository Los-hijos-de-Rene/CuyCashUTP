# Sesión 23 — ISO 25010: Usabilidad
PDF: `apf2/clases/diapositiva23.pdf` (20 láminas, poco texto) · Alimenta APF3

## Conceptos
- Usabilidad = ser comprendido, aprendido y usado; foco en interacción, efectividad y eficiencia.
- **Facilidad de aprendizaje:** usuario nuevo domina lo básico sin manual. Estrategias: consistencia, onboarding (tooltips), patrones conocidos (carrito, lupa).
- **Protección contra errores:** prevención (deshabilitar botones hasta cumplir requisitos, input masks, confirmación «¿Está seguro?») y recuperación (mensajes claros que dicen qué pasó y cómo arreglarlo; undo/redo).
- Heurísticas de Nielsen (visibilidad del estado, coincidencia con el mundo real, control y libertad, prevención de errores). Consistencia visual y de comportamiento.
- Feedback: spinners, notificaciones éxito/error, progreso en formularios largos.
- Accesibilidad: contraste, lectores de pantalla, navegación por teclado.
- Evaluación: test con usuarios, heatmaps, encuesta **SUS**. Métricas: tiempo de tarea, tasa de errores, tiempo de aprendizaje.
- Diseño: minimalismo, jerarquía visual, espacio en blanco.

## Taller pedido
En el flujo principal: 2 puntos de error posible y un control de prevención para cada uno; ¿qué tan rápido aprende un usuario nuevo?

## En CuyCash
Ejemplos ya presentes: confirmación con PIN en envíos y apertura de cuentas, nombre enmascarado al resolver destinatario, onboarding, bloqueo por intentos. Copy es-PE en ARB; tokens de `design_system`. Sin pruebas con usuarios reales ni SUS (no medido).
