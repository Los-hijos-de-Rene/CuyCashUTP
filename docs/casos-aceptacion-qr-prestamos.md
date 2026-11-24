# Casos de aceptación previos al código · QR y préstamos

Tarjeta: **#82** · Dueño: Gian Piero (`@pierog30`) · Revisor/PO: Jair C.
(`@fardcrex`) · Estado del documento: **listo para revisión del PO**.

Estos escenarios fijan los oráculos antes de implementar las API y pantallas.
No prueban que la función ya exista. Cada criterio comprometido tiene un caso
positivo y uno negativo, y conserva la numeración acordada en las tarjetas
#77, #78, #84, #85 y #86.

## Convenciones comunes

- El dinero viaja y se persiste como entero de céntimos; nunca como `float`.
- Un rechazo no modifica saldos, asientos, cuotas ni estados persistidos.
- Cada operación monetaria usa una clave de idempotencia y devuelve un ID
  trazable.
- Los tiempos se comparan en UTC y el cliente presenta fecha y hora en es-PE.
- `✅` significa escenario definido; la ejecución se registrará en la #91.

## HU09 · Simulador de préstamo

| Escenario | Tipo | Dado | Cuando | Entonces | Oráculo |
|---|---|---|---|---|---|
| HU09-CA1-P | Positivo | Un cliente autenticado ingresa S/ 5,000.00, 12 meses y una TEA permitida | Solicita la simulación | Se devuelven cuota, interés, capital, fechas y TCEA; la suma del capital es exactamente 500000 céntimos | #84 · cálculo #79 |
| HU09-CA1-N | Negativo | El monto es cero, negativo, no entero en céntimos o supera el límite técnico | Solicita la simulación | La API responde error de validación y no crea solicitud ni cronograma persistido | #84 · cálculo #79 |
| HU09-CA2-P | Positivo | El monto, plazo y TEA están dentro del dominio técnico | Se calcula el cronograma provisional | La última cuota absorbe el residuo y el saldo final queda en cero, incluso a tasa cero o plazo de un mes | #84 · cálculo #79 |
| HU09-CA2-N | Negativo | El plazo está fuera de 1–360 meses o la tasa no es finita/representable | Se intenta calcular | La API rechaza la entrada con un código estable; no aproxima ni inventa cuotas | #84 · cálculo #79 |
| HU09-CA4-P | Positivo | Existe una simulación válida visible en la app | El cliente elige compartir | Se genera un resumen con monto, plazo, TEA, TCEA, cuota y fecha, sin DNI, token ni número completo de cuenta | #86 |
| HU09-CA4-N | Negativo | La simulación expiró, está incompleta o contiene datos inválidos | El cliente intenta compartir | La app no comparte un resultado parcial y explica que debe recalcular | #86 |

## HU10 · Solicitud y evaluación de préstamo

| Escenario | Tipo | Dado | Cuando | Entonces | Oráculo |
|---|---|---|---|---|---|
| HU10-CA1-P | Positivo | El cliente autenticado aceptó el tratamiento de datos y completó los campos obligatorios | Envía la solicitud | Se crea un expediente único con ID, fecha, consentimiento versionado y estado inicial | #84 |
| HU10-CA1-N | Negativo | El consentimiento no fue aceptado | Intenta enviar la solicitud | Se rechaza antes de evaluar y no se persiste expediente ni datos crediticios | #84 |
| HU10-CA2-P | Positivo | DNI, ingresos, obligaciones, cuenta de desembolso y simulación son válidos | Envía la solicitud | La API acepta los datos completos y ejecuta una sola evaluación | #84 |
| HU10-CA2-N | Negativo | Falta un dato obligatorio o la cuenta no pertenece al titular | Envía la solicitud | Se informa el campo inválido y no se inicia el score | #84 |
| HU10-CA4-P | Positivo | Existe una solicitud completa | El score interno la evalúa | El estado final es `aprobado`, `rechazado` o `en_revision`, con motivo comprensible y auditable | #84 |
| HU10-CA4-N | Negativo | El motor no dispone de datos suficientes o falla una dependencia | Intenta evaluar | No aprueba por defecto; conserva `en_revision`/error controlado y registra trazabilidad sin exponer reglas sensibles | #84 |

## HU12 · Desembolso y cronograma definitivo

