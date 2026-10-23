# Gestión del equipo y delegación

Cómo reparte el trabajo el equipo de CuyCash en los dos sprints que quedan (5 y 6): quién es dueño
de qué, con qué criterio se delega, cómo se configura el tablero de GitHub
Projects y qué métricas muestran que la delegación funciona.

Corte: 2026-10-23. Tablero: *Cuy Cash - planificacion de proyecto*
(GitHub Projects, organización `Los-hijos-de-Rene`).

---

## Estado al 23/10/2026

El Sprint 5 empezó el 19/10 **sin el plan cargado**: hasta hoy ningún ítem tenía
dueño, prioridad ni sprint. Desde hoy el tablero tiene el plan completo (§6),
pero el sprint ya consumió una semana de sus dos. Acciones:

1. **Reparto asignado el 23/10** (§4, carga equitativa). Falta un Sprint
   Planning corto (30 min) para que cada uno confirme o cambie su parte.
2. Si al cierre del Sprint 5 (01/11) quedan P0 abiertos, pasan al Sprint 6 y
   se suelta en el orden de §4: panel admin → asistente IA → desembolso.
3. Registrar esta semana perdida en la Retrospectiva: es el primer
   impedimento de gestión del proyecto, y explicarlo es parte de la nota.

## 1. Diagnóstico

Datos sacados del tablero y de GitHub, no de memoria:

| Hallazgo | Evidencia | Por qué importa |
|---|---|---|
| **Ninguna tarjeta tiene responsable** | 35 de 35 ítems sin *Assignees* | Sin dueño nadie responde por el ítem; el tablero no muestra la carga de cada persona |
| Prioridad, tamaño, estimación y fechas vacíos | El campo *Priority* no tiene opciones; *Size*, *Estimate*, *Start/Target date* sin valor | El *Roadmap* sale sin barras y no se puede medir la velocidad |
| Backlog sobre su propio límite | Columna *Backlog* en **16/10** | El límite existe pero nadie lo respeta |
| Ítems del tamaño de una épica | #47 "Préstamos digitales" = HU09–HU12 = 34 SP; #48 = 3 HU | Una épica no se puede delegar a una persona: hay que partirla |
| Concentración del código | `CuyCashUTP`: 294/294 commits y 38/38 PR de una sola cuenta. `CuyCashKYC`: Jheampierre 8, Jair 4 | **Factor bus = 1**: si esa persona falta, el repositorio principal se detiene |
| Roles incompletos | Sin Product Owner designado; Jair Abdel Linares sin especialidad; Gian Piero no es colaborador del repositorio | Sin PO nadie decide la prioridad; sin acceso, QA no puede revisar PR |

**Conclusión:** el producto avanzó, pero en la práctica fue un esfuerzo
individual. El reto de los sprints que quedan no es técnico: es repartir el
trabajo para que **cada integrante tenga autoría verificable** en el
repositorio y el proyecto no dependa de una sola persona.

## 2. Principios de delegación

1. **Un dueño por ítem.** Cada issue tiene exactamente un *Assignee*, que
   responde por él de punta a punta (código, pruebas, documento). Los demás
   colaboran en sub-issues o como revisores.
2. **Delegar el resultado, no los pasos.** El issue dice *qué* se acepta (los
   CA de [`idoneidad-funcional.md`](idoneidad-funcional.md)) y *por qué*; el
   dueño decide el *cómo* dentro de las reglas duras del repositorio.
3. **Delegar según la especialidad, con un par que aprende.** Cada ítem
   técnico tiene un dueño de la especialidad y un revisor de otra. Así el
   conocimiento se reparte y el factor bus sube.
4. **Carga equitativa, medida en días.** Cada tamaño vale un número de días
   (XS ½ · S 1 · M 2½ · L 5) y el reparto se cuadra para que nadie cargue mucho
   más que el promedio. Jair C. (Scrum Master, autor de casi todo el código)
   implementa su parte **como uno más, no más**, y revisa como los demás.
5. **Nadie empieza un ítem que no está listo** (*Definition of Ready*, §5) ni
   lo cierra sin cumplir la *Definition of Done*.
