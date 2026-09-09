# SLA y KPI — Banca Online Integral

Fuente: `SLA_KPI_Banca_Online_Integral.xlsx` (elaborado por Andersson Junior
Espinoza Medina, Desarrollador de Datos). Este documento es la versión legible
en repo; el libro conserva la justificación por historia de usuario.

Los SLA de identidad/KYC salen del contrato del servicio facial
(`docs/adr/0001-integracion-kyc-facial.md`); los de disponibilidad y respuesta
a incidentes son referenciales de industria y están pendientes de validar con
el docente.

## Responsables de seguimiento

| Rol | Responsabilidad sobre SLA/KPI |
|---|---|
| Scrum Master — Jair Pool Conislla Bocangel | Velocity, cumplimiento del backlog, impedimentos y avance del cronograma |
| Backend — Jeremy Piero Rojas Egusquiza | SLA de autenticación, cuentas y transferencias |
| Frontend — Jheampierre Johayro Ralli Peralta | SLA de experiencia de usuario en billetera, QR y accesibilidad |
| Datos — Andersson Junior Espinoza Medina | SLA de motor transaccional, libro mayor, préstamos y conciliación; documenta este apartado |
| QA y Seguridad — Gian Piero Gonzales Flores | Criterios de aceptación, KPIs de fraude/seguridad y tasa de defectos |

## SLA técnicos por módulo

### Identidad, KYC y autenticación

| Operación | SLA objetivo | Fuente |
|---|---|---|
| Validación de nitidez del documento (OCR/blur) | ≤ 2 s por imagen | HU01 |
| Evaluación de un paso de liveness (`/liveness/evaluate`) | < 1 s por paso (solo MediaPipe) | SERVICE.md §11.3 |
| Vigencia del token de desafío de liveness | 180 s (configurable) | `CHALLENGE_TOKEN_TTL_SECONDS` |
| Verificación completa de identidad (`verify-full`) | ≤ 5 s | DeepFace/RetinaFace, una sola vez al final |
| Autenticación biométrica (facial / huella / PIN) | < 1.5 s, con PIN de contingencia | HU02 |
| Bloqueo de cuenta por intentos fallidos | Automático al 5.º intento | CA-02 HU02 |
| Cierre de sesión por inactividad | Según política de seguridad configurada | CA-03 HU02 |

### Cuentas, transferencias y motor transaccional

| Operación | SLA objetivo | Fuente |
|---|---|---|
| Procesamiento de una transacción (saldo, bloqueo de fondos, anti doble gasto) | < 200 ms | HU17 |
| Consulta de saldos y movimientos | < 1 s (consolidado en tiempo real) | HU05 |
| Transferencia propia o interbancaria inmediata | Confirmación en línea, sin demora perceptible | HU06 |
| Registro en libro mayor (partida doble) | Atómico: débito y crédito, o ninguno | HU18 |
| Autorización biométrica en pagos de alto monto | Selfie inmediata al superar el umbral | HU08 |

### Préstamos digitales

| Operación | SLA objetivo | Fuente |
|---|---|---|
| Simulación de crédito (monto, plazo, TCEA, cuota) | Respuesta inmediata | HU09 |
| Evaluación crediticia automática | Pre-calificación en minutos | HU10 |
| Firma digital del contrato | Pagaré generado y enviado el mismo día de la aprobación | HU11 |
| Desembolso tras aprobación | Acreditación instantánea a la cuenta elegida | HU12 |

### Billetera, QR y pagos

| Operación | SLA objetivo | Fuente |
|---|---|---|
| Generación de QR dinámico/estático | Inmediata, con caducidad parametrizable | HU14 |
| Lectura y validación de QR | Rechazo antes de afectar saldo si está vencido o alterado | HU15, CA-02 HU16 |
| Confirmación de pago con biometría/PIN/OTP | Una sola autorización por pago (idempotencia) | HU16, CA-01/CA-03 |

### Conciliación, fraude y cumplimiento

| Operación | SLA objetivo | Fuente |
|---|---|---|
| Conciliación bancaria y de redes de pago | Ciclo diario automático programado | HU19 |
| Alerta antifraude (suplantación, geolocalización atípica, transacción inusual) | Tiempo real / near real-time | HU20 |
| Cotejo contra listas restrictivas (OFAC, World-Check, PEP) | Tiempo real en onboarding y transferencias | HU21 |
| Notificación de seguridad al cliente (push/correo) | Inmediata tras la transacción o login biométrico | HU22 |