| Escenario | Tipo | Dado | Cuando | Entonces | Oráculo |
|---|---|---|---|---|---|
| HU12-CA1-P | Positivo | Una solicitud aprobada tiene oferta aceptada, cuenta propia activa y clave de idempotencia nueva | Se confirma el desembolso | `ledger.post` acredita una vez el monto aprobado, crea partida doble e identifica la transacción | #85 |
| HU12-CA1-N | Negativo | La solicitud no está aprobada, la cuenta está bloqueada o no pertenece al cliente | Se intenta desembolsar | Se rechaza sin abono, sin deuda y sin asientos parciales | #85 |
| HU12-CA2-P | Positivo | El desembolso fue confirmado | Se consulta el préstamo | Se muestra el cronograma definitivo; capital total = principal y fechas/cuotas coinciden con el contrato | #85 |
| HU12-CA2-N | Negativo | Se reintenta el mismo desembolso o falla la escritura de una cuota | Se procesa la petición | La misma clave devuelve el resultado previo; una falla revierte toda la operación y no duplica dinero ni cronograma | #85 |

## HU14 · Generación de QR de cobro

| Escenario | Tipo | Dado | Cuando | Entonces | Oráculo |
|---|---|---|---|---|---|
| HU14-CA1-P | Positivo | Un comercio autenticado tiene una cuenta PEN activa e ingresa monto, concepto y vigencia permitidos | Genera el cobro | El servidor emite un QR firmado con versión, cuenta, monto en céntimos, referencia única y expiración UTC | #77, #78 |
| HU14-CA1-N | Negativo | El monto es inválido, la cuenta no pertenece al comercio o la vigencia está fuera del rango | Intenta generar | Se rechaza con un error de campo y no se emite token QR utilizable | #77, #78 |
| HU14-CA2-P | Positivo | El servidor emitió un QR vigente | La app lo presenta o comparte | El contenido visual representa exactamente el token firmado y muestra monto, concepto y vencimiento | #77, #78 |
| HU14-CA2-N | Negativo | El QR caducó o fue reemplazado por uno nuevo | Se intenta volver a mostrar/compartir como vigente | La app lo marca vencido y exige regenerarlo; no altera localmente su monto ni firma | #77, #78 |

## HU15 · Lectura y validación de QR

| Escenario | Tipo | Dado | Cuando | Entonces | Oráculo |
|---|---|---|---|---|---|
| HU15-CA1-P | Positivo | La cámara lee un QR CuyCash bien formado | El cliente escanea | Antes de confirmar se muestran comercio enmascarado, importe, concepto y vigencia | #78 |
| HU15-CA1-N | Negativo | La cámara no tiene permiso o el contenido no corresponde al formato soportado | Se intenta escanear | La app informa el problema, permite reintentar y no habilita el pago | #78 |
| HU15-CA2-P | Positivo | El token está firmado, vigente y corresponde a una cuenta activa | La app pide validarlo | La API devuelve los datos canónicos sin ejecutar todavía el pago | #77 |
| HU15-CA2-N | Negativo | Cambió un byte del monto/firma o la expiración ya pasó | Se valida | Se rechaza antes de afectar saldo y no se revela información adicional del comercio | #77 |
| HU15-CA3-P | Positivo | El QR es válido, hay saldo y el importe está bajo el límite reforzado | El cliente confirma una vez | Se crea un solo `pago_qr` y se entrega constancia con ID y estado | #77 |
| HU15-CA3-N | Negativo | No hay saldo, moneda incompatible o una cuenta está bloqueada | Se confirma | Se devuelve un error es-PE estable y los saldos/asientos quedan intactos | #77, #78 |
| HU15-CA4-P | Positivo | El importe supera el límite base y el cliente valida huella o PIN | Confirma el pago | La autorización reforzada se verifica en servidor y el pago se contabiliza una sola vez | #77 |
| HU15-CA4-N | Negativo | Falta la autenticación reforzada, es inválida o se reenvía la misma clave con otros datos | Se intenta pagar | Se rechaza; el reintento idéntico no duplica el cargo y un cambio de huella devuelve conflicto | #77 |

## Ejecución de HU14 y HU15 (2026-11-22)

