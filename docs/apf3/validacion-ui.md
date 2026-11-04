# Validación de interfaz y usabilidad (capítulo D)

Cómo se comprueba que una pantalla **funciona**, **es accesible**, **no rompe el
diseño** y **se entiende**. Cada capa responde una pregunta distinta y ninguna
sustituye a la otra.

| Pregunta | Capa | Automatizada | Quién la ejecuta |
|---|---|---|---|
| ¿Funciona? (navega, habilita, valida) | Widget tests | Sí | CI |
| ¿Es accesible y adaptable? | Suite de usabilidad | Sí | CI |
| ¿Se ve bien y no cambió sin querer? | Capturas / goldens + revisión del PR | Parcial | Dueño + revisor |
| ¿Se entiende para una persona? | Sesión con 5 usuarios, SUS, heurísticas | No | Jair Linares (#104) |
| ¿Funciona la app real contra el backend? | E2E manual en emulador | No | Dueño / QA (#97) |

## 1. Suite de usabilidad (automática)

`apps/mobile/test/usabilidad/` · tarjeta **#98**

```sh
cd apps/mobile
flutter test test/usabilidad          # corre en CI, sin emulador
flutter test test/usabilidad --reporter expanded
```

Cubre 7 pantallas (Login, Registro, Inicio, Destinatario, Monto, Confirmar,
Movimientos, Perfil) con estos casos:

| Código | Criterio ISO 25010 | Verificación |
|---|---|---|
| UX-A | Accesibilidad | Áreas táctiles ≥ 48 dp (`androidTapTargetGuideline`) |
| UX-B | Accesibilidad | Todo tocable tiene etiqueta (`labeledTapTargetGuideline`) |
| UX-C | Accesibilidad | Contraste de texto (`textContrastGuideline`) |
| UX-D | Adaptabilidad | Texto al 200 % sin desbordes |
| UX-E | Protección contra errores | Acción deshabilitada hasta que el formulario es válido |
| UX-F | Protección contra errores | El dinero no se mueve sin PIN completo |
| UX-G | Recuperación | El error dice qué pasó y qué hacer, sin códigos técnicos |
| UX-H | Retroalimentación | Silueta/skeleton durante la carga |
| UX-I | Operabilidad | Pantalla de 320×568 sin desbordes |

El arnés común vive en `test/usabilidad/_harness.dart` (tamaño de pantalla,
escala de texto, tema, localización es-PE y las tres guías de accesibilidad).

**Regla:** cada rojo es un hallazgo. Se corrige el widget con el cambio mínimo,
se anota en la tabla de `spec-jheampierre-usabilidad-ui.md` y la prueba queda en
verde. Los hallazgos UX-03 a UX-07 de esa tabla salieron de esta suite.

## 2. Capturas y revisión visual (por PR)

Un test en verde no prueba que la pantalla se vea bien. Por eso:

1. El dueño adjunta **capturas antes/después** en el PR (pantalla normal y a
   200 % de texto).
2. **Otra persona** revisa contra los tokens de `design_system`: color,
   tipografía, espaciado, jerarquía, copy es-PE y estados vacío/carga/error.
3. El checklist de interfaz del PR es obligatorio (`.github/pull_request_template.md`).

Las capturas de la corrida se guardan en `docs/apf3/evidencias/jheampierre/`
para el capítulo D (#99).

## 3. Regresión visual con goldens (opcional, no en CI todavía)

`matchesGoldenFile` compara la pantalla contra una imagen de referencia y falla
si cambia un píxel. Sirve para detectar “se rompió el diseño”, pero **no** dice
si el diseño es bueno: si la pantalla nace mal, el golden la congela mal.

```sh
cd apps/mobile
flutter test test/goldens --update-goldens   # genera/actualiza las referencias
flutter test test/goldens                    # compara
```

**Por qué no está en CI todavía:** las imágenes dependen de la versión de
Flutter, el motor de texto y el sistema operativo. El CI corre en Ubuntu con
Flutter 3.41.7; un golden generado en Windows con otra versión falla por
motivos ajenos al diseño. Antes de activarlo hay que:

1. fijar la misma versión de Flutter que el CI,
2. generar los goldens **en el runner Linux**,
3. subir las imágenes al repo y añadir el job.

Mientras eso no exista, la regresión visual se cubre con capturas + revisión
humana (capa 2), que es lo que pide la rúbrica.

## 4. Prueba con personas (capítulo D, artefacto 1)

Tarjeta **#104**, dueño Jair Linares. 5 usuarios, tarea “enviar S/ 10”, SUS
(meta ≥ 68), tasa de éxito (meta ≥ 80 %), errores y tiempos. Los hallazgos
vuelven a esta suite y se convierten en pruebas nuevas: ese ciclo es la
evidencia de mejora continua.

## 5. E2E manual y nube

- `docs/verificacion-manual.md`: app real contra `services/api` en emulador.
  Prueba lo que ningún widget test puede: teclado, biometría real, gestos.
- #112: recorrido E2E contra Render + Neon.

## Límites que hay que declarar

- La suite automática **no mide aprendizaje humano**; mide reglas objetivas.
- Los goldens detectan cambios, no malas decisiones de diseño.
- 5 usuarios no son una muestra estadística (Nielsen: ~85 % de los problemas).
- El contraste se comprueba sobre los colores renderizados, no sobre imágenes
  de un teléfono real con brillo bajo.
