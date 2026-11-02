# Capacitación: entender y explicar la presentación de las sesiones 19 y 20

Guía de estudio para quien exponga `apf2/presentacion-sesiones-19-20.pdf`.
Primero la teoría (partes 1 a 4), luego qué decir lámina por lámina (parte 5),
las preguntas probables del docente (parte 6) y un glosario (parte 7).
Cifras con corte al 23/10/2026; fuente de cada una en `docs/idoneidad-funcional.md`
y `docs/vyv.md`.

---

## Parte 1 · La idea de fondo en 5 frases

1. «Que el software compile y no tenga bugs» no basta: puede resolver el problema equivocado.
2. La norma **ISO/IEC 25010** ordena la calidad de un producto en características; la primera es **idoneidad funcional**: ¿hace lo que debe, bien y de forma útil?
3. **ISO/IEC 25023** da las **métricas** para medirla (fórmulas con números, no opiniones).
4. **V&V** separa dos preguntas: ¿lo construimos *bien*? (verificación) y ¿construimos *lo correcto*? (validación).
5. Nuestra conclusión honesta: verificamos mucho (todo automatizado y en verde), pero validamos poco (falta probar con usuarios reales).

---

## Parte 2 · Teoría de la sesión 19 (idoneidad funcional)

### 2.1 ISO/IEC 25010
Modelo de calidad **del producto** de software (familia SQuaRE, ISO 25000). La
versión de 2011, que es la que usa el curso, tiene 8 características:
idoneidad funcional, eficiencia de desempeño, **compatibilidad**,
**usabilidad**, fiabilidad, seguridad, mantenibilidad y portabilidad. La
Unidad 3 recorre varias: sesión 19–20 idoneidad funcional, 21–22
compatibilidad, 23 usabilidad. (La revisión de 2023 reordena nombres y añade
«seguridad física»; si el docente la menciona, es la misma idea con otras etiquetas.)

### 2.2 Las tres subcaracterísticas
| Subcaracterística | Pregunta | Ejemplo en CuyCash |
|---|---|---|
| **Completitud** | ¿Se cubren todos los requisitos pactados? | De 96 criterios, 12 cumplidos |
| **Corrección** | ¿Los resultados son exactos? | S/ 500.00 − 125.50 = S/ 374.50, siempre, al céntimo |
| **Idoneidad (pertinencia)** | ¿Ayuda al usuario a lograr su tarea? | Enviar dinero en 4 pasos, errores en español claro, sin trazas |

Truco para explicarlo: **completitud = cuánto se hizo; corrección = qué tan
bien salió; idoneidad = qué tan útil es para quien lo usa.**

### 2.3 Trazabilidad y RTM
- **Historia de usuario (HU):** necesidad del usuario en una frase.
- **Criterio de aceptación (CA):** condición verificable para dar por buena la HU. Aquí hay 4 por HU.
- **RTM (matriz de trazabilidad de requisitos):** tabla que une cada CA con su endpoint o pantalla y con la prueba que lo verifica. Es «bidireccional»: del requisito al código y de la prueba al requisito. Sirve para ver huecos: un CA sin prueba, o una prueba sin requisito.
- **BDD (Given/When/Then):** escribir el criterio como *Dado* una situación, *Cuando* ocurre una acción, *Entonces* se observa un resultado. Los 3 UAT usan este formato.
- **Oráculo de prueba:** el «juez» que dice si el resultado es correcto (el valor esperado de la prueba). Sin oráculo no hay verificación. Por eso un CA solo cuenta como **cumplido** si tiene prueba automatizada.

### 2.4 Las métricas
- **X (completitud)** = funciones implementadas y probadas ÷ funciones especificadas. Meta del curso: ≥ 0.95.
  Nuestro cálculo: **12 ÷ 96 = 0.125.**
- **Y (pruebas aprobadas)** = aprobadas ÷ ejecutadas = 1.00.
- **Por qué X y Y no se parecen:** Y solo mide si lo que probamos funciona; X mide si probamos todo lo que nos pidieron. Y puede ser 1.00 con X = 0.125. La diapositiva lo advierte: Y es un indicador de *proceso*, no de corrección funcional.
- Variantes que calculamos: contando parciales como ½ (0.198); ponderando por puntos de historia (27.25 ÷ 160 = 0.170). La oficial es la primera.