6. **Límite de trabajo en curso (WIP).** Máximo **2 ítems *In progress* por
   persona**. Antes de tomar uno nuevo, se termina o se libera uno.

## 3. Roles y responsabilidades (RACI)

**R** realiza · **A** aprueba y responde · **C** consultado · **I** informado.

| Área | Jair C. (SM) | Jeremy (Backend) | Jheampierre (Frontend) | Andersson (Datos) | Gian Piero (QA/Seg.) | Jair L. |
|---|---|---|---|---|---|---|
| Prioridad del backlog | C | C | C | C | C | — · **PO por designar** (A) |
| API, autenticación, integraciones | C | **A/R** | I | C | C | R (en par) |
| App Flutter, UX, accesibilidad | C | I | **A/R** | I | C | R (en par) |
| Modelo de datos, libro mayor, migraciones | C | C | I | **A/R** | C | — |
| Pruebas, CA, métrica de completitud | I | R | R | R | **A** | R |
| Seguridad (controles, ZAP, auditoría) | C | R | I | C | **A/R** | — |
| Asistente IA (API y chat) | C | C | C | I | C | **A/R** |
| Panel admin (consultas y web) | C | C | I | **A/R** | C | R |
| Despliegue y CI/CD | **A** | R | I | C | C | — |
| Ceremonias, impedimentos, informe APF | **A/R** | I | I | I | C | R |

> **Product Owner:** el equipo debe nombrarlo en el próximo Sprint Planning.
> Propuesta: un integrante que no sea el SM (Scrum separa ambos roles), con
> autoridad para ordenar el backlog y aceptar cada incremento.
>
> **Jair Abdel Linares:** dueño del **asistente IA** (API y pantalla) y de la
> **web del panel admin**, con Jair C. y Jheampierre de revisores. Confirmar en
> el Planning según su experiencia.

### Niveles de delegación por decisión

Basado en *Delegation Poker* (Management 3.0): 1 = el líder decide · 3 = el
líder consulta y decide · 5 = el equipo decide y el líder aconseja · 7 = el
equipo decide solo.

| Decisión | Nivel | Quién decide |
|---|---|---|
| Orden del backlog | 3 | PO, consultando al equipo |
| Diseño interno de un ítem (librerías, estructura) | 5 | El dueño del ítem, con el consejo del revisor |
| Aceptar un PR | 5 | El revisor asignado (debe ser otra persona) |
| Cambiar el contrato API ↔ app | 3 | Backend + Frontend, consultando al SM |
| Cambiar el esquema de la base | 3 | Datos, consultando a Backend |
| Desplegar a producción | 3 | SM aprueba el environment `production` |
| Cuándo trabajar y en qué orden dentro del sprint | 7 | Cada dueño |

## 4. Plan de delegación (Sprints 5 y 6)

Quedan **dos sprints** hasta el fin del curso. Supuesto de calendario: 2
semanas cada uno, desde el lunes 19/10/2026; ajustar si el docente fija otra
fecha de entrega.

| Sprint | Fechas | Objetivo |
|---|---|---|
| 5 | 19/10 – 01/11 | Cerrar los CA parciales críticos y la deuda de seguridad, **pago con QR** completo y las bases de préstamos, del asistente IA y del panel admin |
| 6 | 02/11 – 15/11 | **Préstamos** (HU09, HU10, HU12), **asistente IA** y **panel admin** en pantalla, verificación E2E y entrega final |

Cuatro frentes nuevos (QR, préstamos, asistente IA y panel admin) en dos
sprints solo caben en **versión mínima** y soltando trabajo de menor impacto
(ver *Fuera de alcance*). Cada frente tiene un dueño distinto para que avancen
en paralelo.

