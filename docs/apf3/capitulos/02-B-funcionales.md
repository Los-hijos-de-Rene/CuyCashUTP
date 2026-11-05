# B. Pruebas funcionales automatizadas

**Responsable:** Gian Piero Gonzales · **Tarjetas:** #96 y #97 · **Corte:**
02/11/2026 · **Commit probado:** `44a9c36`.

El objetivo es verificar completitud, corrección e idoneidad funcional con
criterios trazables. Se distingue entre una prueba que termina en verde y un
criterio de aceptación realmente cumplido: ejecutar líneas no demuestra por sí
solo que el producto entregue toda la función solicitada.

## B.1 Frameworks utilizados y justificación

| Capa | Framework | Justificación técnica |
|---|---|---|
| API | `pytest 8.3.3`, `pytest-asyncio` y `httpx` | Permiten probar servicios asíncronos y contratos HTTP completos, incluyendo código, cuerpo y efectos en base. Los fixtures aíslan cada caso y hacen repetible la preparación de titulares, cuentas y sesiones. |
| Persistencia | SQLAlchemy asíncrono con SQLite local y PostgreSQL 18 en CI | SQLite da realimentación rápida; PostgreSQL 18 valida restricciones, bloqueo de filas y concurrencia con el mismo motor previsto para producción. Una prueba local verde no sustituye el job PostgreSQL. |
| App | `flutter_test` y `bloc_test` | `flutter_test` valida widgets, navegación y accesibilidad; `bloc_test` comprueba estados, transiciones y errores sin depender del renderizado. Los contratos de repositorio comparan implementaciones `Memory*` y `Http*`. |
| Cobertura | `pytest-cov`/`coverage.py` y `flutter test --coverage` | Miden líneas ejecutadas y detectan módulos sin ejercicio. La cobertura se interpreta junto con aserciones y RTM; no equivale a ausencia de defectos. |
| Evidencia | JUnit XML y Cobertura XML | Son formatos reproducibles y consumibles por CI. Conservan caso, duración, estado y cobertura sin transcribir resultados manualmente. |

## B.2 Listado trazable de 20 criterios

La selección cubre las cinco HU operativas principales de identidad, consulta,
transferencias y contabilidad. El resultado de la última columna es el
**veredicto del CA**, no solo el color del test. `🟡` indica que la parte citada
pasó, pero queda una condición funcional sin implementar o medir.

