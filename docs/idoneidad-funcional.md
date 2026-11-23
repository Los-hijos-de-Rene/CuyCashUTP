# Idoneidad funcional (ISO/IEC 25010 · 25023)

**Sesión 19 · Curso Integrador II.** Auditoría de la versión actual frente al
alcance planificado para fin de ciclo: matriz de trazabilidad (RTM) por criterio
de aceptación, auditoría de corrección numérica, idoneidad de la tarea y el
índice de completitud funcional de ISO/IEC 25023. Alimenta el informe de APF3.

Corte: 2026-10-16, rama `feat/idoneidad-funcional-iso25010`.

---

## 1. Línea base

Se mide contra el backlog del **Excel corregido** que usa el informe APF2
(§2.7), no contra la versión anterior de [`sla-kpi.md`](sla-kpi.md):

| Dato | Valor |
|---|---|
| Historias | 26 (7 épicas) |
| MVP | 24 HU · 160 SP (fuera: HU23 y HU26, *Could*) |
| Criterios de aceptación (CA) del MVP | 96 (cuatro por historia) |

> `sla-kpi.md` y `CLAUDE.md` aún describen 22 HU y 6 épicas, y numeran distinto
> desde HU02 (allí HU02 es autenticación; en el Excel corregido es activación
> por OTP y la autenticación es HU03). Toda cifra de este documento usa la
> numeración del Excel corregido.

## 2. Método

Cada CA recibe uno de tres veredictos:

| Veredicto | Significa |
|---|---|
| ✅ **Cumple** | El comportamiento existe **y** una prueba automatizada lo verifica (oráculo). |
| 🟡 **Parcial** | Existe una porción ejecutable, pero falta parte del CA o su oráculo. |
| ❌ **No cumple** | No existe el comportamiento exigido, o es una cifra que nadie mide. |

Solo ✅ cuenta como "función implementada y probada" en la métrica de §5.
Una función sin oráculo no se da por buena aunque parezca funcionar: la
diapositiva lo exige y es la regla que aplicamos.

Rutas de prueba: `api/` = `services/api/tests/`, `app/` = `apps/mobile/test/`.

## 3. Matriz de trazabilidad (RTM) por criterio

Los oráculos acordados antes del código para los CA comprometidos de préstamos
y QR están en [`casos-aceptacion-qr-prestamos.md`](casos-aceptacion-qr-prestamos.md).
Su definición no cambia el veredicto de esta RTM: solo contarán como cumplidos
cuando #91 los ejecute contra una implementación real. Para HU14 y HU15 esa
ejecución ya existe; la correspondencia escenario ↔ prueba está en su sección
"Ejecución de HU14 y HU15".

Solo las 13 historias del MVP que tienen código. Las otras 11 (HU08–HU13,
HU16, HU19–HU21, HU25) no tienen ninguna porción ejecutable: sus 44 CA son ❌.

### HU01 · Registro y KYC (8 SP)

Endpoints: `POST /v1/kyc/liveness/challenge`, `/v1/kyc/document/validate`,
`/v1/kyc/document/mrz`, `/v1/kyc/identity/verify-full`, `POST /v1/auth/register`.

| CA | Requisito | Veredicto | Evidencia / brecha |
|---|---|---|---|
| CA1 | OCR del documento con precisión ≥ 95 % | 🟡 | MRZ TD1 con Tesseract y dígito ICAO; `api/test_proxy_kyc.py`. La precisión **no se mide** y el lector solo se probó con una MRZ sintética |
| CA2 | Liveness antes de continuar | 🟡 | ML Kit guía y el servicio re-mide cada gesto; `app/presentation/kyc/liveness_bloc_test.dart`, `api/test_kyc_obligatorio.py · test_sin_aprobacion_completa_no_hay_ticket`. `KYC_REQUIRED` sigue apagado en producción y no se probó en un teléfono |
| CA3 | Rostro contra documento **y RENIEC** | 🟡 | Rostro ↔ documento (SFace) y DNI ↔ MRZ: `test_el_ticket_es_del_dni_del_documento`. Sin RENIEC |
| CA4 | Motivo del fallo, reintentos limitados, revisión manual | 🟡 | Mensaje y vuelta al paso del rostro: `app/presentation/register/register_kyc_ticket_test.dart`. Sin derivación a revisión manual |