### Disponibilidad general (propuesta)

| Compromiso | Objetivo | Nota |
|---|---|---|
| Uptime de la plataforma | ≥ 99.5 % mensual | Referencia de industria, ajustar según rúbrica |
| Ventana de mantenimiento programado | Fuera de horario pico, con aviso previo | No cuenta como caída |
| Respuesta ante incidente crítico | ≤ 30 min reconocer, ≤ 4 h mitigar | Alinear con política de incidentes del curso |

## KPI de negocio y operación

| KPI | Definición / fórmula | Meta | Frecuencia |
|---|---|---|---|
| Tasa de éxito de transacciones | Completadas / iniciadas | ≥ 99 % | Diaria |
| Tiempo medio de procesamiento transaccional | Latencia promedio del motor (HU17) | < 200 ms | Continua |
| Tasa de finalización de onboarding KYC | Registros que completan liveness + verify-full / iniciados | ≥ 85 % | Semanal |
| Tiempo promedio de onboarding | Desde inicio de registro hasta cuenta activada | < 5 min | Semanal |
| Tasa de detección/prevención de fraude | Casos bloqueados / casos detectados | ≥ 95 % de patrones conocidos | Mensual |
| Falsos positivos del motor antifraude | Alertas sin fraude real / total de alertas | < 5 % | Mensual |
| Tasa de aprobación crediticia automática | Solicitudes sin intervención manual / total | ≥ 70 % | Mensual |
| Diferencias no resueltas en conciliación | Partidas pendientes tras el ciclo diario | 0 al cierre del día hábil | Diaria |
| Disponibilidad del sistema | Tiempo operativo / tiempo total | ≥ 99.5 % | Mensual |
| Satisfacción del cliente | Encuesta post-operación (CSAT/NPS) | NPS ≥ 40 | Trimestral |

## Backlog y plan de sprints

| Dato | Valor |
|---|---|
| Historias de usuario totales | 22 |
| Historias con prioridad Must | 18 |
| Historias en el MVP | 22 |
| Épicas | 6 |
| Story points del MVP (resumen ejecutivo) | 149 |
| Story points planificados en los 6 sprints | 156 |
| Sprints | 6 (12 semanas) |
| Velocity promedio planificada | 26 pts/sprint |

| Sprint | Objetivo | Historias | Pts | Duración |
|---|---|---|---|---|
| 1 | Identidad, autenticación y gobierno de accesos | HU01–HU04 | 23 | 2 sem. |
| 2 | Cuentas, motor transaccional y libro mayor | HU05, HU17–HU18 | 31 | 2 sem. |
| 3 | Transferencias propias/terceros y antifraude | HU06–HU08, HU20 | 26 | 2 sem. |
| 4 | Ciclo digital de préstamos | HU09–HU12 | 34 | 2 sem. |
| 5 | Billetera y pagos QR interoperables | HU13–HU16 | 26 | 2 sem. |
| 6 | Conciliación, cumplimiento, alertas y estabilización | HU19, HU21–HU22 | 16 | 2 sem. |

> El libro reporta 149 pts en el resumen ejecutivo del MVP y 156 en la suma de
> los sprints; el cronograma general del curso es de 18 semanas (hitos T01–T16)
> aunque el desarrollo son 12. Ambas cifras están sin conciliar en la fuente.

## KPI de seguimiento ágil

| KPI | Definición / fórmula | Meta | Frecuencia |
|---|---|---|---|
| Velocity real por sprint | Pts completados y aceptados / sprint | ≥ 90 % de lo planificado (≈ 23–24 pts) | Por sprint |
| Cumplimiento de historias Must | Must completadas / Must planificadas | 100 % | Por sprint y acumulado |
| Avance del MVP | Pts acumulados / 149–156 | ≈ 26 pts/sprint | Por sprint |
| Tasa de defectos por historia | Defectos en QA / historias entregadas | < 1 defecto crítico por historia | Por sprint |
| Criterios de aceptación cumplidos | CA aprobados / CA definidos | 100 % antes de dar por Done | Por sprint |
| Cumplimiento del cronograma (18 semanas) | Hitos T01–T16 en la semana planificada | 0 desviaciones > 1 semana | Semanal |
| Impedimentos abiertos | Reportados en daily sin resolver | 0 al cierre del sprint | Diaria |