### 2.5 Por qué 0.125 no es un fracaso
Estamos a mitad del curso y faltan épicas enteras (préstamos, QR, antifraude,
conciliación: 52 de los 96 CA pertenecen a 13 HU sin una línea de código). Lo
que sí existe es el núcleo del dinero. Se explica como **avance contra un
alcance de fin de ciclo**, no como calidad baja de lo hecho.

### 2.6 Corrección numérica (el problema de 0.1 + 0.2)
- Los computadores guardan decimales en binario. 0.1 no se puede representar exacto; en coma flotante, `0.1 + 0.2` da `0.30000000000000004`.
- En dinero, un error de un céntimo repetido miles de veces es dinero perdido o inventado.
- **Solución estándar:** guardar **céntimos como enteros**. S/ 125.50 = `12550`. Los enteros suman exacto.
- En CuyCash esto se aplica en capas (la regla dura 10): `Money` en la app (int + moneda), `StrictInt` en el contrato HTTP, `BIGINT` en la base y partida doble en el libro.
- **`StrictInt`:** sin él, el validador convertiría `1000.0`, `"1000"` o `true` en `1000` y movería dinero. Comprobamos que con `int` común 6 de 14 pruebas fallan.
- Solo se convierte a soles con decimales **al mostrar** (`formatSoles`).

### 2.7 Conceptos del libro mayor que aparecen
- **Partida doble:** toda operación genera un débito y un crédito iguales; si no cuadran, la operación no existe.
- **Atomicidad (la A de ACID):** o se aplican ambos asientos o ninguno.
- **Idempotencia:** repetir la misma petición (misma `idempotency_key`) no cobra dos veces. Evita dobles cargos por reintentos o mala red.
- **Bloqueo de fila:** mientras una operación toca una cuenta, otra espera; evita que dos envíos simultáneos gasten el mismo saldo.

---

## Parte 3 · Teoría de la sesión 20 (V&V)

### 3.1 Verificación vs validación
| | Verificación | Validación |
|---|---|---|
| Pregunta | ¿Construimos bien el producto? | ¿Construimos el producto correcto? |
| Se contrasta con | La especificación | La necesidad real del usuario |
| Técnicas | Revisión de código, análisis estático, pruebas unitarias e integración | UAT, pruebas de usabilidad, piloto/beta |
| Quién | Desarrollo y QA | Product Owner y usuarios |
| Cuándo | Todo el tiempo | En hitos de entrega |
| Si falta | Producto que le gusta al usuario pero se cae | Producto impecable pero inútil |

Frase para recordar: *«Un sistema puede pasar el 100 % de las pruebas unitarias
y aun así ser rechazado por el cliente.»*

### 3.2 IEEE 1012
Estándar de V&V de software. Idea central: el rigor (cuánta independencia y
formalidad) depende del **riesgo** del sistema. Un sistema bancario justifica
más rigor que una app de recetas.

### 3.3 Modelo en V
Cada nivel de especificación (izquierda) tiene un nivel de prueba que lo
contrasta (derecha):

| Especificación | Prueba | En CuyCash |
|---|---|---|
| Necesidad del negocio | Aceptación (UAT) | Guion de 3 escenarios |
| Arquitectura | Integración | 363 pruebas de API sobre Postgres 16 en CI |
| Diseño modular | Unitarias | 901 de la app + 35 de paquetes |
| Código | Verificación estática | `flutter analyze`, `pip-audit` |

Es una **guía conceptual**, no un ciclo rígido: nosotros trabajamos en sprints.

### 3.4 Verificación estática
Revisar el código **sin ejecutarlo**: linters, análisis de tipos, revisión de PR,
escaneo de dependencias vulnerables (`pip-audit`). Detecta patrones conocidos
pero **no garantiza** ausencia de defectos. Un **criterio de bloqueo de merge**
es una regla que impide fusionar si no se cumple (en CuyCash, el check *CI listo*).

### 3.5 UAT (User Acceptance Testing)
Prueba donde el usuario o su representante ejecuta escenarios reales y decide
si acepta. Componentes: **guion** (precondición, pasos, resultado esperado),
**criterios de éxito** (tarea completada, tiempo, sin ayuda técnica) y **acta
de conformidad** (documento firmado de aprobación). Quien firma es el Product
Owner. **Importante:** nuestras versiones automatizadas del UAT prueban el
servidor; no sustituyen a una persona usando la app.