### HU02 · Activación OTP (3 SP)

| CA | Requisito | Veredicto | Evidencia / brecha |
|---|---|---|---|
| CA1 | OTP al correo/celular al terminar el KYC | ❌ | El OTP existe para teléfono nuevo y recuperación, no para activar el alta |
| CA2 | Activar solo con código válido y ≤ 10 min | 🟡 | `OTP_TTL_SECONDS = 600`; `api/test_otp_y_recuperacion.py`. Mecanismo listo, no aplicado a la activación |
| CA3 | Reenviar hasta 3 veces con espera | 🟡 | `OTP_MAX_RESENDS = 3`, `OTP_COOLDOWN_SECONDS = 60`; `test_reenviar_cambia_el_codigo_y_reinicia_el_vencimiento`. Mismo matiz |
| CA4 | Notificar la activación | ❌ | — |

### HU03 · Autenticación (5 SP)

Endpoints: `POST /v1/auth/sessions`, `/v1/auth/sessions/biometric`,
`/v1/auth/biometric/enroll`, `DELETE /v1/auth/sessions/current`.

| CA | Requisito | Veredicto | Evidencia / brecha |
|---|---|---|---|
| CA1 | Ingreso facial < 1.5 s como método principal | ❌ | El acceso biométrico es por huella; no hay login facial ni medición del 1.5 s |
| CA2 | Huella o PIN como alternativa | ✅ | `api/test_biometria.py · test_activar_y_entrar_con_huella`, `api/test_registro_y_login.py`, `app/presentation/quick_access/` |
| CA3 | Bloqueo tras 5 fallos **y notificar** | 🟡 | Bloquea al **3.er** fallo (más estricto, 15 min → 1 h → 24 h): `test_agotados_los_intentos_se_bloquea_y_ni_el_pin_correcto_pasa`. No se notifica al cliente |
| CA4 | Cierre de sesión por inactividad | ✅ | 5 min sin uso por defecto (`SESSION_INACTIVITY_MINUTES`): la app vuelve al acceso rápido y pide PIN o huella. `app/presentation/session/inactivity_watcher_test.dart` (positiva, negativa y ciclo de vida) y `app/presentation/session/session_lock_test.dart` (gate del router) |

### HU04 · Recuperación (5 SP)

Endpoints: `POST /v1/otp/challenges`, `/v1/otp/challenges/{id}/verify`, `POST /v1/auth/pin/reset`.

| CA | Requisito | Veredicto | Evidencia / brecha |
|---|---|---|---|
| CA1 | Pedir recuperación desde el login sin credencial | ✅ | `api/test_otp_y_recuperacion.py · test_el_codigo_correcto_entrega_un_ticket_y_se_consume`, `app/presentation/recover/` |
| CA2 | Re-validar el rostro | ❌ | La recuperación es por OTP al correo |
| CA3 | Nuevo PIN solo tras validación **facial** | 🟡 | Solo tras el OTP: `test_no_se_puede_cambiar_el_pin_sin_pasar_por_el_codigo` |
| CA4 | Aviso por correo y push del restablecimiento | ❌ | — |

### HU05 · Saldos y movimientos (5 SP)

Endpoints: `GET /v1/accounts`, `/v1/accounts/{id}/movements`, `/v1/movements`, `/v1/movements/{id}`.