| ID | Requisito / criterio | Precondición | Pasos | Resultado esperado | Archivo y nombre exacto de la prueba | Resultado | Evidencia |
|---|---|---|---|---|---|---|---|
| HU03-CA1 | Ingreso facial <1.5 s | Usuario registrado | Intentar autenticación facial y medir | Sesión en menos de 1.5 s | No existe prueba ni login facial | ❌ | RTM §3 |
| HU03-CA2 | Huella o PIN alternativo | Biometría vinculada | Autenticar con credencial válida | Sesión segura creada | `test_biometria.py::test_activar_y_entrar_con_huella` | ✅ | `pytest.xml` |
| HU03-CA3 | Bloqueo tras fallos y aviso | DNI registrado | Fallar el PIN repetidamente | Bloqueo y notificación | `test_registro_y_login.py::test_tres_fallos_bloquean_el_dni_y_ni_el_pin_correcto_entra` | 🟡 | Bloquea al 3.er intento; falta aviso |
| HU03-CA4 | Cierre por inactividad | Sesión abierta | Superar tiempo inactivo | Token/sesión revocados | No existe temporizador ni prueba | ❌ | RTM §3 |
| HU05-CA1 | Cuentas propias, tipo, número enmascarado y saldo | Dos titulares | Consultar `/v1/accounts` | Solo cuentas propias con datos permitidos | `test_cuentas_y_movimientos.py::test_solo_devuelve_las_cuentas_propias` | ✅ | `pytest.xml` |
| HU05-CA2 | Saldo contable y disponible con retenciones | Cuenta con fondos retenidos | Consultar saldos | Ambos saldos reflejan la retención | No existe modelo de retenciones | 🟡 | API entrega ambos campos, hoy iguales |
| HU05-CA3 | Movimientos de la cuenta seleccionada | Varias cuentas con operaciones | Consultar historial por cuenta | No mezcla movimientos | `test_cuentas_y_movimientos.py::test_el_historial_no_mezcla_movimientos_de_otras_cuentas` | ✅ | `pytest.xml` |
| HU05-CA4 | Exportación PDF/Excel | Historial disponible | Solicitar exportación | Archivo descargable coherente | No existe exportación | ❌ | RTM §3 |
| HU06-CA1 | Transferencia propia inmediata y sin costo | Dos cuentas PEN del titular | Enviar S/10.00 | Débito y crédito exactos | `test_envio_por_cuenta.py::test_entre_cuentas_propias_se_puede` | ✅ | `pytest.xml` |
| HU06-CA2 | Interbancaria CCI/CCE | CCI válido y red disponible | Confirmar envío | Titular validado y orden emitida | No existe conector interbancario | ❌ | RTM §3 |
| HU06-CA3 | Rechazo sin fondos sin afectar saldos | Saldo menor al monto | Intentar enviar | `INSUFFICIENT_FUNDS`, cero asientos | `test_transferencias.py::test_sin_saldo_suficiente_responde_insufficient_funds` | ✅ | `pytest.xml` |
| HU06-CA4 | Comprobante completo | Transferencia confirmada | Consultar/compartir constancia | Fecha, monto, cuentas y operación | `receipt_card_test.dart::muestra monto, contraparte, motivo, estado, fecha y operación` | ✅ | `flutter-tests.json` |
| HU17-CA1 | Validar saldo antes de ejecutar | Cuenta con saldo insuficiente | Publicar débito | No se escribe nada | `test_motor_de_asientos.py::test_sin_saldo_no_escribe_nada` | ✅ | `pytest.xml` |
| HU17-CA2 | Bloquear fondos hasta confirmar | Cuenta leída por dos operaciones | Bloquear y releer | Se usa el saldo actual bajo bloqueo | `test_motor_de_asientos.py::test_una_cuenta_ya_cargada_se_relee_tras_el_bloqueo` | 🟡 | Hay bloqueo de fila; no retención separada |
| HU17-CA3 | Idempotencia | Transferencia ya confirmada | Repetir la misma clave | Devuelve la original sin nuevo cargo | `test_motor_de_asientos.py::test_repetir_la_clave_devuelve_la_original_sin_cobrar_de_nuevo` | ✅ | `pytest.xml` |
| HU17-CA4 | Procesamiento <200 ms | Entorno de carga controlado | Medir transacción p95/p99 | Duración menor a 200 ms | No existe prueba de rendimiento | ❌ | No medido |
| HU18-CA1 | Débito = crédito | Operación autorizada | Contabilizar transferencia | Sumas iguales por transacción | `test_libro_mayor.py::test_una_transferencia_deja_los_debitos_iguales_a_los_creditos` | ✅ | `pytest.xml` |
| HU18-CA2 | UUID por asiento | Transacción con dos asientos | Persistir y consultar IDs | IDs propios, válidos y distintos | `test_motor_de_asientos.py::test_cada_asiento_y_su_transaccion_llevan_un_uuid_propio` | ✅ | `pytest.xml` |
| HU18-CA3 | Atomicidad, sin asiento parcial | Entrada inválida o saldo insuficiente | Intentar publicar | Rollback completo | `test_motor_de_asientos.py::test_entradas_invalidas_revientan_antes_de_tocar_la_base` | ✅ | `pytest.xml` |
| HU18-CA4 | Cierre contable diario | Día de negocio cerrado | Ejecutar conciliación | Diferencias detectadas y auditadas | No existe proceso de cierre | ❌ | RTM §3 |

### Corrección numérica obligatoria

| Caso | Control verificado | Resultado 02/11/2026 |
|---|---|---|
| Dinero sin `double` | Montos HTTP y persistencia son enteros de céntimos; más de dos decimales se rechazan | ✅ `test_un_monto_que_no_es_entero_de_centimos_no_mueve_dinero` |
| Envío de S/125.50 | UAT-1 usa `12550` céntimos y verifica ambos saldos | ✅ `test_uat1_enviar_dinero_a_otro_titular_y_que_ambos_lados_cuadren` |
| Partida doble | Total débito = total crédito por ID de transacción | ✅ `test_una_transferencia_deja_los_debitos_iguales_a_los_creditos` |

## B.3 Ejecución reproducible

Comando ejecutado desde `services/api` en Windows 11, Python 3.12.10:

```powershell
.\.venv\Scripts\python.exe -m pytest -q --cov=app --cov-report=term `
  --cov-report=xml:..\..\docs\apf3\evidencias\gian-piero\cobertura-backend.xml `
  --junitxml=..\..\docs\apf3\evidencias\gian-piero\pytest.xml
```

Resultado final: **428 aprobadas, 0 fallidas, 4 omitidas y 22 advertencias**
en **210.76 s**. Las omisiones dependen de capacidades no disponibles en el
host local, entre ellas pruebas específicas de PostgreSQL y `time.tzset` de
POSIX; el job CI PostgreSQL debe confirmar las primeras.

La primera corrida detectó tres incompatibilidades portables en Windows:
codificación de `schema.sql`/salida del generador DDL y uso incondicional de
`time.tzset`. Se fijó UTF-8 explícito y se convirtió el caso POSIX en una
omisión declarada. La repetición dirigida dio **27 aprobadas, 1 omitida** y la
repetición completa produjo el resultado verde anterior.

Evidencias reproducibles:

- `docs/apf3/evidencias/gian-piero/pytest.xml`
- `docs/apf3/evidencias/gian-piero/cobertura-backend.xml`
- `docs/apf3/evidencias/gian-piero/pytest-resumen.txt`
- `docs/apf3/evidencias/gian-piero/entorno-ejecucion.txt`
- `docs/apf3/evidencias/gian-piero/ejecucion-backend.png`

La app se ejecutó con la misma versión fijada en CI, Flutter 3.41.7:

```powershell
flutter analyze
flutter test --coverage --coverage-path=reports/lcov.info `
  --file-reporter=json:reports/flutter-tests.json
```

`flutter analyze` terminó con **0 problemas**. La suite móvil terminó con
**905 aprobadas, 0 fallidas y 2 omitidas**. Además, `core_kernel` aprobó 24/24
y `design_system` 12/12. Los reportes reproducibles se guardaron como
`flutter-tests.json`, `cobertura-app.lcov` y `flutter-resumen.txt` dentro de la
carpeta de evidencias de Gian Piero. La imagen `ejecucion-flutter.png` resume
visualmente esos mismos reportes y declara su procedencia.

## B.4 Cobertura

| Componente | Líneas/sentencias | Sin ejecutar | Cobertura | Estado |
|---|---:|---:|---:|---|
| Backend total | 1,916 | 72 | **96 %** | Medido localmente |
| `services/ledger.py` | 73 | 1 | 99 % | Crítico, medido |
| `routers/transfers.py` | 90 | 1 | 99 % | Crítico, medido |
| `services/loan_schedule.py` | 103 | 1 | 99 % | Cálculo puro, sin API todavía |
| `routers/kyc.py` | 72 | 9 | 88 % | Requiere ampliar casos |
| `services/notifier.py` | 31 | 13 | 58 % | Principal brecha de backend |
| App Flutter | 8,434 | 1,942 | **76.97 %** | Medido con Flutter 3.41.7 |

La cobertura móvil se calculó desde el LCOV real: 6,492 líneas ejecutadas de
8,434 líneas encontradas en 254 archivos. El reporte conserva el detalle por
archivo para que CI o un visor LCOV puedan reproducir el porcentaje.

## B.5 Métricas ISO/IEC 25023 y cumplimiento

| Métrica | Fórmula | Resultado al 02/11/2026 | Interpretación |
|---|---|---:|---|
| Casos backend | aprobados / fallidos / omitidos | 428 / 0 / 4 | 432 recolectados |
| Casos app | aprobados / fallidos / omitidos | 905 / 0 / 2 | 907 recolectados |
| Paquetes compartidos | aprobados / fallidos | 36 / 0 | 24 `core_kernel` + 12 `design_system` |
| Cumplimiento de ejecución | aprobados ÷ recolectados | **99.6 %** (1369/1375) | Supera meta de 90 %; las 6 omisiones no se ocultan |
| Corrección ejecutada `Y` | verdes ÷ ejecutados | **100 %** (1369/1369) | No hubo fallo entre los casos que sí corrieron |
| Completitud funcional `X` | CA implementados y automatizados ÷ CA MVP | **12.5 %** (12/96) | Los CA parciales y los oráculos previos al código no cuentan |
| Cobertura backend | sentencias ejecutadas ÷ sentencias | **96 %** | No implica ausencia de defectos |
| Cobertura app | líneas cubiertas ÷ líneas | **76.97 %** (6492/8434) | Reporte LCOV reproducible |

### Observaciones y limitaciones

1. La ejecución local usa SQLite; bloqueo de fila e idempotencia concurrente
   deben reconfirmarse en PostgreSQL 18 mediante CI.
2. La suite Flutter se ejecuta en el host de pruebas y sustituye sensores con
   dobles controlados; no demuestra cámara, huella ni rendimiento en Android.
3. El SLA transaccional de 200 ms y el ingreso de 1.5 s no se midieron con una
   herramienta de carga; permanecen como CA no cumplidos.
4. QR y préstamos tienen oráculos previos en
   `docs/casos-aceptacion-qr-prestamos.md`, pero las API/pantallas necesarias
   para #91 aún no existen en este commit. El cálculo puro del cronograma no
   acredita por sí solo HU09/HU12.
5. Un 96 % de cobertura solo indica líneas recorridas. La calidad depende de
   los oráculos, límites, datos negativos y revisión de código.

## B.6 UAT y acta de validación (#97)

Las pruebas automatizadas UAT-1..3 del backend están verdes dentro de la suite.
La validación visual completa sigue **pendiente** porque Docker Desktop no está
activo y Flutter/emulador no están disponibles en este host. No se firma un
acta manual sin recorrer la app real. Para cerrar #97 faltan:

- levantar API y app local;
- sembrar Ana/Luis;
- ejecutar cada paso de `docs/verificacion-manual.md`;
- completar `docs/vyv.md` §5 con capturas, discrepancias y firma del revisor.

Esta separación evita presentar una prueba HTTP automatizada como si fuera una
aceptación de usuario en emulador.