La API y la app de QR ya existen (#142, #143, #144). Esta tabla registra qué
prueba ejecuta cada escenario. Las filas de arriba **no se cambiaron**: son
el acuerdo previo al código. Las diferencias con la implementación se
declaran aquí y en la §8 de [`idoneidad-funcional.md`](idoneidad-funcional.md).
Rutas: `api/` = `services/api/tests/`, `app/` = `apps/mobile/test/`.

| Escenario | Estado | Prueba | Nota |
|---|---|---|---|
| HU14-CA1-P | ✅ | `api/test_qr_flujo.py · test_qr_01`, `app/presentation/qr/qr_charge_screen_test.dart` (con monto y concepto) | El token ya no lleva cuenta ni monto: es una referencia firmada a `qr_codigos`, donde viven monto, cuenta y expiración (`api/test_qr_firmado.py · test_qr_08_el_token_no_revela_nada_del_cobro`) |
| HU14-CA1-N | 🟡 | `test_qr_08_no_se_puede_emitir_para_cuenta_ajena` (404); app: "sin monto no genera" | Sin prueba de API para monto inválido ni vigencia fuera de 30 s–24 h al emitir (Pydantic los rechaza, pero no hay oráculo) |
| HU14-CA2-P | ✅ | `qr_charge_screen_test.dart · la tarjeta que se comparte es una imagen autosuficiente` | Se comparte una imagen con QR, monto, concepto y vencimiento; nunca el token en texto |
| HU14-CA2-N | 🟡 | Reemplazado: `api/test_qr_estatico.py · e10_regenerar_revoca_el_anterior` | La app no marca como vencido un cobro que sigue en pantalla; lo rechaza el servidor al pagarlo (`test_qr_04`) |
| HU15-CA1-P | ✅ | `qr_pay_screen_test.dart · el escaneo muestra nombre y monto antes de confirmar` | En "Mi QR" no hay monto que mostrar: el pagador lo escribe y ve el cupo del día (grupo monto libre) |
| HU15-CA1-N | 🟡 | `qr_pay_screen_test.dart · una imagen sin QR avisa y se queda escaneando` | Sin prueba del permiso de cámara denegado |
| HU15-CA2-P | ✅ | `test_qr_01`, `test_qr_estatico.py · e04_validar_muestra_a_quien_sin_monto_y_no_mueve_dinero` | — |
| HU15-CA2-N | ✅ | `test_qr_03`, `test_qr_04`, `test_qr_12`, `test_qr_16_un_token_inexistente_firmado_no_revela_nada` | — |
| HU15-CA3-P | ✅ | `test_qr_02_el_pin_se_exige_siempre_y_con_el_mueve_ambos_saldos`, `qr_pay_screen_test.dart · pagar pide PIN y termina en la constancia` | — |
| HU15-CA3-N | 🟡 | `test_qr_09_saldo_insuficiente_no_genera_movimiento`, `e13_no_se_paga_a_si_mismo_con_la_misma_cuenta` | Sin prueba de QR para moneda incompatible ni cuenta bloqueada (los cubre `ledger.post`, probado en envíos) |
| HU15-CA4-P | ✅ | `test_qr_02`, `e05_el_pagador_elige_el_monto_y_se_registra_como_pago_qr` | **Distinto de lo acordado:** el PIN se exige en todo pago, no solo sobre un límite base |
| HU15-CA4-N | ✅ | `e09_sin_pin_no_paga`, `test_qr_14_un_pin_errado_no_paga`, `test_qr_06`, `e07_reintentar_con_la_misma_clave_no_cobra_dos_veces` (otra data con la misma clave → 409 `IDEMPOTENCY_KEY_REUSED`) | — |

Resultado: 8 ✅ y 4 🟡 de 12. Los 🟡 son negativos sin oráculo propio, no
comportamientos ausentes. Fuera de estos escenarios, el límite diario
(DT-15) se ejecuta en `api/test_qr_limite_diario.py`, con concurrencia en
Postgres (`test_limite_09`).

La numeración de este documento no coincide con la del informe APF2: aquí
HU15-CA2 es "validar" y HU15-CA4 la autenticación reforzada; en el informe,
CA3 es la validación adicional y CA4 el rechazo de un QR vencido o alterado.
La RTM usa la del informe.

## Criterio de salida

- **28/28 escenarios definidos:** 14 positivos y 14 negativos.
- **Revisión del PO:** pendiente; el revisor debe confirmar la correspondencia
  CA ↔ escenario antes de que #77, #78, #84, #85 y #86 los automaticen.
- **Ejecución:** pendiente de #91. Un escenario no se marcará aprobado hasta
  existir la API/app y una prueba automatizada con evidencia reproducible.