### 3.5.1 Pirámide de pruebas (contexto de la sesión 15)
Muchas unitarias (rápidas, aisladas), menos de integración (varias capas
juntas), pocas E2E (toda la app). Nuestros UAT automatizados están en el nivel
de integración/API.

---

## Parte 4 · Qué entender de CuyCash para defender el contenido

- **Qué es:** app móvil de banca digital (Perú), Flutter + backend FastAPI/Postgres. Lo implementado: identidad y accesos, cuentas, libro mayor, envíos entre cuentas CuyCash, recarga simulada, perfil.
- **Lo que no existe:** interbancarias, QR, préstamos, antifraude, conciliación.
- **Cómo se prueba:** backend con `pytest` (SQLite local, Postgres 16 en CI), app con `flutter test`, dos paquetes con sus propias pruebas.
- **Documentos clave:** `idoneidad-funcional.md` (sesión 19), `vyv.md` (sesión 20), `plan-de-pruebas.md`, `seguridad.md`, `verificacion-manual.md`.
- **Qué es «núcleo transaccional»:** HU05 saldos y movimientos, HU06 transferencias, HU17 motor transaccional, HU18 libro mayor.

---

## Parte 5 · Qué decir lámina por lámina

Tiempo sugerido: ~10 minutos (≈ 55 s por lámina).

**1 · Portada.** «Presentamos cómo aplicamos las sesiones 19 y 20 a CuyCash: medir la calidad funcional con la norma ISO 25010 y planificar la verificación y validación.»

**2 · Alcance.** Qué pedían las dos sesiones y qué hicimos (RTM, precisión numérica, índice ISO 25023; plan V&V, verificación estática, UAT y acta). Los cuatro números: 96 CA auditados, 1 299 pruebas en verde, 3 UAT, 0 issues. *Cuidado:* 1 299 pruebas verdes es **verificación**; no lo presentes como calidad funcional completa (viene en la lámina 4).

**3 · Método.** Línea base: 26 HU, MVP de 24 HU y 160 puntos, 96 CA. Tres veredictos: cumple (existe y hay prueba), parcial, no cumple. Regla clave: sin prueba automatizada, no cuenta.

**4 · Completitud.** X = 12/96 = 0.125. Explica la barra (12 / 14 / 70). Mensaje central en el cuadro: Y = 1.00 no es corrección funcional. Y la meta 0.95 es para la entrega final.

**5 · Núcleo transaccional.** 10 de los 12 CA cumplidos están en las HU del dinero. Ninguna HU completa; HU06 y HU18 están a una pieza (interbancaria y cierre diario).

**6 · Corrección numérica.** Explica 0.1 + 0.2, la solución de céntimos enteros y las capas. Remata con la prueba: cambiar `StrictInt` por `int` rompe 6 de 14 pruebas.

**7 · Modelo en V.** Recorre de arriba a abajo: negocio ↔ UAT, arquitectura ↔ integración, diseño ↔ unitarias, código ↔ verificación estática. Aclara que la validación (derecha, arriba) es lo menos cubierto.

**8 · Verificación estática.** Qué reglas bloquean el merge, el resultado de hoy (1 299 aprobadas, 0 fallidas) y las 3 brechas: backend sin linter, `main` exige 0 aprobaciones, sin plantilla de PR.

**9 · UAT.** Lee un escenario completo en formato Dado/Cuando/Entonces (UAT-1). Aclara: corren como pruebas automáticas y cubren el servidor.

**10 · Lo que no está validado.** Sé directo: guion manual nunca ejecutado, sin Product Owner, sin sesión con usuarios. Presenta los próximos pasos.

**11 · Cierre.** Tres mensajes: medimos con evidencia, el núcleo del dinero es lo más sólido, falta validar con usuarios. Termina con la pregunta: «¿todos los requisitos tienen un oráculo automatizado? Hoy, 12 de 96.»

---

## Parte 6 · Preguntas probables y respuestas

**¿Por qué su completitud es tan baja?**
Medimos contra el alcance de fin de ciclo y estamos a mitad. Faltan épicas enteras sin código (52 CA). Es un punto de partida medido, no un defecto de lo construido. La meta de 0.95 es para la entrega final.

