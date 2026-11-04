# Integración de las tareas #40, #85 y #88

Esta rama parte del cálculo puro de #79 (PR #94). La entrega es código y pruebas
para revisión. La integración de la app, aprobación del equipo y despliegue son
pasos posteriores. No cierra automáticamente issues del equipo.

## Desembolso (#85)

`POST /v1/loans/applications/{application_id}/disbursement`, sesión del titular,
JSON `{account_id, idempotency_key, pin}`. Devuelve 201 la primera vez, 200 al
repetir la misma clave/cuenta, 409 si la solicitud ya se desembolsó con otra
clave/cuenta. Cuenta o solicitud ajenas: 404. Condiciones no aprobadas o contrato
no aceptado: 409. Moneda distinta: 400. PIN y bloqueos usan la autorización
compartida; las condiciones se validan antes de gastar intentos del PIN.

La aprobación se bloquea en PostgreSQL durante la operación. Cuenta acreditada,
contrapartida en caja del sistema, préstamo y cuotas definitivas se confirman en
una sola transacción. Todo dinero pasa por `ledger.post`; ningún importe/tasa del
cliente decide cuánto se desembolsa. Una restricción única por solicitud refuerza
la prohibición de doble desembolso, incluso con distintas claves concurrentes.
Los reintentos devuelven las cuotas almacenadas: no recalculan con otra fecha.

**Contrato con #80/#84:** se añaden tablas mínimas `loan_applications`, `loans`
y `loan_installments`. La API de evaluación, que no forma parte de esta entrega,
debe escribir las condiciones aprobadas (principal en céntimos, moneda, meses,
TEA decimal en texto), estado `aprobado`, `approved_at` y
`contrato_aceptado_at` tras aprobación/aceptación verificadas. El endpoint no
permite crear ni aprobar solicitudes. Estos nombres deben acordarse con los
responsables de tablas/evaluación/contrato; no se declaran completas esas tareas.
El caso integral desde la app todavía requiere esa integración.

Método, redondeo, TCEA sin cargos y límites conservan las decisiones propuestas
en `idoneidad-funcional.md` §4.1. No certifica cálculo regulatorio ni consentimiento
legal. La fecha de desembolso y vencimientos se fijan en UTC.

## Consultas administrativas (#88)

Todas las rutas requieren sesión activa y `users.rol = 'admin'`, comprobado de
nuevo en cada petición. El registro deja `titular`; no hay ruta para ascender rol.
Otorgar/revocar admin requiere una operación del administrador de la base con
trazabilidad. No se ha otorgado ese rol a ninguna cuenta real.

| GET | Contenido |
|---|---|
| `/v1/admin/registrations` | Altas y estado KYC, DNI enmascarado |
| `/v1/admin/kyc` | Veredictos, sin imágenes ni distancia facial |
| `/v1/admin/operations?day=AAAA-MM-DD` | Asientos de operaciones del día UTC, cuenta enmascarada |
| `/v1/admin/reconciliation` | Débitos/créditos por moneda y saldo contra asientos de cada cuenta |
| `/v1/admin/lockouts` | Bloqueos vigentes con sujeto enmascarado |

