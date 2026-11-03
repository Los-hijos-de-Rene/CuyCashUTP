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

## Criterio de salida

- **28/28 escenarios definidos:** 14 positivos y 14 negativos.
- **Revisión del PO:** pendiente; el revisor debe confirmar la correspondencia
  CA ↔ escenario antes de que #77, #78, #84, #85 y #86 los automaticen.
- **Ejecución:** pendiente de #91. Un escenario no se marcará aprobado hasta
  existir la API/app y una prueba automatizada con evidencia reproducible.
