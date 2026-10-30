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

**Contrato con #81:** esta rama añade la protección mínima del rol para no
exponer consultas al titular. CORS continúa cerrado como el backend existente;
no se añade un comodín. La configuración del origen del panel web y el resto
del alcance de #81 requieren integrarse con su responsable. #89 (web) no se
implementa aquí. HU28 sigue siendo propuesta pendiente del PO, fuera de la línea
base de 26 HU; no se aumenta la métrica X por estas consultas.