| CA | Requisito | Veredicto | Evidencia / brecha |
|---|---|---|---|
| CA1 | Todas las cuentas con tipo, número enmascarado y saldo | ✅ | `api/test_cuentas_y_movimientos.py · test_solo_devuelve_las_cuentas_propias`; tipo y saldo en `app/presentation/home/account_carousel_test.dart`; `Nro. de cuenta ••••4521` en `home_screen_test.dart` |
| CA2 | Contable vs. disponible con fondos retenidos | 🟡 | La API devuelve `saldo_contable` y `saldo_disponible`, pero no hay retenciones (siempre iguales) y la app no muestra el contable |
| CA3 | Movimientos de la cuenta al seleccionarla | ✅ | `test_el_historial_no_mezcla_movimientos_de_otras_cuentas`, `app/presentation/movements/movements_screen_test.dart` |
| CA4 | Exportar a PDF o Excel | ❌ | Solo se comparte la constancia de un movimiento |

### HU06 · Transferencias (8 SP)

Endpoints: `POST /v1/transfers`, `GET /v1/directory/resolve`.

| CA | Requisito | Veredicto | Evidencia / brecha |
|---|---|---|---|
| CA1 | Entre cuentas propias, inmediata y sin costo | ✅ | `api/test_envio_por_cuenta.py · test_entre_cuentas_propias_se_puede`, `app/presentation/transfer/send_flow_test.dart` |
| CA2 | Interbancaria CCI/CCE validando al titular | ❌ | No existe |
| CA3 | Sin fondos: rechazo sin afectar saldos | ✅ | `api/test_motor_de_asientos.py · test_sin_saldo_no_escribe_nada`, `api/test_transferencias.py · test_sin_saldo_suficiente_responde_insufficient_funds` |
| CA4 | Comprobante con fecha, monto, cuentas y n.º de operación | ✅ | `app/presentation/movement/receipt_card_test.dart`: monto, contraparte, cuenta `••••7732`, estado, fecha (aserción **nueva**, §7) y n.º de operación; el texto para compartir dice lo mismo |

### HU07 · Beneficiarios (3 SP)

Endpoints: `GET/POST /v1/beneficiaries`, `DELETE /v1/beneficiaries/{id}`.

| CA | Requisito | Veredicto | Evidencia / brecha |
|---|---|---|---|
| CA1 | Guardar con alias, foto y cuenta tras un envío | 🟡 | API y pruebas en `api/test_directorio_y_frecuentes.py`; sin foto y **ocultos** en la app (`FeatureToggles.frecuentesEnEnvio = false`) |
| CA2 | Buscar y agrupar | ❌ | — |
| CA3 | Límite pre-aprobado por beneficiario | ❌ | — |
| CA4 | Editar o eliminar | 🟡 | Eliminar sí; editar no |

### HU14 · Generación QR (5 SP)

