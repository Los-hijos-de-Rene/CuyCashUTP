# Verificación manual: app contra backend

**Estado: nunca ejecutada.** La app y el backend se probaron cada uno contra su
propio doble (la app contra `Memory*`, el backend por HTTP con su suite y con un
recorrido a mano con `curl`). Este guion es para cerrar esa brecha en un
emulador. Si lo ejecutas, anota el resultado al final de este archivo.

**Qué está verificado y qué no.** Los comandos del backend (pasos 1 y 2) y las
respuestas HTTP se ejercitaron. Los pasos que describen pantallas de la app
(4 a 9) están marcados **[inferido]**: los nombres de pantalla, botones y textos
se deducen del código, no se vieron en ejecución, así que ahí puede no cuadrar
el guion aunque la app esté bien.

Requisitos: emulador Android o simulador iOS arrancado, `flutter pub get` en la raíz.

**Nota sobre el virtualenv.** Los comandos usan `.venv/bin/python -m uvicorn` y
`.venv/bin/python -m pytest`, no `.venv/bin/uvicorn` ni `.venv/bin/pytest`: en el
venv de esta máquina esos scripts tienen un shebang que apunta a
`services/auth/.venv`, ruta que dejó de existir al renombrar el servicio, y dan
`bad interpreter`. Si recreas el virtualenv desde cero, los scripts vuelven a
funcionar; el problema es de ese venv concreto, no del proyecto.

### Paso 0. Configuración de la app.
 En `apps/mobile/config.local.json` de ESTA máquina hay restos de Supabase (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) que la app ya no usa; no está versionado. Reemplázalo:
```sh
cd /Users/jairconislla/Projects/cuycash/apps/mobile
cp config.example.json config.local.json
```
- Emulador Android: déjalo así (`AUTH_BASE_URL` = `http://10.0.2.2:8001`).
- Simulador iOS: borra la línea `AUTH_BASE_URL` (o ponla en `http://127.0.0.1:8001`) — el `10.0.2.2` del ejemplo NO sirve en iOS; sin la variable la app asume `127.0.0.1` sola.
- Teléfono FÍSICO: pon `AUTH_BASE_URL` con la IP del PC en la red local (p. ej. `http://192.168.1.20:8001`; averíguala con `ipconfig getifaddr en0`), y arranca el backend con `--host 0.0.0.0` (ver paso 2). Si no, la app llega a `10.0.2.2`/`127.0.0.1` del propio teléfono y todo falla con error de red.
- Deja `KYC_BASE_URL`/`KYC_API_KEY` vacíos: el registro usa `MemoryKycRepository` (simula el reconocimiento).
Fallo aquí = la app abre pero toda llamada da error de conexión.

### Paso 1. Backend y esquema limpio.

```sh
cd /Users/jairconislla/Projects/cuycash/services/api
rm -f cuycash.db
DATABASE_URL="sqlite+aiosqlite:///./cuycash.db" .venv/bin/python scripts/reset_schema.py
```
Esperado: `Esquema recreado en ...cuycash.db`. Si responde "Rechazado: el destino no es local", `DATABASE_URL` apunta a una base remota (por ejemplo en tu `.env`): para y revisa, no fuerces con `ALLOW_DESTRUCTIVE_RESET=1` salvo que quieras de verdad borrarla.

### Paso 2. Arrancar el servicio
 (deja esa terminal abierta: ahí aparecen los códigos OTP).
```sh
DATABASE_URL="sqlite+aiosqlite:///./cuycash.db" .venv/bin/python -m uvicorn app.main:app --port 8001
# teléfono físico: añade --host 0.0.0.0
```
Comprobar: `curl -s http://127.0.0.1:8001/health` responde OK y `http://127.0.0.1:8001/docs` abre. Opcional: no pongas `UNIFORM_RESPONSE_SECONDS=0` aquí; el retardo uniforme (0.35 s) es el comportamiento real. Fallo: puerto ocupado (`lsof -i :8001`) o falta el venv.

### Paso 3. Arrancar la app.

```sh
cd /Users/jairconislla/Projects/cuycash/apps/mobile
flutter run --flavor local -t lib/main_local.dart --dart-define-from-file=config.local.json
```
Esperado: splash -> onboarding. Fallo de compilación del flavor `local` = problema de Gradle/Xcode, no del backend. Si compila pero la app se queda en una pantalla de carga o muestra error de red desde el primer paso con red, `AUTH_BASE_URL` no apunta al backend (paso 0) o el servicio no está escuchando en 8001 (paso 2). Si `flutter run` pide un flavor o config que no existe, falta `config.local.json`.

### Paso 4. Registrar la cuenta A [inferido]
 (p. ej. DNI `71234567`, nombre Jenny Ruiz, correo `71234567@correo.pe`, PIN `839201` — el backend rechaza PIN repetidos o secuenciales como `000000` o `123456`). Mirar: el wizard de registro y el KYC simulado terminan sin error. En la terminal del backend debe aparecer `POST /v1/auth/register ... 201`. Si el registro devuelve error de DNI duplicado, la base no está limpia (repetir paso 1). Si el PIN es rechazado, usa otro.