Las listas aceptan `offset >= 0` y `1 <= limit <= 100` (50 por defecto), con orden
estable. Operaciones muestra una fila por asiento, con `transaction_id` para
agrupar; no debe sumarse débito y crédito como si fueran dos operaciones.
El cuadre es histórico, por transacción/moneda y por cuenta; detecta errores
opuestos entre transacciones o cuentas aunque
la suma global coincida. No sustituye el cierre contable diario (#87).
Los endpoints no cambian datos de negocio; la sesión conserva su renovación
normal. Las respuestas tienen `Cache-Control: no-store`.

**Contrato con #81:** la protección por rol y CORS exacto ya están implementados.
`ADMIN_CORS_ORIGINS` enumera orígenes HTTP(S) exactos separados por coma;
vacío deniega todos. No hay comodines y solo se admiten GET/Authorization para
el panel. El origen real del panel depende de #89 y no se inventa. Las rutas
siguen exigiendo admin incluso para un origen permitido.


## Actualización de integración (2026-11-04 UTC)

PR #94 ya está fusionado. PR #95 tiene base `main` y conserva el historial,
con `main` integrado mediante merge (sin reescritura). #80/#81 son ahora
responsabilidad de Andersson. CORS admite únicamente orígenes exactos definidos
en `ADMIN_CORS_ORIGINS` (separados por coma); vacío deniega todos. Solo GET,
sin credenciales de cookie; Authorization se permite en el preflight. RBAC sigue
siendo obligatorio incluso para el origen autorizado. No se inventa ni habilita
un dominio de panel que el equipo no haya publicado.

El job de contrato app/API aplica Alembic sobre su SQLite desechable antes de
arrancar: el arranque ya no crea tablas. Producción requiere el procedimiento
de adopción con respaldo de `migraciones.md`, todavía sin ejecutar.


## Inventario de responsabilidades (auditoría 2026-11-04 UTC)

Autor local configurado: AnderssonEspinoza, correo del commit #94 reconocido
por la API de GitHub como AnderssonEspinoza. Árbol inicial limpio; dos rutas
locales son el mismo directorio mediante enlace. Cuenta gh correcta. No se
reescribe historial ni se fusiona ningún PR desde esta sesión.

| Issue / título | Estado real y CA | Código existente / faltante | Responsable / revisor | Pruebas y dependencia | Rama / PR / evidencia |
|---|---|---|---|---|---|
| #40 Migraciones Alembic | Implementado para revisión; falta aprobación y adopción operativa | 0001 legado, 0002 rol/préstamos, adopción exacta, arranque valida revisión; no migración productiva ejecutada | Andersson / Jeremy | `test_migrations.py`: subida, conservación usuario/saldos/asientos, esquema desconocido rechazado; PostgreSQL real y SQLite | `feat/40-85-88-backend`, #95; `migraciones.md` |
| #79 Cuota/TCEA/cronograma | Fusionado #94, issue abierta; sin revisión independiente registrada | `loan_schedule.py` ya cumple enteros, HALF_UP, residuo final, conservación capital y TCEA sobre flujos; no duplicado | Andersson / Gian Piero | `test_cronograma.py`; casos 1 mes, medio céntimo, capital total y negativos; incluido en suite focal 130/130 | `feat/79-calculo-cronograma`, #94 en main; no cerrar sin regularizar revisión de DoD |
| #80 Modelo préstamos | Implementado para revisión | `LoanApplication`, `Loan`, `LoanInstallment`, FK/CHECK/UNIQUE/índices y schema.sql; falta acuerdo de contrato con #84 | Andersson / Jeremy | `test_consistencia_ddl.py`, migraciones; depende #40 y contrato Jeremy | #95; `modelo-datos.md`, `schema.sql` |
| #81 RBAC/CORS | Implementado para revisión | `current_admin` por petición, titular por defecto, CORS exacto sin comodines; dominio real del panel aún no publicado, vacío deniega | Andersson / Gian Piero | `test_sesion_requerida.py`, `test_admin_cors.py`, revocación rol y parámetros maliciosos; AC-15 actualizado | #95, `catalogo-controles.md` |
| #85 Desembolso | Implementado y probado como componente; pendiente #84 para recorrido integral | Aprobación/contrato/PIN/titularidad, ledger.post atómico, UNIQUE y bloqueo de solicitud, cuotas persistidas; no existe API evaluadora #84 | Andersson / Jeremy | HTTP positivos/negativos, rollback y dos carreras PostgreSQL con claves iguales/distintas, clave de otra solicitud rechazada | #95; `test_loan_disbursement.py`, contrato arriba |
| #88 Consultas admin | Implementado para revisión | Altas/KYC/operaciones/cuadre/bloqueos, enmascarado, solo GET; cuadre con totales y páginas acotadas sin ocultar errores | Andersson / Gian Piero | `test_admin_queries.py`; autorización, fechas, negativos, descuadres que se cancelan y paginación | #95 |
| #102 Validación nube | Parcial y bloqueada para cierre | Humo, validación HTTP, captura, UAT seguro y capítulo E; faltan UAT nube con KYC válido, SQL Neon y Android | Andersson / Jeremy | Humo productivo 0 fallos; UAT productivo 403 KYC_REQUIRED; UAT local aprobado; sin Neon ni teléfono | `feat/102-validacion-cloud-apf3`, PR #122; `apf3/evidencias/andersson/` |
| #103 Coexistencia | Fusionado por fardcrex; issue abierta, sin review APPROVED registrada | USER app, dockerignore, límite512MiB, pool configurable, script secuencial | Andersson / Jeremy | Imagen construida; uid999, health/db200, 4 pruebas pool; suite SQLite433 aprobadas/3 omitidas; no despliegue | `feat/103-coexistencia-contenedores`, #121; `apf3/evidencias/andersson/coexistencia/` |

### Revisiones a cargo de Andersson

La consulta de todos los PR y ramas remotos no encuentra PR de implementación
para #77 (Jeremy, QR), #84 (Jeremy, evaluación/solicitud de préstamo) ni #87
(Jair C., cierre diario). No se aprueba código inexistente ni se modifican sus
funciones. #120 contiene oráculos de aceptación, no esas implementaciones.
Revisión pendiente del responsable; el contrato mínimo de #84 se documenta
arriba para coordinar antes de crear tablas/API incompatibles. El cuadre GET de
#88 no se presenta como sustituto del cierre diario con registro de #87.

### Entorno y límites verificados

Linux Mint 22.3 x86_64; CPU Ryzen5 5500U (12 hilos), RAM5,6GiB, inicialmente
935MiB disponibles, 3,1GiB libres en disco. Git2.43, gh2.45, Docker29.1.3,
Compose5.1.2 y Python3.12.3. PostgreSQL16 aislado; loopback55432, API8001,
base desarrollo `cuycash_dev`, bases desechables `cuycash_andersson_test` y
`cuycash_rbac_test`. Solo contenedores propios; KYC no levantado.
Flutter/Dart ausentes; ADB34 disponible sin dispositivos; Android SDK incompleto.
No se descarga Flutter con el disco al 98%: no hay margen seguro para SDK,
artefactos Android y build. La compilación y UI no se declaran probadas.
El contrato app/API se ejecuta en CI; revisar el run de cada PR.

Durante la auditoría inicial, Projects no era accesible con la credencial inicial (falta scope project). El push
de #95 requiere scope workflow por actualizar el arranque del job de contrato.
No se omite esa corrección ni se afirma CI verde para el último commit si no
ha sido aceptado por GitHub. Los PR #102/#103 son independientes desde main.


### Verificación final del código local

- PostgreSQL16: **486 aprobadas, cero omitidas**, 96% de cobertura de líneas
  (2119 sentencias,75 sin cubrir); `pytest-postgres-final.txt` y
  `coverage-final.xml`. Suite completa del código final, incluidos los nuevos
  negativos de registro, límites del cuadre y conflicto entre solicitudes.
- SQLite: **481 aprobadas y5 omitidas**, exclusivamente las cinco carreras que
  requieren PostgreSQL. No se interpreta una omisión como aprobación.
- Suite focal PostgreSQL:130 aprobadas; `alembic current`0002,
  `alembic check` sin diferencias; `schema.sql` idéntico al dump regenerado.
- Ruff, pip check y git diff --check correctos. pip-audit: sin vulnerabilidades
  conocidas en las dependencias auditadas. Permanecen22 avisos de deprecación
  (Pydantic/Starlette/pytest-asyncio); no son fallos nuevos de negocio.
- Imagen final #95 reconstruida; health/db200 contra la base local preservada.
- CI #121: **SUCCESS**, run41755843542;436 pruebas PostgreSQL, cobertura96%,
  diez pruebas de contrato app/API. No sustituye Android ni aprueba #95.
- #95 fue publicado con head e63789e tras habilitar project/workflow.
  CI41761171157 **SUCCESS**: backend, Flutter completo y contrato app/API.
  Los reportes XML/logs ya están publicados en la rama del PR.

Evidencia local versionada en `apf3/evidencias/andersson/backend/`.
Las ramas #102/#103 están subidas con PR #122/#121; revisión Jeremy solicitada.

### Publicación y tablero tras habilitar permisos

El push normal de #95 publicó los tres commits locales sin reescritura. Su base
es main; la primera ejecución completa del código publicado terminó en verde:
https://github.com/Los-hijos-de-Rene/CuyCashUTP/actions/runs/41761171157 .
Las últimas correcciones de documentación tienen su propio CI de PR.

Projects1 actualizado solo para las tarjetas propias: #40/#80/#81/#85/#88/#103 en
**In review**; #79 en **In progress** para regularizar aprobación independiente;
#102 en **In progress**, parcial por KYC/Neon/Android. WIP propio:2, sin cambios
de asignaciones ni tareas marcadas Done. Hay7 tarjetas globales en revisión
(6 propias y1 previa de otro responsable), frente al objetivo6 pendiente de
configuración por el SM; se declara la saturación sin esconder tareas ni mover
las ajenas. Revisiones Jeremy/Gian Piero solicitadas; no se aprueba trabajo propio.

Pendientes para el cierre real: aprobación independiente de #95/#121/#122,
regularización de #79 con Gian Piero, integración del flujo #84 y acceso de ensayo
KYC/Neon más Android para #102. Ningún despliegue ni migración productiva fue
aprobado o ejecutado. Las credenciales Neon no están disponibles en los issues,
PR,38 comentarios consultados ni secretos de GitHub: la documentación indica
que DATABASE_URL se mantiene en Render. Las cuentas locales de demostración
no se presentan como cuentas productivas con KYC aprobado.


### Integración posterior de #121 y #122 (2026-11-04 UTC)

Jair C. (`fardcrex`) fusionó #122 en main (`4347039`,03:23UTC) y #121
(`a73f1a0`,03:48UTC). El CI de main41769399162 terminó SUCCESS. No hay reviews
APPROVED registradas en #94/#95/#121/#122; se informa la integración realizada
por otra persona sin inventar una revisión formal. Las issues conservan sus
asignaciones; #102 no se cierra por haberse fusionado su evidencia parcial.

Estas fusiones causaron dos conflictos reales en #95: `.env.example` y
`app/core/config.py`. Se resolvieron conservando tanto ADMIN_CORS_ORIGINS y su
validación exacta como DB_POOL_SIZE/DB_MAX_OVERFLOW/DB_POOL_TIMEOUT y sus rangos.
El Dockerfile integrado conserva usuario app, exec uvicorn y las migraciones;
la configuración de base conserva pool configurable y transacciones SQLite.

Validación local de la integración:29 pruebas de configuración/sesión aprobadas,
73 pruebas focales PostgreSQL aprobadas sin omisiones, ruff y diff correctos.
Imagen construida, health/db200, Alembic0002 y check sin diferencias; pool
real2+2, proceso app,512MiB y apagado exit0/OOM=false. Evidencias en
`apf3/evidencias/andersson/backend/integracion-main/`. Se detuvieron únicamente
los contenedores propios; no se borraron bases/volúmenes ni se tocó producción.
El nuevo commit debe completar su propio CI antes de atribuirle un resultado.

El despliegue de main continúa pendiente; `/health` productivo sigue sirviendo
`d74d663`. No hubo respuestas nuevas de acceso Neon/KYC en #102 ni PR nuevos de
#77/#84/#87. La rama remota nueva `feat/apf3-usabilidad-goldens` corresponde a
trabajo del equipo y no se modificó.