Endpoints: `POST /v1/qr/emitir` (cobro con monto fijo), `POST /v1/qr/estatico`
y `/v1/qr/estatico/regenerar` ("Mi QR", monto libre). Cerrada el 2026-11-22
(#142–#144).

| CA | Requisito | Veredicto | Evidencia / brecha |
|---|---|---|---|
| CA1 | QR con monto y concepto específico por cobro | ✅ | `api/test_qr_flujo.py · test_qr_01_emitir_y_consultar_nombre_enmascarado`, `test_qr_08_no_se_puede_emitir_para_cuenta_ajena`; `app/presentation/qr/qr_charge_screen_test.dart` (con monto y concepto muestra el QR; sin monto no genera). Además, "Mi QR" sin monto: `api/test_qr_estatico.py · e01–e16` |
| CA2 | Configurar la caducidad del QR | 🟡 | El servidor acepta `caducidad_segundos` (30 s–24 h) y rechaza el vencido: `test_qr_04_qr_vencido_se_rechaza_sin_descontar`. La app no deja elegirla: manda 15 min fijos (`QrCharge.vigencia`) y ninguna prueba cubre los bordes del rango |
| CA3 | Interoperable con otras billeteras y bancos | ❌ | Requiere el switch del BCRP; el payload lleva versión para migrar a EMVCo después (`gestion-del-equipo.md`, fuera de alcance) |
| CA4 | Push al comercio al recibir el abono | ❌ | No hay push (ver HU22) |

### HU15 · Pago QR (5 SP)

Endpoints: `POST /v1/qr/validar`, `POST /v1/qr/pagar`. El pago es un
`pago_qr` por `ledger.post` con idempotencia.

| CA | Requisito | Veredicto | Evidencia / brecha |
|---|---|---|---|
| CA1 | Leer el QR y mostrar nombre y monto antes de confirmar | ✅ | `app/presentation/qr/qr_pay_screen_test.dart · el escaneo muestra nombre y monto antes de confirmar`; `api/test_qr_estatico.py · e04_validar_muestra_a_quien_sin_monto_y_no_mueve_dinero`. En "Mi QR" el monto lo escribe el pagador y la app valida el máximo y el cupo del día antes del PIN (`qr_pay_bloc_test.dart`, grupo monto libre) |
| CA2 | Pago en un solo toque dentro del límite base | 🟡 | El pago se completa (`test_qr_02_el_pin_se_exige_siempre_y_con_el_mueve_ambos_saldos`, `test_qr_06_idempotencia_no_cobra_dos_veces`), pero **siempre pide PIN**: no hay "un solo toque". Desviación a propósito (§8) |
| CA3 | Validación adicional si excede el límite base | ✅ | Más estricto que lo pedido: el servidor exige PIN en **todo** pago (`test_qr_02`, `test_qr_estatico.py · e09_sin_pin_no_paga`, `test_qr_14_un_pin_errado_no_paga`), y además hay tope diario por titular y moneda (`test_qr_limite_diario.py`, DT-15). Es PIN, no huella: el oráculo HU15-CA4 de [`casos-aceptacion-qr-prestamos.md`](casos-aceptacion-qr-prestamos.md) acepta "huella o PIN" |
| CA4 | Rechazar el QR vencido o alterado | ✅ | `test_qr_03_qr_alterado_se_rechaza_sin_descontar`, `test_qr_04_qr_vencido_se_rechaza_sin_descontar`, `test_qr_12_vencido_y_alterado_se_distinguen`, `api/test_qr_firmado.py · 03–07`; revocado: `test_qr_estatico.py · e10_regenerar_revoca_el_anterior`; app: `app/feature/qr/memory_qr_repository_test.dart` |

### HU17 · Motor transaccional (13 SP)

Todo pasa por `app/services/ledger.py · post`.

| CA | Requisito | Veredicto | Evidencia / brecha |
|---|---|---|---|
| CA1 | Validar saldo antes de ejecutar | ✅ | `test_sin_saldo_no_escribe_nada`, `test_dos_debitos_sobre_la_misma_cuenta_se_validan_sumados` |
| CA2 | Bloquear fondos hasta la confirmación final | 🟡 | Bloqueo de fila (`with_for_update`) dentro de la transacción atómica: `test_una_cuenta_ya_cargada_se_relee_tras_el_bloqueo`. No hay retención de fondos separada |
| CA3 | Ninguna transacción dos veces | ✅ | Idempotencia: `test_repetir_la_clave_devuelve_la_original_sin_cobrar_de_nuevo`, `test_la_misma_clave_en_paralelo_cobra_una_sola_vez` (Postgres 18 en CI) |
| CA4 | < 200 ms por transacción | ❌ | Sin medición automatizada |

### HU18 · Libro mayor de partida doble (13 SP)

| CA | Requisito | Veredicto | Evidencia / brecha |
|---|---|---|---|
| CA1 | Débito y crédito por operación | ✅ | `api/test_libro_mayor.py · test_una_transferencia_deja_los_debitos_iguales_a_los_creditos`, `test_unos_asientos_descuadrados_son_un_error_de_programacion` |
| CA2 | UUID por asiento | ✅ | `api/test_motor_de_asientos.py · test_cada_asiento_y_su_transaccion_llevan_un_uuid_propio` (**nueva**, §7) |
| CA3 | Ningún asiento aplicado a medias | ✅ | `test_sin_saldo_no_escribe_nada`, `test_entradas_invalidas_revientan_antes_de_tocar_la_base` |
| CA4 | Cierre contable diario automatizado | ❌ | No existe |

### HU22 · Notificaciones (3 SP)

| CA | Requisito | Veredicto | Evidencia / brecha |
|---|---|---|---|
| CA1–CA4 | Push y correo por transacción/login, con dispositivo y ubicación; reportar actividad | ❌ | El único envío es el OTP (de demo). El informe APF2 la marca "Parcial" en el backlog y "Pendiente" en la trazabilidad: **es pendiente** |

### HU24 · Multidivisa y ahorro (5 SP)

| CA | Requisito | Veredicto | Evidencia / brecha |
|---|---|---|---|
| CA1 | Bolsillos y cuentas USD/EUR | 🟡 | Cuentas en PEN y USD: `api/test_envio_por_cuenta.py · test_envio_y_recarga_en_dolares`. Sin EUR ni bolsillos |
| CA2 | Redondeo automático hacia una meta | ❌ | — |
| CA3 | Rendimientos automáticos | ❌ | — |
| CA4 | Traspasos entre bolsillos y cuentas propias | 🟡 | Entre cuentas propias sí (`test_entre_cuentas_propias_se_puede`); bolsillos no existen |

### Regla "un positivo y un negativo por HU"

Las 11 historias con al menos un CA ✅ o 🟡 respaldado por pruebas tienen ambos
casos. Ejemplos: HU01 (alta con ticket / sin ticket → 403), HU03 (huella /
PIN errado → bloqueo), HU05 (cuentas propias / ajena → 404), HU06 (envío /
sin fondos), HU14 (cobro emitido / cuenta ajena → 404), HU15 (pago con PIN /
QR alterado o vencido → rechazo sin descontar), HU17 (clave nueva / misma
clave con otro monto → 409), HU18 (cuadra / descuadrado → error). HU02 y HU22 no tienen comportamiento propio
que probar.

## 4. Auditoría de corrección numérica

El problema que plantea la sesión (`0.1 + 0.2 != 0.3`) está resuelto por
diseño: **el dinero nunca es un número de coma flotante**.

| Capa | Control | Oráculo |
|---|---|---|
| Dominio (Dart) | `Money`: céntimos `int` + moneda (`packages/core_kernel/lib/src/money.dart`) | `money_test.dart · sumar diez veces S/ 0.10 da exactamente S/ 1.00` |
| Entrada del usuario | `Money.parse` rechaza más de 2 decimales, signos, notación científica y separador de miles | `money_test.dart`, `app/presentation/transfer/money_input_formatter_test.dart` |
| Contrato HTTP | `monto_centimos: StrictInt` en envíos y recargas | `api/test_transferencias.py · test_un_monto_que_no_es_entero_de_centimos_no_mueve_dinero` y `test_una_recarga_que_no_es_entera_de_centimos_es_rechazada` (**nuevas**, §7) |
| Base de datos | `BIGINT` en saldos, asientos y montos | `api/test_consistencia_ddl.py` |
| Libro mayor | Débitos = créditos por transacción; saldo no negativo (`CHECK`) salvo la caja del sistema | `test_libro_mayor.py`, `test_motor_de_asientos.py` |
| Rangos | Monto > 0 y ≤ S/ 2,000.00; el máximo exacto se acepta | `test_un_monto_fuera_de_rango_es_rechazado`, `test_el_monto_maximo_exacto_se_acepta` |
| Transiciones de estado | Una cuenta `bloqueada` no se debita ni recibe; un estado de transacción no previsto se rechaza | `test_una_cuenta_bloqueada_no_se_debita`, `test_un_estado_no_previsto_es_rechazado` |

### 4.1 Cálculo puro de préstamos (#79)

Contrato propuesto para revisión, sin endpoint ni escritura de dinero:
`app.services.loan_schedule.calcular_cronograma`. No acredita HU09/HU12 como
completas: falta integración de solicitud/evaluación/contrato; ver el
contrato de implementación de #85 en `backend-pendientes-andersson.md`.

- Principal y resultados monetarios: `int` de céntimos; nunca `float`.
  Las tasas se reciben y publican como `Decimal`, con contexto local de al
  menos 50 dígitos y 40 dígitos de guarda sobre la escala de entrada; no
  dependen del contexto decimal del llamador. Para raíces mensuales decimales
  exactas se comprueba la potencia 12 con aritmética racional (`Fraction`,
  enteros) y se redondea la cuota/interés por cociente entero: evita perder
  un empate exacto por aproximar la suma de descuentos. No usa `float`.
- Entrada: **TEA efectiva anual en fracción** (`Decimal("0.12")` = 12 %),
  principal, meses y fecha de desembolso explícita. No recibe TCEA como si
  fuera una tasa de interés. Sistema francés, períodos mensuales iguales:
  `i = (1 + TEA) ** (1/12) - 1`; cuota exacta = principal dividido entre
  la suma de los factores de descuento mensuales. También funciona a tasa 0.
- Redondeo monetario: `ROUND_HALF_UP` al céntimo, incluido medio céntimo.
  Se redondea la cuota regular y el interés de cada período sobre el capital
  pendiente. Capital = cuota regular − interés. La última cuota amortiza
  exactamente el capital restante más su interés; puede diferir de la regular.
- Dominio técnico de esta versión: 1–360 meses, principal positivo hasta
  10^12 céntimos, TEA finita entre 0 y 10 (0–1000 %) con hasta 120 posiciones
  decimales para tasas no nulas (incluidos ceros finales). No son límites comerciales
  aprobados. Se rechazan planes cuya cuota redondeada no amortice capital o
  extinga el préstamo antes del último mes: no se inventan cuotas vacías ni
  capital negativo. La API futura debe traducir `ValueError` a su error de entrada.
- Vencimientos: sumar cada mes a la **fecha original**, recortando el día al
  último disponible. 31/01 → 28/02 → 31/03; no arrastrar el recorte de febrero.
  Sin ajuste de feriados ni interés diario; la fecha es un `date`, no el reloj
  del servidor. La capa de desembolso decidirá la fecha de negocio.
- TCEA: tasa interna de retorno de los **pagos ya redondeados**, anualizada
  como `(1 + i_real) ** 12 − 1`, con 16 decimales. En este alcance no existen
  comisiones, seguros ni retenciones: el neto recibido es el principal. Si se
  añaden, el contrato y los flujos para TCEA deben ampliarse; no basta usar TEA.
- Oráculos: `tests/test_cronograma.py` (casos calculados a mano, medio céntimo,
  tasa 0, última cuota, un mes, calendario, límites y conservación del capital).

La elección del método, calendario y alcance sin cargos queda explícita para
revisión por Gian Piero (#79) y la integración con Jeremy (#84). No representa
una tarifa ni una política comercial aprobada.

**Revisión del ZIP de #79.** El parche inicial aprobaba 57 casos, pero perdía
dos fronteras de redondeo: principal 105 céntimos, 2 meses y TEA
`2.138428376721` (10 % mensual) producía una cuota regular de 60 en lugar de
61 (`60.5` exacto); una TEA de `1.01^12 - 1 - 1e-60`, a 150 céntimos y un
mes, producía interés 2 en lugar de 1. Se conservan los oráculos originales
y se añaden regresiones en el empate y a ambos lados. El límite de escala
y la precisión de guarda son parte del contrato técnico propuesto.

**Alcance de TCEA.** Este valor es una TIR mensual anualizada de flujos
equidistantes sin cargos, no una certificación de cálculo regulatorio ni una
TIR por días reales. La SBS define el costo incluyendo los gastos/comisiones
aplicables ([fuente](https://www.sbs.gob.pe/usuarios/aprende-con-la-sbs/aprende-sobre-creditos));
confirmar cargos, seguros y convención temporal antes de exponerlo comercialmente.

## 5. Métrica de completitud funcional (ISO/IEC 25023)

**X = funciones implementadas y probadas ÷ funciones especificadas.** Meta del
curso: X ≥ 0.95.

Conteo de los 96 CA del MVP (actualizado el 2026-11-22 con HU14 y HU15):

| Veredicto | CA | Dónde |
|---|---|---|
| ✅ Cumple | **17** | HU03 (2), HU04 (1), HU05 (2), HU06 (3), HU14 (1), HU15 (3), HU17 (2), HU18 (3) |
| 🟡 Parcial | 16 | HU01 (4), HU02 (2), HU03 (1), HU04 (1), HU05 (1), HU07 (2), HU14 (1), HU15 (1), HU17 (1), HU24 (2) |
| ❌ No cumple | 63 | 19 en las HU con código + 44 de las 11 HU sin código |

| Indicador | Cálculo | Valor |
|---|---|---|
| **X por CA (indicador oficial)** | 17 / 96 | **0.177** |
| X por CA, contando parciales como ½ (referencia) | (17 + 8) / 96 | 0.260 |
| X por HU completa (todos sus CA ✅) | 0 / 24 | 0.000 |
| X por puntos, ponderada por CA cumplidos | 33.5 / 160 SP | 0.209 |
| Y = pruebas aprobadas / ejecutadas | backend 360 / 360 · app 914 / 914 · paquetes 35 / 35 | 1.00 |

Ponderación por puntos: HU03 5·½ + HU04 5·¼ + HU05 5·½ + HU06 8·¾ + HU14 5·¼ +
HU15 5·¾ + HU17 13·½ + HU18 13·¾ = 33.5 SP.

Conteo anterior (corte 2026-10-16): 13 ✅, 14 🟡, 69 ❌; X = 0.135. Ese corte
repartía los ❌ como 18 + 51; la suma por historia da 17 + 52 (el total, 69,
era correcto).

**Lectura.**

- X subió de **0.135** a **0.177** con la épica de QR (HU14 y HU15). Préstamos,
  antifraude y conciliación aún no suman CA. La meta de 0.95 es para la
  entrega final.
- **Y = 1.00 no es corrección funcional.** Que todas las pruebas pasen dice que
  lo que se probó funciona, no que se probó lo que se pidió. Por eso X se mide
  por CA y no por pruebas verdes.
- Cuatro historias (HU05, HU06, HU17, HU18) concentran 10 de los 17 CA
  cumplidos: lo construido es el **núcleo
  transaccional**, que es donde un error cuesta dinero. El pago QR (3 de 4)
  se apoya en ese mismo núcleo.
- Ninguna HU está completa. Las más cercanas (HU06, HU15 y HU18, 3/4 cada una)
  solo necesitan una pieza: CCI/CCE, el pago en un toque (que hoy se descarta
  a propósito, §8) y el cierre diario.

## 6. Idoneidad de la tarea

| Criterio de la sesión | Estado en CuyCash | Mejora propuesta |
|---|---|---|
| Evitar pasos redundantes | Tocar una tarjeta abre sus movimientos; el envío es buscar → cuenta → monto → PIN; el destino se filtra a la misma moneda | Volver a mostrar los frecuentes (un toque al monto): es cambiar `FeatureToggles.frecuentesEnEnvio` |
| Valores por defecto coherentes | La cuenta sueldo solo admite soles; el destino se ofrece ya filtrado a la moneda del origen | Preseleccionar la cuenta de origen con saldo |
| Errores orientados al usuario, no trazas | Ninguna respuesta lleva `traceback`, SQL ni el motor (`test_seguridad_web.py`); la app traduce cada `code` a un texto es-PE desde el ARB | Mantener: toda `GlobalFailure` nueva necesita su texto en el ARB |

## 7. Lo que se agregó en esta auditoría

| Hueco | Cierre |
|---|---|
| `StrictInt` estaba declarado pero ninguna prueba lo demostraba | 14 casos en `test_transferencias.py` (`10.5`, `1000.0`, `0.1 + 0.2`, `"1000"`, `"10.50"`, `true`, `null`), en envíos y recargas. Se comprobó que **fallan** si se cambia `StrictInt` por `int` (6 de 14 rojos: Pydantic convierte `1000.0`, `"1000"` y `true` y el dinero se mueve) |
| HU18 CA2 (UUID por asiento) no tenía oráculo | `test_cada_asiento_y_su_transaccion_llevan_un_uuid_propio` |
| HU06 CA4: la constancia pintaba la fecha, pero ninguna prueba la verificaba | Aserción en `receipt_card_test.dart`, independiente de la zona horaria (probada con `TZ=Asia/Tokyo`) |
| HU22 figuraba como "Parcial" y "Pendiente" a la vez | Queda **pendiente** (§3) |
| Dos líneas base (22 vs. 26 HU) | Nota en [`sla-kpi.md`](sla-kpi.md); este documento usa la de 26 |

## 8. Desviaciones a declarar

| Tema | Especificado | Implementado | Postura |
|---|---|---|---|
| Bloqueo por intentos (HU03 CA3) | 5.º intento | 3.er intento, escalonado | Más estricto a propósito; acordar con el docente o ajustar `IDENTIFIER_MAX_ATTEMPTS` |
| Cierre por inactividad (HU03 CA4) | Tras un período configurado | 5 min por defecto (`SESSION_INACTIVITY_MINUTES`), pide PIN o huella | Ya no es brecha; el valor por defecto es una decisión de producto |
| 200 ms por transacción (HU17 CA4) | < 200 ms | Sin medir | Medir con carga sobre el despliegue antes de afirmarlo |
| Pago QR en un toque (HU15 CA2) | Sin autenticación bajo el límite base | PIN en todo pago, verificado en el servidor | Más estricto a propósito: con monto libre, un umbral sin PIN permite vaciar una cuenta robada con muchos pagos chicos. El riesgo de monto lo acota el tope diario (DT-15). Acordar con el docente |
| Tope del pago QR (HU15 CA3) | "Límite base configurado" | Tope por operación S/ 2,000 (el de envíos) y tope diario S/ 5,000 · US$ 1,500 por titular | Los montos son decisión de producto (`LIMITE_DIARIO_QR`); la app los espeja en `QrLimits` solo para avisar |
| Caducidad del cobro (HU14 CA2) | Configurable | 30 s–24 h en la API; la app fija 15 min | Exponer el selector en la app si el PO lo pide |
| E2E app ↔ backend | — | `verificacion-manual.md` sin ejecutar | Es la V&V de la sesión 20: ver [`vyv.md`](vyv.md) |

## 9. Próximos pasos (por costo/beneficio)

1. **HU03 CA4** · cierre por inactividad en la app: + 1 CA.
2. **HU05 CA2** · mostrar el saldo contable junto al disponible: + ½ CA sin backend.
3. **HU07** · encender los frecuentes y agregar editar: CA1 y CA4 a ✅.
4. **HU02** · usar el OTP existente para la activación del alta: CA1–CA3.
5. **HU17 CA4** · medir latencia con carga y publicar el resultado.
6. Recalcular X al cierre de cada sprint con esta misma tabla.


## Integración backend de #40, #85 y #88

Esquema versionado con Alembic: [procedimiento de migración](migraciones.md).
Se añade `users.rol` (`titular` por defecto, `admin` solo por operación
administrativa) y las tablas `loan_applications` (condiciones y aprobación),
`loans` (solicitud/transacción únicas) y `loan_installments` (capital/interés/saldo
en BIGINT y número único por préstamo). TEA/TCEA se conservan como texto decimal.
Contrato HTTP, límites y dependencias: [integración de tareas](backend-pendientes-andersson.md).
Pruebas: `test_migrations.py`, `test_loan_disbursement.py`, `test_admin_queries.py`.
Las pruebas del desembolso parten de condiciones aprobadas sembradas por fixture;
no acreditan el flujo completo de solicitud/evaluación/contrato de HU10–HU12.
El conteo histórico de completitud de la línea base no se modifica: faltan esa
integración y las pruebas integrales; HU28 sigue fuera de la línea base.