**¿Por qué solo cuentan los CA con prueba automatizada?**
Porque la sesión 19 exige un *oráculo*: sin él no podemos afirmar que cumple. Es la regla más estricta y evita inflar el número.

**¿Qué diferencia hay entre X y Y?**
X = funciones implementadas y probadas / especificadas (cuánto cubrimos). Y = pruebas aprobadas / ejecutadas (si lo probado pasa). Y puede ser 1.00 con X bajo.

**¿Verificación y validación no son lo mismo?**
No. Verificación: ¿lo construimos bien, conforme a la especificación? Validación: ¿es lo que el usuario necesita? La primera la hace el equipo; la segunda, el usuario o PO.

**¿Sus UAT son UAT de verdad?**
Son escenarios de aceptación **automatizados** del lado del servidor. Un UAT pleno lo ejecuta una persona con la app y firma un acta. Eso está planificado y declarado como pendiente.

**¿Por qué no usan decimales para el dinero?**
Por el error de coma flotante (0.1 + 0.2 ≠ 0.3). Usamos céntimos enteros en la app (`Money`), el contrato (`StrictInt`) y la base (`BIGINT`).

**¿Qué es la idempotencia y por qué importa?**
Que repetir una operación con la misma clave no la duplica. Si la red falla y el usuario reintenta, no se le cobra dos veces. Hay pruebas, incluida una con peticiones en paralelo contra Postgres.

**¿Qué pasa si falla la verificación en un PR?**
El check *CI listo* queda en rojo y la regla de `main` no deja fusionar.

**¿Por qué el bloqueo es al 3.er intento y no al 5.º del SLA?**
Es más estricto a propósito; está documentado como desviación en `seguridad.md`. Se puede ajustar a 5 si el docente lo prefiere.

**¿Qué mejoraría primero?**
Ejecutar el guion manual en un emulador, designar PO y firmar el acta con UAT-1, y añadir linter al backend y 1 aprobación obligatoria en `main`.

**¿Cómo subirían rápido el índice X?**
Con los criterios baratos: cierre por inactividad (HU03 CA4), saldo contable visible (HU05 CA2), encender frecuentes (HU07) y usar el OTP existente para la activación (HU02).

---

## Parte 7 · Glosario

| Término | Significado corto |
|---|---|
| **ACID** | Atomicidad, consistencia, aislamiento y durabilidad de una transacción |
| **BDD** | Escribir criterios como Dado/Cuando/Entonces |
| **CA** | Criterio de aceptación |
| **CCI/CCE** | Código de cuenta interbancario / cámara de compensación electrónica (transferencias entre bancos) |
| **HU** | Historia de usuario |
| **Idempotencia** | Repetir una petición no repite su efecto |
| **IEEE 1012** | Estándar de verificación y validación |
| **ISO/IEC 25010** | Modelo de calidad del producto de software |
| **ISO/IEC 25023** | Métricas de calidad del producto |
| **Libro mayor** | Registro de todos los asientos contables |
| **Linter / SAST** | Análisis del código sin ejecutarlo |
| **MVP** | Producto mínimo viable (24 HU, 160 puntos) |
| **Oráculo** | Resultado esperado contra el que se juzga una prueba |
| **Partida doble** | Débitos = créditos en cada operación |
| **PO** | Product Owner: decide la prioridad y acepta el producto |
| **RTM** | Matriz de trazabilidad de requisitos |
| **SP** | Puntos de historia (tamaño) |
| **UAT** | Prueba de aceptación del usuario |

---

## Parte 8 · Autoevaluación (responde sin mirar)

1. ¿Qué mide la completitud y cuál es su fórmula?
2. ¿Por qué Y = 1.00 no prueba que el software sea correcto?
3. Da un ejemplo de verificación y otro de validación en CuyCash.
4. ¿Por qué `0.1 + 0.2` rompe un sistema bancario y cómo lo evitamos?
5. ¿Qué es un oráculo de prueba?
6. ¿Qué cubren nuestros UAT automatizados y qué no?
7. ¿Qué tres brechas de verificación estática declaramos?
8. ¿Por qué el acta de conformidad está sin firmar?