| Frente | Dueño del frente | Versión mínima que se compromete |
|---|---|---|
| Pago con QR | Jeremy (API) + Jheampierre (app) | Cobrar con QR firmado (monto, concepto, caducidad) y pagarlo leyendo la cámara. El pago es un envío más por `ledger.post`, con idempotencia |
| Préstamos | Jeremy (API) + Andersson (cálculo y desembolso) | Simular, solicitar con evaluación automática por score interno y desembolsar con cronograma |
| Asistente IA | Jair L. | Chat dentro de la app que responde dudas de uso y consulta **en solo lectura** los saldos y movimientos del titular. **Nunca mueve dinero** |
| Panel admin | Andersson (datos) + Jair L. (web) | Web de solo lectura con rol `admin`: altas y estado KYC, operaciones del día, cuadre del libro mayor y bloqueos activos |

Prioridad: **P0** sin esto no hay entrega · **P1** sube la completitud ·
**P2** solo si sobra capacidad. Tamaño: XS < ½ día · S 1 día · M 2–3 días ·
L 1 semana · XL partir.

### Sprint 5 · parciales críticos, QR y bases

| Ítem | Dueño | Revisor | Prio. | Tamaño | Cierra |
|---|---|---|---|---|---|
| #76 Cierre de sesión por inactividad | Gian Piero | Jair L. | P0 | S | HU03 CA4 |
| #78 QR en la app: generar cobro y leer para pagar | Jheampierre | Jair L. | P0 | L | HU14 CA1–CA2, HU15 CA1 |
| #36 KYC exigido por el servidor | Jeremy | Gian Piero | P0 | M | HU01 CA2 · riesgo R01 |
| #37 OTP por correo, sin códigos en logs | Jair C. | Jeremy | P0 | M | Riesgo R06 |
| #77 API de QR: emitir firmado con caducidad, validar y pagar vía `ledger.post`; huella sobre el límite base | Jeremy | Andersson | P0 | M | HU14 CA1–CA2, HU15 CA2–CA4 |
| #40 Migraciones con Alembic | Andersson | Jeremy | P0 | M | Riesgo R05; necesario para las tablas nuevas |
| #79 Cuota, TCEA y cronograma en céntimos con regla de redondeo y casos borde | Andersson | Gian Piero | P0 | M | Base de HU09 y HU12 |
| #80 Modelo y migración: solicitud, préstamo, cuotas | Jair C. | Andersson | P0 | S | Base de HU10–HU12 |
| #81 Rol `admin` (RBAC), rutas `/v1/admin/*` cerradas al titular y CORS con lista blanca exacta | Gian Piero | Jeremy | P0 | M | Control AC-15 |
| #82 Casos de aceptación de QR y préstamos escritos antes del código | Gian Piero | Jair C. | P0 | S | Oráculos de ambos sprints |
| #83 API del asistente: proxy al modelo con la clave solo en el backend, herramientas de solo lectura y límite de uso | Jair L. | Jair C. | P1 | M | HU27 (propuesta) |
| #51 Levantar observaciones del APF1 | Jair C. | Jheampierre | P0 | S | — |

### Sprint 6 · préstamos, asistente, panel y entrega (#47 se parte en sub-issues)

| Ítem | Dueño | Revisor | Prio. | Tamaño | Cierra |
|---|---|---|---|---|---|
| #84 API simulador, solicitud con consentimiento y evaluación por score interno | Jeremy | Andersson | P0 | L | HU09 CA1–CA2, HU10 CA1, CA2, CA4 |
| #85 Desembolso vía `ledger.post` con idempotencia y cronograma definitivo | Andersson | Jeremy | P0 | M | HU12 CA1–CA2 |
| #86 Pantallas: simulador, solicitud, resultado, cronograma; compartir simulación | Jheampierre | Jair L. | P0 | L | HU09 CA4 |
| #87 Cierre contable diario que verifica el cuadre | Jair C. | Andersson | P1 | M | HU18 CA4 |
| #88 Consultas del panel: altas, KYC, operaciones del día, cuadre y bloqueos | Andersson | Gian Piero | P1 | M | HU28 (propuesta) |
| #89 Panel admin web (Flutter web con `design_system`), solo lectura | Jair L. | Jheampierre | P1 | M | HU28 (propuesta) |
| #90 Pantalla de chat del asistente | Jair L. | Jheampierre | P1 | M | HU27 (propuesta) |
| #91 Pruebas de aceptación de QR y préstamos sobre la API y la app | Gian Piero | Jair C. | P0 | M | Oráculos de todo lo anterior |
| #50 Verificación E2E en Android y biometría real | Gian Piero | Jheampierre | P0 | M | Riesgo R07 |
| #92 Informe final y recálculo de la métrica X | Jair C. | Gian Piero | P0 | M | — |