### Paso 5. Entrar como A. [inferido]
 Login con DNI + PIN. Un teléfono desconocido exige OTP de dispositivo: mira en la terminal del backend la línea `WARNING [OTP:device] 71234567@correo.pe -> 123456` e ingresa ese código en la app. Esperado: llegas al home con una cuenta de ahorro y saldo S/ 0.00. Fallo: si no aparece la línea del código, `OTP_NOTIFIER` no es `log`; si la app dice "código inválido" con el código correcto, comprueba la hora del emulador (la vigencia es de minutos).

### Paso 6. Recargar A. [inferido]
 Home -> Recargar, S/ 500.00, confirmar con PIN. Esperado: saldo S/ 500.00 y un movimiento "Recarga de saldo". Backend: `POST /v1/topups ... 201`. Fallo "PIN incorrecto" con el PIN bueno: revisa que el `X-Device-Id` de la sesión sea el mismo (reinstalar la app lo cambia). Fallo de saldo que no se refresca: la app no está releyendo `/v1/accounts` tras recargar.

### Paso 7. Cerrar sesión de A y registrar la cuenta B [inferido]
 (DNI `45678912`, nombres **Luis Alberto**, apellidos **Quispe**, correo `45678912@correo.pe`, PIN `839201`; el nombre completo importa porque los pasos 8 y 9 esperan `L*** A*** Q***` y `Luis Alberto Quispe`). Mismo procedimiento (pasos 4-5); B termina con saldo S/ 0.00. Hacen falta dos titulares para demostrar un envío. Un solo dispositivo basta, y como el teléfono ya está vinculado a A, B pedirá su propio OTP de dispositivo (leerlo en el log del backend). Qué significaría que fallara: "DNI ya registrado" = base sin limpiar (paso 1); si al volver a entrar como A la app exige OTP de nuevo, el vínculo de dispositivo no se está guardando; si B ve la cuenta o el saldo de A, hay una fuga entre sesiones (grave: avisar). Si la app muestra un nombre distinto del escrito, el registro no está enviando `nombres`/`apellidos` bien.

### Paso 8. Enviar de A a B. [inferido]
 Entra de nuevo como A (código OTP solo si el teléfono ya no está vinculado). Enviar -> DNI `45678912`. Esperado: la app muestra el nombre ENMASCARADO `L*** A*** Q***` y la cuenta `••••NNNN` (backend: `GET /v1/directory/resolve ... 200`). Monto S/ 125.50, motivo opcional, confirmar con PIN. Esperado: constancia de envío; saldo de A = S/ 374.50. Backend: `POST /v1/transfers ... 201`. Fallos: "no encontramos a nadie con ese DNI" (404) = B no está registrado o su cuenta no está activa; "no puedes enviarte dinero a ti mismo" = DNI propio; error de monto = fuera de S/ 0.01–2,000.00.

### Paso 9. Comprobar que ambos lados cuadran. [inferido]

- A: saldo S/ 374.50; historial con "Recarga de saldo" +S/ 500.00 y el envío a Luis Alberto Quispe -S/ 125.50 (motivo si lo pusiste).
- Cerrar sesión, entrar como B: saldo S/ 125.50; historial con UN movimiento +S/ 125.50 con contraparte Jenny Ruiz. Abrir el detalle de ambos: misma referencia/identificador de operación.
- Contraste independiente con la base: `sqlite3 services/api/cuycash.db "select tipo, direccion, monto, saldo_posterior from ledger_entries l join transactions t on t.id=l.transaction_id order by l.created_at;"` — la suma de débitos debe igualar la de créditos por transacción (la recarga tiene como contraparte la cuenta `sistema`, con saldo -50000).
Qué significa que falle: si el importe sale distinto en un lado (p. ej. 12550 vs 125.5 o 1.25), hay un error de conversión de céntimos en la app (`Money`/`formatSoles`) — es la regla dura 10; si un lado no muestra el movimiento, el mapeo de `direccion`/`contraparte` del `HttpAccountRepository` no coincide con el JSON real del backend (eso es justo la brecha que ningún test cubre); si el saldo de la app no coincide con el de la base, la app está cacheando.

### Paso 10. Reintento idempotente (opcional)
 Desde curl, repite un `POST /v1/transfers` con la misma `idempotency_key` y el mismo cuerpo (ver el recorrido HTTP del backend: `POST /v1/transfers` con `Authorization: Bearer <token>` y el mismo cuerpo): 200 con la misma transacción y sin cambio de saldo. En la app, la prueba equivalente es enviar, matar la red (modo avión) justo al confirmar y reintentar: no debe cobrar dos veces. Si cobra dos veces, la clave no se está persistiendo (`pending_transfer_store`).

Al terminar: Ctrl+C en el backend y `rm services/api/cuycash.db`.