### Alcance nuevo fuera de la línea base

El asistente IA y el panel admin **no están entre las 26 HU** del Excel
corregido; el panel figuraba como "diferido" en los documentos del
repositorio. Para que cuenten, el **PO** los agrega al backlog como historias
con sus cuatro CA antes del Sprint Planning:

| Propuesta | Esqueleto de CA |
|---|---|
| **HU27 · Asistente IA** (#74) | Responde dudas de uso en es-PE · consulta saldos y movimientos **solo del titular con sesión** · no ejecuta operaciones de dinero ni revela datos de terceros · si no sabe o el modelo falla, lo dice y deriva a soporte |
| **HU28 · Panel administrativo** (#75) | Solo entra un usuario con rol `admin` · muestra altas y estado KYC · muestra operaciones del día y el cuadre del libro mayor · es de solo lectura y enmascara DNI y cuentas |

Agregarlas cambia el denominador de la métrica: 26 HU → 28, y 96 CA del MVP →
104 si el PO las marca MVP. El informe debe decir cuál de los dos se usa.

Reglas que no se negocian en ambos frentes:

- **Asistente:** la clave del modelo vive solo en el backend (igual que la del
  KYC). Las herramientas que el modelo puede llamar son de lectura y van con
  la sesión del titular; nunca recibe un PIN ni puede invocar `/transfers`.
- **Panel:** un titular nunca entra a `/v1/admin/*` (prueba en
  `test_sesion_requerida.py`). Al abrir CORS solo se admite el origen exacto
  del panel; ningún comodín.

### Fuera de alcance, declarado

| Ítem | Motivo |
|---|---|
| HU11 Contrato y firma | Sale para dar lugar al asistente; sin firma certificada quedaba en 1 CA de 4 |
| Activación del alta por OTP (HU02) | P2: el OTP existe; conectarlo al alta queda si sobra tiempo |
| Frecuentes visibles y editables (HU07) | P2 |
| #43 Prueba de carga (200 ms), #39 CSP | P2: siguen como riesgo declarado |
| HU14 CA3–CA4, HU13, HU16 | Interoperabilidad con otras billeteras y push al comercio necesitan redes y proveedores externos |
| #45 CCI interbancario | Necesita una red bancaria externa |
| #48 Antifraude, conciliación y AML (HU19–HU21) | Tres historias de 8 SP sin datos ni proveedores reales |
| #49 Notificaciones (HU22) | Necesita push y correo transaccional |
| HU10 CA3, HU12 CA3–CA4, HU09 CA3 | Centrales de riesgo reales, débito automático, avisos de cuota y desgravamen |
| #38, #41, #42, #44, HU25, HU26 | P2: solo si sobra capacidad |

Decir que no por escrito también es gestión: protege lo que sí se compromete.

### Carga por persona (reparto equitativo del 23/10)

Días de trabajo según el tamaño (XS ½ · S 1 · M 2½ · L 5). Total: 56.5 días
en 22 tareas, **9.4 días por persona** en promedio.

| Integrante | Sprint 5 | Sprint 6 | Total | Revisa |
|---|---|---|---|---|
| Jeremy | 5 (#36, #77) | 5 (#84) | **10** | 4 |
| Jheampierre | 5 (#78) | 5 (#86) | **10** | 4 |
| Andersson | 5 (#40, #79) | 5 (#85, #88) | **10** | 4 |
| Gian Piero | 4.5 (#76, #81, #82) | 5 (#91, #50) | **9.5** | 4 |
| Jair C. | 4.5 (#51, #37, #80) | 5 (#87, #92) | **9.5** | 3 |
| Jair L. | 2.5 (#83) | 5 (#89, #90) | **7.5** | 3 |

**Qué se movió respecto de la primera propuesta** (que tenía a Jeremy con 15
días y a Jair L. con 5):

| Tarea | De → a | Por qué encaja |
|---|---|---|
| #37 OTP por correo, sin códigos en logs | Jeremy → Jair C. | Jair C. escribió el módulo de OTP |
| #85 Desembolso | Jeremy → Andersson | Es un asiento del libro mayor, su especialidad |
| #87 Cierre contable diario | Andersson → Jair C. | Conoce `ledger.py` y libera a Andersson para el desembolso |
| #80 Modelo de préstamos | Andersson → Jair C. | Pequeño y acotado; lo revisa Andersson |
| #76 Cierre por inactividad | Jheampierre → Gian Piero | Es un control de seguridad; Jheampierre ya carga dos L |
| #89 Panel admin web | Jair C. → Jair L. | Jair L. debe tener carga real, no solo revisiones |

**Jair L.** tiene menos en el Sprint 5 porque aún no tiene acceso al
repositorio. Sus tres tareas (#83, #89, #90) quedan sin asignar hasta que
acepte la invitación; **si no entra antes del 02/11, pasan a Jair C.** Mientras
tanto, sus revisiones las cubren Jheampierre (#76) y Jair C. (#78, #86).

**Camino crítico:** Jeremy (QR y préstamos dependen de su API) y Jheampierre
(una L en cada sprint). Si uno se atrasa, el orden para soltar es: panel admin
→ asistente IA → desembolso. QR y la simulación/solicitud de préstamos no se
sueltan.

### Proyección de la métrica

Sobre los 96 CA de la línea base (sin HU27 ni HU28):

| Momento | CA cumplidos | X |
|---|---|---|
| Hoy | 12 | 0.125 |
| Fin del Sprint 5 (P0 cerrados) | 20 | 0.208 |
| Fin del Sprint 6 (préstamos + cierre diario) | 26 – 29 | 0.27 – 0.30 |

El asistente y el panel no mueven esta X, porque no están en la línea base. Si
el PO los agrega como MVP, suman hasta 8 CA sobre 104.

**La meta de 0.95 no se alcanza en este curso** con el backlog de 26 HU. Es
mejor declararlo con esta proyección que prometerlo: el informe final debe
presentar X real, lo que quedó fuera y por qué.

## 5. Definition of Ready y Definition of Done

**Ready** (para pasar de *Backlog* a *Ready*):

- [ ] Tiene dueño, revisor, prioridad, tamaño ≤ L y sprint.
- [ ] Dice qué CA cierra, con su texto, o es deuda técnica con criterio de salida.
- [ ] Sus dependencias están en *Done* o planificadas antes.

**Done** (para cerrar):

- [ ] PR revisado y aprobado por **otra persona** (la regla de `main` ya exige el CI).
- [ ] Cada CA que cierra tiene una prueba automatizada, positiva y negativa.
- [ ] `flutter analyze` sin issues; `flutter test` y `pytest` en verde.
- [ ] Fila actualizada en `idoneidad-funcional.md` y documento APF afectado.

## 6. Configuración del tablero

**Ya aplicado (23/10/2026):**

| Cambio | Para qué |
|---|---|
| Campo *Sprint* (iteración): Sprint 5 del 19/10 y Sprint 6 del 02/11, 14 días cada uno | Agrupar por sprint y medir la velocidad |
| *Priority* (campo de la organización): **P0 = Urgent · P1 = High · P2 = Low** | Ordenar el backlog sin duplicar el campo |
| *Start date* y *Target date* = fechas del sprint de cada ítem | Que el *Roadmap* muestre barras |
| *Size* en todos los ítems abiertos del plan | Detectar ítems XL (#46 y #47 son épicas: se trabajan por sus sub-issues) |
| 19 issues nuevos (#74–#92): dos historias propuestas y 17 tareas, cada una con "Se acepta cuando", dueño propuesto y revisor | Que cada pieza tenga un solo dueño |
| Sub-issues: #46 ← #77, #78 · #47 ← #79, #80, #84, #85, #86 · #74 ← #83, #90 · #75 ← #81, #88, #89 | Ver el avance de cada épica en *Sub-issues progress* |
| Etiqueta `fuera-de-alcance` en #44, #45, #48, #49 · `propuesta-po` en #74, #75 | El backlog muestra solo lo comprometido |
| Gian Piero (`pierog30`) colaborador del repositorio y editor del tablero | Puede ser dueño y revisor |
| **19 tareas asignadas** con el reparto equitativo; dueño y revisor escritos en cada issue | Cada uno ve su trabajo en *My items* |

**Pendiente:**

| Cambio | Quién | Por qué no está |
|---|---|---|
| Invitar a Jair L. | SM | Falta su usuario correcto de GitHub |
| Límites de WIP: *Ready* 12 · *In progress* 8 · *In review* 6 | SM, en la web | GitHub no los expone por API |
| Vista **"Por persona"**: tabla agrupada por *Assignees*, filtrada a `sprint:@current` | SM, en la web | Ídem |
| Vista *Roadmap* con *Start/Target date* y marcadores de sprint | SM, en la web | Ídem |

Cuando Jair L. acepte la invitación: `gh issue edit 83 89 90 --add-assignee <su-usuario>`.

## 7. Métricas de gestión

Se revisan en la Sprint Review y van al informe:

| Métrica | Fórmula | Meta | Fuente |
|---|---|---|---|
| Ítems con dueño | ítems con *Assignee* / ítems del sprint | 100 % | Tablero |
| Reparto de autoría | PR fusionados del autor con más PR / total del sprint | ≤ 40 % | `gh pr list --state merged` |
| PR revisados por otro | PR con revisión de alguien que no es el autor / total | 100 % | GitHub |
| Velocidad | SP en *Done* por sprint | Estable ±20 % | *Estimate* + *Iteration* |
| Cumplimiento del compromiso | SP terminados / SP comprometidos | ≥ 80 % | Tablero |
| WIP por persona | Ítems *In progress* por *Assignee* | ≤ 2 | Vista "Por persona" |
| Completitud funcional | X = CA cumplidos / 96 | Sube cada sprint | `idoneidad-funcional.md` |
| Impedimentos | Abiertos al cierre del sprint | 0 | Daily |

Línea base de hoy: ítems con dueño **0 %**, reparto de autoría **100 %** en una
persona, X = **0.125**.

## 8. Ceremonias

| Ceremonia | Cuándo | Salida concreta |
|---|---|---|
| Sprint Planning | Lunes que abre el sprint, 1 h | Ítems del sprint con dueño, revisor, prioridad y tamaño (§5 *Ready*) |
| Daily | 15 min, mismo horario (vale asíncrona en un hilo) | Qué cerré, qué sigue, qué me bloquea; el SM toma los bloqueos |
| Refinamiento | A mitad del sprint, 45 min | Épicas del siguiente sprint partidas en ítems ≤ L |
| Sprint Review | Viernes que cierra el sprint | Demo de lo terminado; X y velocidad recalculados |
| Retrospectiva | Tras la Review, 30 min | Una mejora concreta con dueño, que entra al siguiente sprint |

## 9. Riesgos de la delegación

| Riesgo | Mitigación |
|---|---|
| Un ítem delegado se atasca por falta de contexto | Revisor asignado desde el Planning; el dueño puede pedir una sesión en par de 30 min |
| Baja la calidad al repartir | La DoD no cambia: CI obligatorio, pruebas por CA y revisión de otra persona |
| El SM vuelve a hacerlo todo "para ir más rápido" | La métrica de reparto de autoría (≤ 40 %) lo hace visible en cada Review |
| Integración tardía app ↔ API | Backend publica el contrato (OpenAPI) antes de implementar; Frontend usa el `Memory*` mientras tanto (regla dura 3) |
| Un integrante no puede cumplir | Se avisa en el Daily; el SM redistribuye y lo registra en la Retro |
