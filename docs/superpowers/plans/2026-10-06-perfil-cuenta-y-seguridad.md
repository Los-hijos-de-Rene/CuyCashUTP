# Perfil: cuenta y seguridad — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que las cinco opciones de "Cuenta" y "Seguridad" del perfil funcionen contra el backend: datos personales, alias, cambio de PIN, acceso biométrico real y dispositivos vinculados.

**Architecture:** Backend FastAPI gana un router `profile` (`/v1/me`, `/v1/devices`) y rutas en `auth` (`pin/change`, `biometric/*`, `sessions/biometric`), con dos servicios nuevos (`pin_check`, `biometric`) y una tabla `biometric_credentials`. La app gana tres features (`profile`, `security`, `biometric`) con su `Memory*`, cinco pantallas bajo `/perfil/*`, y el acceso rápido cambia la biometría simulada por una credencial emitida por el servidor y desbloqueada con `local_auth`.

**Tech Stack:** Flutter (Bloc, freezed, go_router, dio, fpdart), `local_auth` 3.x, `device_info_plus`, `flutter_secure_storage`; FastAPI + SQLAlchemy async + pytest.

**Spec:** `docs/superpowers/specs/2026-10-06-perfil-cuenta-y-seguridad-design.md`

**Nota de rutas:** el spec escribe las rutas sin prefijo. En el código real todo cuelga de `/v1`, y lo que es de identidad de `/v1/auth`. Este plan usa:

| Spec | Ruta real |
|---|---|
| `GET /me`, `PATCH /me/alias` | `/v1/me`, `/v1/me/alias` |
| `GET /devices`, `DELETE /devices/{id}` | `/v1/devices`, `/v1/devices/{id}` |
| `POST /pin/change` | `/v1/auth/pin/change` |
| `POST /biometric/enroll`, `DELETE /biometric/current` | `/v1/auth/biometric/enroll`, `/v1/auth/biometric/current` |
| `POST /sessions/biometric` | `/v1/auth/sessions/biometric` |

**"Este dispositivo"** se toma de la fila de sesión (`current_session_row().device_id`), no de la cabecera `X-Device-Id`: la sesión es lo que el servidor emitió, la cabecera la escribe el cliente.

**Correo enmascarado:** se reutiliza `otp.mask_email` (`j•••••@dominio`), el mismo formato que ya ve el usuario en la verificación de dispositivo. El spec decía `j***@`; manda la coherencia con lo existente.

## Global Constraints

- Errores como valores (`Either` + `GlobalFailure`); ningún `throw` cruza capas.
- Failures sellados: factory nombrado + subclase. Las subclases nuevas llevan prefijo (`Profile…`, `Security…`) porque `NetworkFailure`/`Unauthenticated`/`UnexpectedFailure` ya existen en `account`.
- Toda interfaz nace con su `Memory*` funcional.
- Estados sealed + `switch` exhaustivo; prohibido `when`/`maybeWhen`/`!` en `lib/`.
- El Bloc consume `application` (Actions/UseCase) por constructor, nunca el repo.
- Colores/tipografía solo desde `design_system`; cero hex sueltos.
- Copy es-PE en `apps/mobile/lib/l10n/arb/app_es.arb`; cero strings de UI en código. Tras editar el ARB: `flutter gen-l10n` en `apps/mobile`.
- Un widget público por archivo; `.freezed.dart` y l10n generados se commitean.
- `flutter analyze` con cero issues antes de cada commit (en la raíz del repo).
- Backend: suite con `cd services/api && .venv/bin/python -m pytest -q`.
- `create_all` no altera tablas existentes: las columnas nuevas de `devices` exigen `scripts/reset_schema.py` en bases ya creadas. `schema.sql` se regenera con `scripts/dump_schema.py`, nunca a mano.
- Alias: `@` + 3–20 de `[a-z0-9_.]`, no único.
- Bloqueo al 5.º intento: `/pin/change` y `/biometric/enroll` usan el mismo contador que el login (`lockout.register_failure`).
- `/v1/auth/sessions/biometric`: cualquier fallo de credencial → 401 `BIOMETRIC_REVOKED`, idéntico para todos los casos; no suma intentos.
- El teclado de PIN del acceso rápido siempre está visible (contingencia).
- Autenticación biométrica < 1.5 s: sin medición automatizada (se documenta).
- `dart format` solo sobre los archivos que la tarea toca (formatear carpetas enteras reformatea archivos ajenos).

## Review Focus

1. **Alias con mayúsculas, espacios o tildes** ("Jenny_01 ", "ñandú"): se normaliza a minúsculas sin espacios si queda válido, y se rechaza con mensaje claro si no. Test en Task 2 (backend) y Task 9 (validación de la app).
2. **Sensor que desaparece** (credencial guardada, pero el usuario borró sus huellas del sistema): el botón de huella no aparece y el PIN funciona. Test en Task 15.
3. **Desvincular dos veces, o un dispositivo que otro teléfono ya desvinculó** (404): se toma como éxito y se refresca la lista, sin error. Test en Task 12.
4. **Cambiar PIN sin red a mitad de la llamada:** mensaje de resultado desconocido, sin reintento automático y sin volver a teclear el PIN actual a ciegas. Test en Task 11.
5. **Otro usuario en el mismo teléfono** tras "No eres tú" o "Cerrar sesión": la credencial biométrica del anterior se borra y no se puede usar. Test en Task 10 (`clearUser` borra la credencial) y Task 5 (backend: credencial de otro DNI → 401).

---

## Mapa de archivos

**Backend (`services/api/`)**
- Modify `app/db/models.py`: `Device.nombre`, `Device.plataforma`; clase `BiometricCredential`.
- Create `app/services/devices.py`: parseo de `X-Device-Name` y `touch(device, header)`.
- Create `app/services/pin_check.py`: verificar PIN con bloqueo (compartido por cambio de PIN y alta de huella).
- Create `app/services/biometric.py`: emitir, revocar y validar credenciales.
- Modify `app/services/sessions.py`: `revoke_all_except`, `revoke_device`.
- Modify `app/core/errors.py`: `INVALID_ALIAS`, `CANNOT_UNLINK_CURRENT`, `DEVICE_NOT_FOUND`, `BIOMETRIC_REVOKED`.
- Modify `app/schemas.py`: `AliasIn`, `ChangePinIn`, `EnrollBiometricIn`, `BiometricSessionIn`.
- Create `app/api/v1/routers/profile.py`: `/v1/me`, `/v1/me/alias`, `/v1/devices`, `/v1/devices/{id}`.
- Modify `app/api/v1/routers/auth.py`: `X-Device-Name`, `pin/change`, `biometric/enroll`, `biometric/current`, `sessions/biometric`.
- Modify `app/main.py`: incluir `profile.router`.
- Regenerate `schema.sql`.
- Tests: `tests/test_nombre_de_dispositivo.py`, `tests/test_perfil.py`, `tests/test_cambio_de_pin.py`, `tests/test_dispositivos.py`, `tests/test_biometria.py`.

**App (`apps/mobile/`)**
- Create `lib/core/env/device_name.dart`; modify `lib/core/http/authenticated_dio.dart`, `lib/core/injection/envs/shared/shared_backend_dependencies.dart`.
- Create `lib/feature/auth/domain/pin_rules.dart`; modify `lib/presentation/register/bloc/register_bloc.dart` (delegar en `PinRules`).
- Create `lib/feature/profile/{domain,application,infrastructure}/…`.
- Create `lib/feature/security/{domain,application,infrastructure}/…`.
- Create `lib/feature/biometric/{domain,infrastructure}/…`.
- Modify `lib/feature/auth/…` (`signInWithBiometric`, `BiometricRevoked`), `lib/feature/device/…` (credencial).
- Modify `lib/core/injection/app_dependencies.dart`, `envs/mock_dependencies.dart`, `envs/shared/shared_backend_dependencies.dart`; create `modules/profile_module.dart`, `modules/security_module.dart`.
- Create `lib/presentation/profile/{personal_data,alias,change_pin,biometric,devices}/…`.
- Modify `lib/presentation/profile/profile_screen.dart`, `lib/presentation/app/{app_routes,router}.dart`, `lib/presentation/quick_access/…`, `lib/presentation/register/…`.
- Modify `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `MainActivity.kt`, `ios/Runner/Info.plist`.
- Docs: `docs/verificacion-manual.md`, `docs/modelo-datos.md`, `CLAUDE.md`.

---

### Task 1: Backend — nombre del dispositivo y esquema nuevo

**Files:**
- Modify: `services/api/app/db/models.py:46-56`
- Create: `services/api/app/services/devices.py`
- Modify: `services/api/app/api/v1/routers/auth.py` (`register`, `authenticate`, `open_session`)
- Regenerate: `services/api/schema.sql`
- Test: `services/api/tests/test_nombre_de_dispositivo.py`

**Interfaces:**
- Produces: `Device.nombre: Optional[str]`, `Device.plataforma: Optional[str]`; `BiometricCredential(id, user_id, device_id, secret_hash, created_at, revoked_at)`; `devices.describe(header: Optional[str]) -> Tuple[Optional[str], Optional[str]]`; `devices.touch(device: Device, header: Optional[str]) -> None`.

- [ ] **Step 1: Write the failing test**

`services/api/tests/test_nombre_de_dispositivo.py`:

```python
"""
El teléfono dice qué es (`X-Device-Name`) para que "Dispositivos vinculados"
muestre un modelo y no un UUID. Es un dato para mostrar, no de seguridad.
"""

from sqlalchemy import select

from app.db.models import Device
from app.services import devices


def test_describe_separa_plataforma_y_modelo():
    assert devices.describe("android · Samsung SM-A546E") == ("Samsung SM-A546E", "android")
    assert devices.describe("ios · iPhone14,5") == ("iPhone14,5", "ios")


def test_describe_sin_prefijo_conocido_guarda_todo_como_nombre():
    assert devices.describe("Pixel 8") == ("Pixel 8", None)
    assert devices.describe("windows · PC") == ("windows · PC", None)


def test_describe_vacio_o_ausente_no_guarda_nada():
    assert devices.describe(None) == (None, None)
    assert devices.describe("   ") == (None, None)


def test_describe_trunca_a_80():
    nombre, _ = devices.describe("android · " + "x" * 200)
    assert len(nombre) == 80


async def test_el_alta_guarda_el_nombre_del_telefono(client, db_de_client):
    r = await client.post(
        "/v1/auth/register",
        json={
            "dni": "71234567",
            "nombres": "Jenny",
            "apellidos": "Ruiz",
            "email": "jenny@correo.pe",
            "pin": "839201",
        },
        headers={"X-Device-Id": "dev-1", "X-Device-Name": "android · Samsung SM-A546E"},
    )
    assert r.status_code == 201, r.text

    fila = (await db_de_client.execute(select(Device))).scalars().one()
    assert fila.nombre == "Samsung SM-A546E"
    assert fila.plataforma == "android"


async def test_entrar_de_nuevo_actualiza_el_nombre(client, db_de_client):
    await client.post(
        "/v1/auth/register",
        json={
            "dni": "71234567",
            "nombres": "Jenny",
            "apellidos": "Ruiz",
            "email": "jenny@correo.pe",
            "pin": "839201",
        },
        headers={"X-Device-Id": "dev-1"},
    )
    r = await client.post(
        "/v1/auth/authenticate",
        json={"identifier": "71234567", "pin": "839201"},
        headers={"X-Device-Id": "dev-1", "X-Device-Name": "ios · iPhone14,5"},
    )
    assert r.json()["result"] == "session"

    fila = (await db_de_client.execute(select(Device))).scalars().one()
    await db_de_client.refresh(fila)
    assert (fila.nombre, fila.plataforma) == ("iPhone14,5", "ios")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd services/api && .venv/bin/python -m pytest tests/test_nombre_de_dispositivo.py -q`
Expected: FAIL with `ImportError: cannot import name 'devices'`.

- [ ] **Step 3: Implement**

`app/db/models.py`, en `class Device` tras `last_seen_at`:

```python
    # Lo que el teléfono declara de sí mismo (`X-Device-Name`). Solo para
    # mostrar en "Dispositivos vinculados": nada de seguridad se decide con él.
    nombre: Mapped[Optional[str]] = mapped_column(String(80), nullable=True)
    plataforma: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
```

Y tras `class Session`, la tabla nueva:

```python
class BiometricCredential(Base):
    """
    Secreto que la huella libera para abrir sesión sin teclear el PIN.

    Ligado a (usuario, dispositivo): de otro teléfono no sirve. Se guarda el
    hash, como los tokens de sesión. Revocarlo es poner `revoked_at`; una
    fila revocada nunca vuelve a valer.
    """

    __tablename__ = "biometric_credentials"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    device_id: Mapped[str] = mapped_column(String(128), index=True)
    secret_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    revoked_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
```

`app/services/devices.py`:

```python
"""
Lo que el teléfono declara de sí mismo en `X-Device-Name`.

Formato que manda la app: `<plataforma> · <modelo>`. Una cabecera ausente o
rara no rompe nada: es un dato para mostrar.
"""

from typing import Optional, Tuple

from app.db.models import Device

_PLATAFORMAS = ("android", "ios")
_SEPARADOR = " · "
_MAXIMO = 80


def describe(header: Optional[str]) -> Tuple[Optional[str], Optional[str]]:
    """`(nombre, plataforma)`; `(None, None)` si no hay nada que guardar."""
    texto = (header or "").strip()
    if not texto:
        return None, None
    plataforma, sep, modelo = texto.partition(_SEPARADOR)
    if sep and plataforma in _PLATAFORMAS and modelo.strip():
        return modelo.strip()[:_MAXIMO], plataforma
    return texto[:_MAXIMO], None


def touch(device: Device, header: Optional[str]) -> None:
    """Actualiza el nombre si el teléfono mandó uno; si no, conserva el que había."""
    nombre, plataforma = describe(header)
    if nombre is not None:
        device.nombre = nombre
        device.plataforma = plataforma
```

`app/api/v1/routers/auth.py`:
- Import: `from app.services import accounts, devices, lockout, otp, sessions`.
- `register`: añadir parámetro `x_device_name: Optional[str] = Header(None),` tras `x_device_id`. Reemplazar `session.add(Device(user_id=user.id, device_id=x_device_id))` por:

```python
    vinculado = Device(user_id=user.id, device_id=x_device_id)
    devices.touch(vinculado, x_device_name)
    session.add(vinculado)
```

- `authenticate`: añadir `x_device_name: Optional[str] = Header(None),`. En la rama `if trusted is not None:` tras `trusted.last_seen_at = utcnow()`: `devices.touch(trusted, x_device_name)`. Además guardar el nombre en `_pending` para `open_session`: cambiar `_pending[token_digest(pending)] = (user.id, x_device_id)` por `_pending[token_digest(pending)] = (user.id, x_device_id, x_device_name)`.
- `open_session`: añadir `x_device_name: Optional[str] = Header(None),`; desempaquetar `user_id, device_id, nombre_pendiente = entry`; reemplazar `session.add(Device(user_id=user_id, device_id=x_device_id))` por:

```python
    vinculado = Device(user_id=user_id, device_id=x_device_id)
    devices.touch(vinculado, x_device_name or nombre_pendiente)
    session.add(vinculado)
```

- [ ] **Step 4: Run tests**

Run: `cd services/api && .venv/bin/python -m pytest -q`
Expected: toda la suite PASS (los tests existentes del login siguen pasando con la tupla de tres).

- [ ] **Step 5: Regenerate schema and commit**

```bash
cd services/api && .venv/bin/python scripts/dump_schema.py > schema.sql
git add app/db/models.py app/services/devices.py app/api/v1/routers/auth.py schema.sql tests/test_nombre_de_dispositivo.py
git commit -m "feat(api): el dispositivo guarda su nombre y nace la tabla de credenciales biométricas"
```

---

### Task 2: Backend — datos personales y alias

**Files:**
- Create: `services/api/app/api/v1/routers/profile.py`
- Modify: `services/api/app/main.py:7,43`, `services/api/app/core/errors.py:35`, `services/api/app/schemas.py`
- Test: `services/api/tests/test_perfil.py`

**Interfaces:**
- Consumes: `current_user`, `otp.mask_email`.
- Produces: `GET /v1/me` → `{dni, nombres, apellidos, email_masked, alias, kyc_status, created_at}` (`created_at` UTC con `Z`); `PATCH /v1/me/alias` `{alias}` → `{alias}`; 422 `{code: "INVALID_ALIAS"}`. `ErrorCode.INVALID_ALIAS`. `profile.router` (prefix `/v1`), que Task 4 amplía.

- [ ] **Step 1: Write the failing test**

`services/api/tests/test_perfil.py`:

```python
"""Datos personales (solo lectura) y alias."""


async def test_me_devuelve_los_datos_del_titular(client, registrado):
    r = await client.get("/v1/me", headers=registrado.auth)

    assert r.status_code == 200
    cuerpo = r.json()
    assert cuerpo["dni"] == "71234567"
    assert cuerpo["nombres"] == "Jenny Marisol"
    assert cuerpo["apellidos"] == "Ruiz"
    assert cuerpo["alias"] == "@jenny"
    assert cuerpo["kyc_status"] == "pending"
    assert cuerpo["created_at"].endswith("Z")


async def test_me_nunca_devuelve_el_correo_completo(client, registrado):
    cuerpo = (await client.get("/v1/me", headers=registrado.auth)).json()

    assert "email" not in cuerpo
    assert cuerpo["email_masked"].endswith("@correo.pe")
    assert "71234567" not in cuerpo["email_masked"]


async def test_me_sin_sesion_es_401(client):
    r = await client.get("/v1/me")
    assert r.status_code == 401


async def test_alias_se_normaliza_y_persiste(client, registrado):
    r = await client.patch(
        "/v1/me/alias", json={"alias": "  Jenny_01 "}, headers=registrado.auth
    )

    assert r.status_code == 200
    assert r.json() == {"alias": "@jenny_01"}
    me = (await client.get("/v1/me", headers=registrado.auth)).json()
    assert me["alias"] == "@jenny_01"


async def test_alias_con_arroba_se_respeta(client, registrado):
    r = await client.patch("/v1/me/alias", json={"alias": "@j.r"}, headers=registrado.auth)
    assert r.json() == {"alias": "@j.r"}


async def test_alias_fuera_de_formato_se_rechaza(client, registrado):
    for malo in ["ab", "ñandú", "con espacio", "a" * 21, "@", ""]:
        r = await client.patch("/v1/me/alias", json={"alias": malo}, headers=registrado.auth)
        assert r.status_code == 422, malo
        assert r.json()["code"] == "INVALID_ALIAS", malo


async def test_alias_no_es_unico(client, registrado, otro_registrado):
    a = await client.patch("/v1/me/alias", json={"alias": "@igual"}, headers=registrado.auth)
    b = await client.patch(
        "/v1/me/alias", json={"alias": "@igual"}, headers=otro_registrado.auth
    )
    assert a.status_code == b.status_code == 200
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd services/api && .venv/bin/python -m pytest tests/test_perfil.py -q`
Expected: FAIL (404 en `/v1/me`).

- [ ] **Step 3: Implement**

`app/core/errors.py`, en `class ErrorCode` tras `RATE_LIMITED`:

```python
    INVALID_ALIAS = "INVALID_ALIAS"
    CANNOT_UNLINK_CURRENT = "CANNOT_UNLINK_CURRENT"
    DEVICE_NOT_FOUND = "DEVICE_NOT_FOUND"
    BIOMETRIC_REVOKED = "BIOMETRIC_REVOKED"
```

`app/schemas.py`, al final:

```python
class AliasIn(BaseModel):
    # Holgado a propósito: la regla real (`@` + 3–20 de [a-z0-9_.]) la aplica
    # el router tras normalizar, para responder INVALID_ALIAS y no un 422 genérico.
    alias: str = Field(max_length=60)
```

`app/api/v1/routers/profile.py`:

```python
"""
Perfil del titular: sus datos (solo lectura) y su alias.

Los datos vienen del KYC: cambiarlos exigiría volver a verificar la identidad,
así que aquí solo se leen. El correo nunca sale completo: es el canal del OTP de
recuperación y no tiene por qué viajar entero a cada apertura del perfil.
"""

import re
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import current_user
from app.core.errors import ApiError, ErrorCode
from app.db.base import get_session
from app.db.models import User
from app.schemas import AliasIn
from app.services import otp

router = APIRouter(prefix="/v1", tags=["Perfil"])

_ALIAS = re.compile(r"^@[a-z0-9_.]{3,20}$")


def _iso(momento: datetime) -> str:
    """UTC con sufijo `Z`, el formato del resto del contrato."""
    utc = momento.replace(tzinfo=timezone.utc) if momento.tzinfo is None else momento
    return utc.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ")


def normalizar_alias(texto: str) -> str:
    """Minúsculas, sin espacios en los bordes y con `@` delante."""
    limpio = texto.strip().lower()
    return limpio if limpio.startswith("@") else f"@{limpio}"


@router.get("/me")
async def me(user: User = Depends(current_user)):
    return {
        "dni": user.dni,
        "nombres": user.nombres,
        "apellidos": user.apellidos,
        "email_masked": otp.mask_email(user.email),
        "alias": user.alias,
        "kyc_status": user.kyc_status,
        "created_at": _iso(user.created_at),
    }


@router.patch("/me/alias")
async def cambiar_alias(
    payload: AliasIn,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    alias = normalizar_alias(payload.alias)
    if not _ALIAS.match(alias):
        raise ApiError(
            ErrorCode.INVALID_ALIAS,
            "Usa de 3 a 20 letras, números, punto o guion bajo.",
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        )
    user.alias = alias
    await session.commit()
    return {"alias": alias}
```

`app/main.py`: import `profile` junto a los demás routers (`from app.api.v1.routers import accounts, auth, directory, kyc, otp, profile, transfers`) y `app.include_router(profile.router)` tras `directory`.

- [ ] **Step 4: Run tests**

Run: `cd services/api && .venv/bin/python -m pytest -q`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add services/api/app/api/v1/routers/profile.py services/api/app/main.py services/api/app/core/errors.py services/api/app/schemas.py services/api/tests/test_perfil.py
git commit -m "feat(api): GET /v1/me y PATCH /v1/me/alias"
```

---

### Task 3: Backend — cambiar el PIN con sesión abierta

**Files:**
- Create: `services/api/app/services/pin_check.py`, `services/api/app/services/biometric.py`
- Modify: `services/api/app/services/sessions.py`, `services/api/app/schemas.py`, `services/api/app/api/v1/routers/auth.py`
- Test: `services/api/tests/test_cambio_de_pin.py`

**Interfaces:**
- Consumes: `lockout.*`, `averify_pin`, `current_session_row`, `current_user`.
- Produces:
  - `pin_check.verify(session, user: User, pin: str, row: SessionRow) -> None` (lanza `ApiError` 423 o 401 con `attempts_left`; si bloquea, revoca `row`).
  - `sessions.revoke_all_except(session, user_id: str, device_id: str) -> int`
  - `sessions.revoke_device(session, user_id: str, device_id: str) -> int`
  - `biometric.revoke(session, user_id: str, *, device_id: Optional[str] = None, except_device: Optional[str] = None) -> int`
  - `POST /v1/auth/pin/change` `{current_pin, new_pin}` → `{revoked_sessions: int}`.

- [ ] **Step 1: Write the failing test**

`services/api/tests/test_cambio_de_pin.py`:

```python
"""
Cambiar el PIN con la sesión abierta: exige el actual, cuenta para el bloqueo,
y cierra las sesiones y huellas de los OTROS teléfonos, no la de este.
"""

from sqlalchemy import select

from app.db.models import BiometricCredential, utcnow
from tests.conftest import PIN_DE_PRUEBA

NUEVO = "502718"


async def _otra_sesion(client, otp_codes, dni):
    """Entra desde un segundo teléfono por el camino real (PIN + OTP)."""
    a = await client.post(
        "/v1/auth/authenticate",
        json={"identifier": dni, "pin": PIN_DE_PRUEBA},
        headers={"X-Device-Id": "telefono-2"},
    )
    pending = a.json()["pending_token"]
    ch = await client.post(
        "/v1/otp/challenges",
        json={"purpose": "device", "identifier": dni},
        headers={"X-Device-Id": "telefono-2"},
    )
    cid = ch.json()["challenge_id"]
    v = await client.post(
        f"/v1/otp/challenges/{cid}/verify",
        json={"code": otp_codes[-1]["code"]},
        headers={"X-Device-Id": "telefono-2"},
    )
    s = await client.post(
        "/v1/auth/sessions",
        json={"pending_token": pending, "otp_ticket": v.json()["otp_ticket"]},
        headers={"X-Device-Id": "telefono-2"},
    )
    return {"Authorization": f"Bearer {s.json()['session_token']}"}


async def _cambiar(client, auth, actual=PIN_DE_PRUEBA, nuevo=NUEVO):
    return await client.post(
        "/v1/auth/pin/change",
        json={"current_pin": actual, "new_pin": nuevo},
        headers=auth,
    )


async def test_cambia_el_pin_y_este_telefono_sigue_dentro(client, registrado):
    r = await _cambiar(client, registrado.auth)

    assert r.status_code == 200
    assert (await client.get("/v1/me", headers=registrado.auth)).status_code == 200
    viejo = await client.post(
        "/v1/auth/authenticate",
        json={"identifier": registrado.dni, "pin": PIN_DE_PRUEBA},
        headers={"X-Device-Id": f"dev-{registrado.dni}"},
    )
    assert viejo.status_code == 401
    nuevo = await client.post(
        "/v1/auth/authenticate",
        json={"identifier": registrado.dni, "pin": NUEVO},
        headers={"X-Device-Id": f"dev-{registrado.dni}"},
    )
    assert nuevo.json()["result"] == "session"


async def test_cierra_las_sesiones_y_huellas_de_los_otros(
    client, registrado, otp_codes, db_de_client
):
    otra = await _otra_sesion(client, otp_codes, registrado.dni)
    db_de_client.add_all(
        [
            BiometricCredential(
                user_id=registrado.user_id, device_id="telefono-2", secret_hash="a" * 64
            ),
            BiometricCredential(
                user_id=registrado.user_id,
                device_id=f"dev-{registrado.dni}",
                secret_hash="b" * 64,
            ),
        ]
    )
    await db_de_client.commit()

    r = await _cambiar(client, registrado.auth)

    assert r.json()["revoked_sessions"] == 1
    assert (await client.get("/v1/me", headers=otra)).status_code == 401
    filas = (await db_de_client.execute(select(BiometricCredential))).scalars().all()
    for fila in filas:
        await db_de_client.refresh(fila)
    estado = {f.device_id: f.revoked_at is not None for f in filas}
    assert estado == {"telefono-2": True, f"dev-{registrado.dni}": False}


async def test_pin_actual_errado_descuenta_intentos(client, registrado):
    r = await _cambiar(client, registrado.auth, actual="111222")

    assert r.status_code == 401
    assert r.json()["code"] == "INVALID_CREDENTIALS"
    assert r.json()["attempts_left"] == 4
    # Un 401 de negocio NO cierra la sesión.
    assert (await client.get("/v1/me", headers=registrado.auth)).status_code == 200


async def test_al_quinto_fallo_bloquea_y_cierra_esta_sesion(client, registrado):
    for _ in range(4):
        await _cambiar(client, registrado.auth, actual="111222")
    r = await _cambiar(client, registrado.auth, actual="111222")

    assert r.status_code == 423
    assert "locked_until" in r.json()
    assert (await client.get("/v1/me", headers=registrado.auth)).status_code == 401


async def test_pin_nuevo_previsible_se_rechaza(client, registrado):
    r = await _cambiar(client, registrado.auth, nuevo="123456")
    assert r.json()["code"] == "WEAK_PIN"


async def test_pin_nuevo_igual_al_actual_se_rechaza(client, registrado):
    r = await _cambiar(client, registrado.auth, nuevo=PIN_DE_PRUEBA)
    assert r.json()["code"] == "PIN_UNCHANGED"


async def test_sin_sesion_es_401(client):
    r = await _cambiar(client, {})
    assert r.status_code == 401
```

`_otra_sesion` reproduce el camino de `tests/test_otp_y_recuperacion.py::test_restablecer_el_pin_revoca_todas_las_sesiones`: el reto de dispositivo se abre con el DNI como `identifier`, y `verify` devuelve `otp_ticket`.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd services/api && .venv/bin/python -m pytest tests/test_cambio_de_pin.py -q`
Expected: FAIL (404 en `/v1/auth/pin/change`).

- [ ] **Step 3: Implement**

`app/schemas.py`, al final:

```python
class ChangePinIn(BaseModel):
    current_pin: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")
    new_pin: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")


class EnrollBiometricIn(BaseModel):
    pin: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")


class BiometricSessionIn(BaseModel):
    dni: str = Field(min_length=8, max_length=8, pattern=r"^\d{8}$")
    credential: str = Field(min_length=1, max_length=200)
```

`app/services/sessions.py`, al final:

```python
async def revoke_all_except(session: AsyncSession, user_id: str, device_id: str) -> int:
    """Cierra las sesiones del usuario en los OTROS dispositivos."""
    result = await session.execute(
        update(SessionRow)
        .where(
            SessionRow.user_id == user_id,
            SessionRow.device_id != device_id,
            SessionRow.revoked_at.is_(None),
        )
        .values(revoked_at=utcnow())
    )
    await session.flush()
    return result.rowcount or 0


async def revoke_device(session: AsyncSession, user_id: str, device_id: str) -> int:
    """Cierra las sesiones del usuario en UN dispositivo."""
    result = await session.execute(
        update(SessionRow)
        .where(
            SessionRow.user_id == user_id,
            SessionRow.device_id == device_id,
            SessionRow.revoked_at.is_(None),
        )
        .values(revoked_at=utcnow())
    )
    await session.flush()
    return result.rowcount or 0
```

`app/services/biometric.py`:

```python
"""
Credenciales biométricas: un secreto por (usuario, dispositivo) que la huella
libera en el teléfono para abrir sesión sin teclear el PIN.

El servidor guarda el hash (SHA-256: el secreto tiene 256 bits, no hay
diccionario que probar). Nunca se reactiva una fila: revocar es definitivo.
"""

from typing import Optional

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import new_token, token_digest
from app.db.models import BiometricCredential, Device, utcnow


async def revoke(
    session: AsyncSession,
    user_id: str,
    *,
    device_id: Optional[str] = None,
    except_device: Optional[str] = None,
) -> int:
    """Revoca las vigentes del usuario; solo las de `device_id`, o todas menos `except_device`."""
    condiciones = [
        BiometricCredential.user_id == user_id,
        BiometricCredential.revoked_at.is_(None),
    ]
    if device_id is not None:
        condiciones.append(BiometricCredential.device_id == device_id)
    if except_device is not None:
        condiciones.append(BiometricCredential.device_id != except_device)
    result = await session.execute(
        update(BiometricCredential).where(*condiciones).values(revoked_at=utcnow())
    )
    await session.flush()
    return result.rowcount or 0


async def issue(session: AsyncSession, user_id: str, device_id: str) -> str:
    """Reemplaza la credencial de este dispositivo y devuelve el secreto en claro, una vez."""
    await revoke(session, user_id, device_id=device_id)
    secreto = new_token()
    session.add(
        BiometricCredential(
            user_id=user_id, device_id=device_id, secret_hash=token_digest(secreto)
        )
    )
    await session.flush()
    return secreto


async def valid_for(
    session: AsyncSession, user_id: str, device_id: str, secreto: str
) -> bool:
    """¿El secreto es la credencial VIGENTE de ese usuario en ese dispositivo vinculado?"""
    fila = (
        await session.execute(
            select(BiometricCredential).where(
                BiometricCredential.secret_hash == token_digest(secreto),
                BiometricCredential.revoked_at.is_(None),
            )
        )
    ).scalars().first()
    if fila is None or fila.user_id != user_id or fila.device_id != device_id:
        return False
    vinculado = (
        await session.execute(
            select(Device).where(Device.user_id == user_id, Device.device_id == device_id)
        )
    ).scalars().first()
    return vinculado is not None


async def devices_with_credential(session: AsyncSession, user_id: str) -> set:
    """`device_id` con credencial vigente, para marcar la huella en la lista."""
    filas = await session.execute(
        select(BiometricCredential.device_id).where(
            BiometricCredential.user_id == user_id,
            BiometricCredential.revoked_at.is_(None),
        )
    )
    return set(filas.scalars().all())
```

`app/services/pin_check.py`:

```python
"""
Verificar el PIN de un titular que YA tiene sesión (cambiar PIN, activar huella).

Cuenta para el mismo bloqueo que el login: con sesión abierta, un PIN errado
sigue siendo un intento de adivinarlo. Si el intento bloquea, también se cierra
la sesión que lo pidió: quien no sabe el PIN no debe seguir dentro.
"""

from fastapi import status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ApiError, ErrorCode
from app.core.security import averify_pin
from app.db.models import Session as SessionRow
from app.db.models import User
from app.services import lockout, sessions


def _bloqueado(hasta) -> ApiError:
    return ApiError(
        ErrorCode.IDENTIFIER_LOCKED,
        "El ingreso está bloqueado por ahora.",
        status_code=status.HTTP_423_LOCKED,
        extra={"locked_until": hasta.isoformat()},
    )


async def verify(session: AsyncSession, user: User, pin: str, row: SessionRow) -> None:
    for kind, value in (("dni", user.dni), ("device", row.device_id)):
        hasta = await lockout.locked_until(session, kind, value)
        if hasta is not None:
            raise _bloqueado(hasta)

    if await averify_pin(pin, user.pin_hash):
        await lockout.register_success(session, user.dni, row.device_id)
        return

    hasta = await lockout.register_failure(session, user.dni, row.device_id)
    if hasta is not None:
        await sessions.revoke(session, row)
        await session.commit()
        raise _bloqueado(hasta)
    restantes = await lockout.attempts_left(session, user.dni)
    await session.commit()
    raise ApiError(
        ErrorCode.INVALID_CREDENTIALS,
        "Tu PIN actual no es correcto.",
        status_code=status.HTTP_401_UNAUTHORIZED,
        extra={"attempts_left": restantes},
    )
```

`app/api/v1/routers/auth.py`:
- Imports: `from app.core.deps import bearer_token, current_session_row, current_user`; `from app.db.models import Device, OtpTicket, User, utcnow` y `from app.db.models import Session as SessionRow`; `from app.schemas import AuthenticateIn, BiometricSessionIn, ChangePinIn, CheckPinIn, EnrollBiometricIn, RegisterIn, ResetPinIn, SessionIn`; `from app.services import accounts, biometric, devices, lockout, otp, pin_check, sessions`.
- Al final:

```python
@router.post("/pin/change")
async def change_pin(
    payload: ChangePinIn,
    row: SessionRow = Depends(current_session_row),
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    """
    Cambiar el PIN con la sesión abierta. A diferencia de `/pin/reset`, este
    teléfono sigue dentro: quien lo pide acaba de probar el PIN actual. Los
    OTROS teléfonos pierden sus sesiones y sus huellas.
    """
    await pin_check.verify(session, user, payload.current_pin, row)
    if not pin_is_valid(payload.new_pin):
        raise ApiError(ErrorCode.WEAK_PIN, "Elige un PIN menos previsible.")
    if await averify_pin(payload.new_pin, user.pin_hash):
        raise ApiError(ErrorCode.PIN_UNCHANGED, "Tu nuevo PIN debe ser distinto al anterior.")

    user.pin_hash = await ahash_pin(payload.new_pin)
    user.pin_updated_at = utcnow()
    revocadas = await sessions.revoke_all_except(session, user.id, row.device_id)
    await biometric.revoke(session, user.id, except_device=row.device_id)
    await session.commit()
    return {"revoked_sessions": revocadas}
```

`current_user` y `current_session_row` dependen de `get_session`; FastAPI resuelve una sola instancia por petición, así que `row` y `session` son de la misma sesión.

- [ ] **Step 4: Run tests**

Run: `cd services/api && .venv/bin/python -m pytest -q`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add services/api/app services/api/tests/test_cambio_de_pin.py
git commit -m "feat(api): POST /v1/auth/pin/change conserva esta sesión y cierra las demás"
```

---

### Task 4: Backend — dispositivos vinculados

**Files:**
- Modify: `services/api/app/api/v1/routers/profile.py`
- Test: `services/api/tests/test_dispositivos.py`

**Interfaces:**
- Consumes: `current_session_row`, `sessions.revoke_device`, `biometric.revoke`, `biometric.devices_with_credential`.
- Produces: `GET /v1/devices` → `{"dispositivos": [{id, nombre, plataforma, vinculado_el, ultimo_uso, es_este, con_huella}]}` (este primero, luego `ultimo_uso` desc); `DELETE /v1/devices/{id}` → 204 | 404 `DEVICE_NOT_FOUND` | 409 `CANNOT_UNLINK_CURRENT`.

- [ ] **Step 1: Write the failing test**

`services/api/tests/test_dispositivos.py`:

```python
"""Ver y desvincular los teléfonos con acceso a la cuenta."""

from sqlalchemy import select

from app.db.models import BiometricCredential, Device
from tests.conftest import PIN_DE_PRUEBA
from tests.test_cambio_de_pin import _otra_sesion


async def _lista(client, auth):
    return (await client.get("/v1/devices", headers=auth)).json()["dispositivos"]


async def test_lista_marca_este_telefono_primero(client, registrado, otp_codes):
    await _otra_sesion(client, otp_codes, registrado.dni)

    lista = await _lista(client, registrado.auth)

    assert len(lista) == 2
    assert lista[0]["es_este"] is True
    assert lista[1]["es_este"] is False
    assert lista[0]["vinculado_el"].endswith("Z")
    assert set(lista[0]) == {
        "id", "nombre", "plataforma", "vinculado_el", "ultimo_uso", "es_este", "con_huella"
    }


async def test_con_huella_refleja_la_credencial_vigente(client, registrado, db_de_client):
    db_de_client.add(
        BiometricCredential(
            user_id=registrado.user_id,
            device_id=f"dev-{registrado.dni}",
            secret_hash="c" * 64,
        )
    )
    await db_de_client.commit()

    assert (await _lista(client, registrado.auth))[0]["con_huella"] is True


async def test_desvincular_otro_lo_saca_y_pide_otp_otra_vez(
    client, registrado, otp_codes, db_de_client
):
    otra = await _otra_sesion(client, otp_codes, registrado.dni)
    otro_id = (await _lista(client, registrado.auth))[1]["id"]

    r = await client.delete(f"/v1/devices/{otro_id}", headers=registrado.auth)

    assert r.status_code == 204
    assert (await client.get("/v1/me", headers=otra)).status_code == 401
    assert len(await _lista(client, registrado.auth)) == 1
    vuelve = await client.post(
        "/v1/auth/authenticate",
        json={"identifier": registrado.dni, "pin": PIN_DE_PRUEBA},
        headers={"X-Device-Id": "telefono-2"},
    )
    assert vuelve.json()["result"] == "device_verification_required"


async def test_desvincular_este_telefono_es_409(client, registrado):
    este = (await _lista(client, registrado.auth))[0]["id"]
    r = await client.delete(f"/v1/devices/{este}", headers=registrado.auth)
    assert r.status_code == 409
    assert r.json()["code"] == "CANNOT_UNLINK_CURRENT"


async def test_desvincular_uno_ajeno_o_inexistente_es_404(
    client, registrado, otro_registrado
):
    ajeno = (await _lista(client, otro_registrado.auth))[0]["id"]
    for objetivo in [ajeno, "no-existe"]:
        r = await client.delete(f"/v1/devices/{objetivo}", headers=registrado.auth)
        assert r.status_code == 404
        assert r.json()["code"] == "DEVICE_NOT_FOUND"


async def test_desvincular_revoca_su_huella(client, registrado, otp_codes, db_de_client):
    await _otra_sesion(client, otp_codes, registrado.dni)
    db_de_client.add(
        BiometricCredential(
            user_id=registrado.user_id, device_id="telefono-2", secret_hash="d" * 64
        )
    )
    await db_de_client.commit()
    otro_id = (await _lista(client, registrado.auth))[1]["id"]

    await client.delete(f"/v1/devices/{otro_id}", headers=registrado.auth)

    fila = (await db_de_client.execute(select(BiometricCredential))).scalars().one()
    await db_de_client.refresh(fila)
    assert fila.revoked_at is not None
    assert (
        await db_de_client.execute(select(Device).where(Device.device_id == "telefono-2"))
    ).scalars().first() is None
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd services/api && .venv/bin/python -m pytest tests/test_dispositivos.py -q`
Expected: FAIL (404 en `/v1/devices`).

- [ ] **Step 3: Implement**

`app/api/v1/routers/profile.py`: imports añadidos:

```python
from sqlalchemy import select

from app.core.deps import current_session_row, current_user
from app.db.models import Device
from app.db.models import Session as SessionRow
from app.services import biometric, otp, sessions
```

Y al final:

```python
@router.get("/devices")
async def listar_dispositivos(
    row: SessionRow = Depends(current_session_row),
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    filas = (
        await session.execute(select(Device).where(Device.user_id == user.id))
    ).scalars().all()
    con_huella = await biometric.devices_with_credential(session, user.id)

    def _utc(d):
        return d.replace(tzinfo=timezone.utc) if d.tzinfo is None else d

    ordenadas = sorted(
        filas, key=lambda d: (d.device_id != row.device_id, -_utc(d.last_seen_at).timestamp())
    )
    return {
        "dispositivos": [
            {
                "id": d.id,
                "nombre": d.nombre,
                "plataforma": d.plataforma,
                "vinculado_el": _iso(d.trusted_at),
                "ultimo_uso": _iso(d.last_seen_at),
                "es_este": d.device_id == row.device_id,
                "con_huella": d.device_id in con_huella,
            }
            for d in ordenadas
        ]
    }


@router.delete("/devices/{dispositivo_id}", status_code=status.HTTP_204_NO_CONTENT)
async def desvincular(
    dispositivo_id: str,
    row: SessionRow = Depends(current_session_row),
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    """
    Saca a un teléfono: cierra sus sesiones, revoca su huella y borra la
    confianza, así que volver a entrar desde ahí pedirá el OTP de dispositivo.
    Este teléfono no se desvincula aquí: para eso está "Cerrar sesión".
    """
    fila = await session.get(Device, dispositivo_id)
    if fila is None or fila.user_id != user.id:
        raise ApiError(
            ErrorCode.DEVICE_NOT_FOUND,
            "Ese dispositivo ya no está vinculado.",
            status_code=status.HTTP_404_NOT_FOUND,
        )
    if fila.device_id == row.device_id:
        raise ApiError(
            ErrorCode.CANNOT_UNLINK_CURRENT,
            "Para salir de este teléfono, cierra sesión.",
            status_code=status.HTTP_409_CONFLICT,
        )
    await sessions.revoke_device(session, user.id, fila.device_id)
    await biometric.revoke(session, user.id, device_id=fila.device_id)
    await session.delete(fila)
    await session.commit()
```

(La ruta 204 no devuelve cuerpo; FastAPI lo respeta con `status_code=204` y retorno `None`.)

- [ ] **Step 4: Run tests**

Run: `cd services/api && .venv/bin/python -m pytest -q`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add services/api/app/api/v1/routers/profile.py services/api/tests/test_dispositivos.py
git commit -m "feat(api): listar y desvincular dispositivos"
```

---

### Task 5: Backend — credencial biométrica y sesión con huella

**Files:**
- Modify: `services/api/app/api/v1/routers/auth.py`
- Test: `services/api/tests/test_biometria.py`

**Interfaces:**
- Consumes: `pin_check.verify`, `biometric.issue/revoke/valid_for`, `devices.touch`.
- Produces: `POST /v1/auth/biometric/enroll` `{pin}` → `{credential}`; `DELETE /v1/auth/biometric/current` → 204; `POST /v1/auth/sessions/biometric` (`X-Device-Id`, `{dni, credential}`) → `{result: "session", session_token, user: {id, dni, alias}}` | 401 `BIOMETRIC_REVOKED` | 423.

- [ ] **Step 1: Write the failing test**

`services/api/tests/test_biometria.py`:

```python
"""Entrar con huella: una credencial del servidor que la huella libera en el teléfono."""

from tests.conftest import PIN_DE_PRUEBA


async def _activar(client, registrado, pin=PIN_DE_PRUEBA):
    return await client.post(
        "/v1/auth/biometric/enroll", json={"pin": pin}, headers=registrado.auth
    )


async def _entrar(client, dni, credencial, device):
    return await client.post(
        "/v1/auth/sessions/biometric",
        json={"dni": dni, "credential": credencial},
        headers={"X-Device-Id": device},
    )


async def test_activar_y_entrar_con_huella(client, registrado):
    credencial = (await _activar(client, registrado)).json()["credential"]

    r = await _entrar(client, registrado.dni, credencial, f"dev-{registrado.dni}")

    assert r.status_code == 200
    cuerpo = r.json()
    assert cuerpo["result"] == "session"
    assert cuerpo["user"]["dni"] == registrado.dni
    nueva = {"Authorization": f"Bearer {cuerpo['session_token']}"}
    assert (await client.get("/v1/me", headers=nueva)).status_code == 200


async def test_activar_con_pin_errado_descuenta_intentos(client, registrado):
    r = await _activar(client, registrado, pin="111222")
    assert r.status_code == 401
    assert r.json()["attempts_left"] == 4


async def test_reactivar_invalida_la_credencial_anterior(client, registrado):
    vieja = (await _activar(client, registrado)).json()["credential"]
    nueva = (await _activar(client, registrado)).json()["credential"]

    assert (await _entrar(client, registrado.dni, vieja, f"dev-{registrado.dni}")).status_code == 401
    assert (await _entrar(client, registrado.dni, nueva, f"dev-{registrado.dni}")).status_code == 200


async def test_desactivar_la_revoca(client, registrado):
    credencial = (await _activar(client, registrado)).json()["credential"]

    r = await client.delete("/v1/auth/biometric/current", headers=registrado.auth)
    assert r.status_code == 204
    assert (await _entrar(client, registrado.dni, credencial, f"dev-{registrado.dni}")).status_code == 401
    # Idempotente.
    assert (await client.delete("/v1/auth/biometric/current", headers=registrado.auth)).status_code == 204


async def test_todos_los_rechazos_responden_igual(client, registrado, otro_registrado):
    credencial = (await _activar(client, registrado)).json()["credential"]

    casos = [
        await _entrar(client, registrado.dni, "inventada", f"dev-{registrado.dni}"),
        await _entrar(client, registrado.dni, credencial, "otro-telefono"),
        await _entrar(client, otro_registrado.dni, credencial, f"dev-{registrado.dni}"),
        await _entrar(client, "00000000", credencial, f"dev-{registrado.dni}"),
    ]

    assert {c.status_code for c in casos} == {401}
    assert len({c.text for c in casos}) == 1
    assert casos[0].json()["code"] == "BIOMETRIC_REVOKED"


async def test_un_dispositivo_desvinculado_no_entra_con_huella(
    client, registrado, otp_codes
):
    from tests.test_cambio_de_pin import _otra_sesion

    otra = await _otra_sesion(client, otp_codes, registrado.dni)
    credencial = (
        await client.post(
            "/v1/auth/biometric/enroll", json={"pin": PIN_DE_PRUEBA}, headers=otra
        )
    ).json()["credential"]
    lista = (await client.get("/v1/devices", headers=registrado.auth)).json()["dispositivos"]

    await client.delete(f"/v1/devices/{lista[1]['id']}", headers=registrado.auth)

    assert (await _entrar(client, registrado.dni, credencial, "telefono-2")).status_code == 401


async def test_con_el_dni_bloqueado_no_entra_ni_con_huella(client, registrado):
    credencial = (await _activar(client, registrado)).json()["credential"]
    for _ in range(5):
        await client.post(
            "/v1/auth/authenticate",
            json={"identifier": registrado.dni, "pin": "111222"},
            headers={"X-Device-Id": "telefono-x"},
        )

    r = await _entrar(client, registrado.dni, credencial, f"dev-{registrado.dni}")
    assert r.status_code == 423


async def test_los_fallos_con_huella_no_suman_intentos(client, registrado):
    for _ in range(10):
        await _entrar(client, registrado.dni, "inventada", f"dev-{registrado.dni}")

    ok = await client.post(
        "/v1/auth/authenticate",
        json={"identifier": registrado.dni, "pin": PIN_DE_PRUEBA},
        headers={"X-Device-Id": f"dev-{registrado.dni}"},
    )
    assert ok.json()["result"] == "session"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd services/api && .venv/bin/python -m pytest tests/test_biometria.py -q`
Expected: FAIL (404).

- [ ] **Step 3: Implement**

`app/api/v1/routers/auth.py`, al final:

```python
@router.post("/biometric/enroll")
async def enroll_biometric(
    payload: EnrollBiometricIn,
    row: SessionRow = Depends(current_session_row),
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    """El secreto se devuelve UNA vez; el servidor solo guarda su hash."""
    await pin_check.verify(session, user, payload.pin, row)
    secreto = await biometric.issue(session, user.id, row.device_id)
    await session.commit()
    return {"credential": secreto}


@router.delete("/biometric/current", status_code=status.HTTP_204_NO_CONTENT)
async def revoke_biometric(
    row: SessionRow = Depends(current_session_row),
    session: AsyncSession = Depends(get_session),
):
    await biometric.revoke(session, row.user_id, device_id=row.device_id)
    await session.commit()


def _biometria_rechazada() -> ApiError:
    # UN solo rechazo para todo: credencial inventada, revocada, de otro
    # teléfono, de otro DNI o DNI inexistente. Distinguirlos delataría cuáles
    # DNI tienen huella activa.
    return ApiError(
        ErrorCode.BIOMETRIC_REVOKED,
        "Entra con tu PIN.",
        status_code=status.HTTP_401_UNAUTHORIZED,
    )


@router.post("/sessions/biometric")
async def biometric_session(
    payload: BiometricSessionIn,
    x_device_id: str = Header(...),
    x_device_name: Optional[str] = Header(None),
    session: AsyncSession = Depends(get_session),
):
    """
    No suma intentos al bloqueo: el secreto tiene 256 bits y no se adivina.
    Pero SÍ respeta un bloqueo vigente: la huella no es un atajo para saltarlo.
    """
    for kind, value in (("dni", payload.dni), ("device", x_device_id)):
        bloqueo = await lockout.locked_until(session, kind, value)
        if bloqueo is not None:
            code = ErrorCode.IDENTIFIER_LOCKED if kind == "dni" else ErrorCode.DEVICE_LOCKED
            raise ApiError(
                code,
                "El ingreso está bloqueado por ahora.",
                status_code=status.HTTP_423_LOCKED,
                extra={"locked_until": bloqueo.isoformat()},
            )

    user = (
        await session.execute(select(User).where(User.dni == payload.dni))
    ).scalars().first()
    if user is None or not await biometric.valid_for(
        session, user.id, x_device_id, payload.credential
    ):
        raise _biometria_rechazada()

    vinculado = (
        await session.execute(
            select(Device).where(Device.user_id == user.id, Device.device_id == x_device_id)
        )
    ).scalars().one()
    vinculado.last_seen_at = utcnow()
    devices.touch(vinculado, x_device_name)
    token, _ = await sessions.open_session(session, user.id, x_device_id)
    await session.commit()
    return {
        "result": "session",
        "session_token": token,
        "user": {"id": user.id, "dni": user.dni, "alias": user.alias},
    }
```

- [ ] **Step 4: Run tests**

Run: `cd services/api && .venv/bin/python -m pytest -q`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add services/api/app/api/v1/routers/auth.py services/api/tests/test_biometria.py
git commit -m "feat(api): credencial biométrica y sesión con huella"
```

---

### Task 6: App — nombre del dispositivo en cada petición

**Files:**
- Create: `apps/mobile/lib/core/env/device_name.dart`
- Modify: `apps/mobile/lib/core/http/authenticated_dio.dart:31-47`, `apps/mobile/lib/core/injection/envs/shared/shared_backend_dependencies.dart:29-40`, `apps/mobile/pubspec.yaml`
- Test: `apps/mobile/test/core/http/authenticated_dio_test.dart` (crear si no existe; si existe, añadir el test)

**Interfaces:**
- Produces: `Future<String?> describeThisDevice()`; `buildAuthenticatedDio({..., String? deviceName})`.

- [ ] **Step 1: Add dependency**

Run: `cd apps/mobile && flutter pub add device_info_plus`
Expected: `pubspec.yaml` gana `device_info_plus: ^<versión resuelta>`.

- [ ] **Step 2: Write the failing test**

```dart
import 'dart:typed_data';

import 'package:cuycash/core/http/authenticated_dio.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Captura implements HttpClientAdapter {
  RequestOptions? ultima;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    ultima = options;
    return ResponseBody.fromString('{}', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('manda X-Device-Name cuando se conoce el nombre', () async {
    final captura = _Captura();
    final dio = buildAuthenticatedDio(
      baseUrl: 'http://x',
      deviceId: 'd1',
      deviceName: 'android · Pixel 8',
      readToken: () => null,
      onUnauthenticated: () {},
    )..httpClientAdapter = captura;

    await dio.get<dynamic>('/v1/me');

    expect(captura.ultima?.headers['X-Device-Name'], 'android · Pixel 8');
    expect(captura.ultima?.headers['X-Device-Id'], 'd1');
  });

  test('sin nombre no inventa la cabecera', () async {
    final captura = _Captura();
    final dio = buildAuthenticatedDio(
      baseUrl: 'http://x',
      deviceId: 'd1',
      readToken: () => null,
      onUnauthenticated: () {},
    )..httpClientAdapter = captura;

    await dio.get<dynamic>('/v1/me');

    expect(captura.ultima?.headers.containsKey('X-Device-Name'), isFalse);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd apps/mobile && flutter test test/core/http/authenticated_dio_test.dart`
Expected: FAIL (`No named parameter with the name 'deviceName'`).

- [ ] **Step 4: Implement**

`authenticated_dio.dart`: añadir el parámetro `String? deviceName,` tras `required String deviceId,` y cambiar las cabeceras base:

```dart
      headers: {
        'X-Device-Id': deviceId,
        // Solo para mostrar en "Dispositivos vinculados"; nada de seguridad
        // depende de él.
        'X-Device-Name': ?deviceName,
      },
```

`lib/core/env/device_name.dart`:

```dart
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Cómo se presenta este teléfono en "Dispositivos vinculados":
/// `android · Samsung SM-A546E` / `ios · iPhone14,5`. El formato
/// `<plataforma> · <modelo>` es el que el backend sabe separar.
///
/// `null` si no se puede leer: es un dato decorativo y su ausencia no debe
/// impedir arrancar la app.
Future<String?> describeThisDevice() async {
  try {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await info.androidInfo;
      return 'android · ${a.manufacturer} ${a.model}'.trim();
    }
    if (Platform.isIOS) {
      final i = await info.iosInfo;
      return 'ios · ${i.utsname.machine}';
    }
    return null;
  } catch (_) {
    return null;
  }
}
```

`shared_backend_dependencies.dart`: tras `final deviceId = await deviceStore.deviceId();` añadir `final deviceName = await describeThisDevice();` (import `../../../env/device_name.dart`) y pasar `deviceName: deviceName,` a `buildAuthenticatedDio`.

- [ ] **Step 5: Run tests and analyze**

Run: `cd apps/mobile && flutter test test/core/http && cd ../.. && flutter analyze`
Expected: PASS, `No issues found!`.

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/pubspec.yaml pubspec.lock apps/mobile/lib/core apps/mobile/test/core/http/authenticated_dio_test.dart
git commit -m "feat(app): cada petición dice qué teléfono la hace"
```

(Si el lock vive en `apps/mobile/pubspec.lock` en vez de la raíz, añadir ese.)

---

### Task 7: App — feature `profile` (dominio, memoria, HTTP)

**Files:**
- Create: `apps/mobile/lib/feature/profile/domain/personal_data.dart`, `profile_failure.dart`, `profile_repository.dart`, `alias_rules.dart`
- Create: `apps/mobile/lib/feature/profile/application/profile_actions.dart`
- Create: `apps/mobile/lib/feature/profile/infrastructure/memory_profile_repository.dart`, `http_profile_repository.dart`
- Test: `apps/mobile/test/feature/profile/profile_repository_contract.dart`, `memory_profile_repository_test.dart`, `http_profile_repository_test.dart`, `alias_rules_test.dart`

**Interfaces:**
- Produces:
  - `class PersonalData { dni, nombres, apellidos, emailMasked, alias: String; kycVerified: bool; clienteDesde: DateTime }`
  - `sealed class ProfileFailure` → `ProfileInvalidAlias`, `ProfileUnauthenticated`, `ProfileNetworkFailure`, `ProfileUnexpectedFailure`.
  - `abstract interface class ProfileRepository { FutureResult<ProfileFailure, PersonalData> me(); FutureResult<ProfileFailure, String> updateAlias(String alias); }`
  - `class ProfileActions { me(); updateAlias(String) }`
  - `abstract final class AliasRules { static String normalize(String); static bool isValid(String) }`
  - `MemoryProfileRepository({PersonalData? initial})`, `HttpProfileRepository({required Dio dio})`.

- [ ] **Step 1: Write the failing tests**

`test/feature/profile/alias_rules_test.dart`:

```dart
import 'package:cuycash/feature/profile/domain/alias_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normaliza como el backend: minúsculas, sin bordes, con @', () {
    expect(AliasRules.normalize('  Jenny_01 '), '@jenny_01');
    expect(AliasRules.normalize('@j.r'), '@j.r');
  });

  test('acepta 3 a 20 de [a-z0-9_.] y rechaza el resto', () {
    for (final bueno in ['@abc', '@j.r_9', '@${'a' * 20}']) {
      expect(AliasRules.isValid(AliasRules.normalize(bueno)), isTrue, reason: bueno);
    }
    for (final malo in ['ab', 'ñandú', 'con espacio', 'a' * 21, '@', '']) {
      expect(AliasRules.isValid(AliasRules.normalize(malo)), isFalse, reason: malo);
    }
  });
}
```

`test/feature/profile/profile_repository_contract.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/profile/domain/profile_failure.dart';
import 'package:cuycash/feature/profile/domain/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// La MISMA batería contra Memory y HTTP. [construir] entrega estado nuevo con
/// el titular [dni], alias inicial [aliasInicial], KYC verificado.
void probarContratoDePerfil(
  String nombre,
  ProfileRepository Function() construir, {
  required String dni,
  required String aliasInicial,
}) {
  T valorDe<T>(Result<ProfileFailure, T> r) =>
      r.match((f) => fail('No debía fallar: $f'), (v) => v);

  ProfileFailure falloDe(Result<ProfileFailure, Object?> r) {
    final failure = r.getLeft().toNullable();
    expect(failure, isA<ServerFailure<ProfileFailure>>(), reason: '$r');
    return (failure! as ServerFailure<ProfileFailure>).failure;
  }

  group('$nombre · contrato de ProfileRepository', () {
    test('me devuelve los datos con el correo enmascarado', () async {
      final datos = valorDe(await construir().me());
      expect(datos.dni, dni);
      expect(datos.alias, aliasInicial);
      expect(datos.emailMasked, contains('•'));
      expect(datos.kycVerified, isTrue);
      expect(datos.clienteDesde.isUtc, isTrue);
    });

    test('updateAlias normaliza, persiste y lo devuelve', () async {
      final repo = construir();
      expect(valorDe(await repo.updateAlias(' Nuevo_1 ')), '@nuevo_1');
      expect(valorDe(await repo.me()).alias, '@nuevo_1');
    });

    test('un alias inválido es invalidAlias', () async {
      expect(falloDe(await construir().updateAlias('ñandú')),
          isA<ProfileInvalidAlias>());
    });
  });
}
```

`test/feature/profile/memory_profile_repository_test.dart`:

```dart
import 'package:cuycash/feature/profile/infrastructure/memory_profile_repository.dart';

import 'profile_repository_contract.dart';

void main() {
  probarContratoDePerfil(
    'MemoryProfileRepository',
    MemoryProfileRepository.new,
    dni: MemoryProfileRepository.demo.dni,
    aliasInicial: MemoryProfileRepository.demo.alias,
  );
}
```

`test/feature/profile/http_profile_repository_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/profile/domain/profile_failure.dart';
import 'package:cuycash/feature/profile/infrastructure/http_profile_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'profile_repository_contract.dart';

/// Reproduce `services/api/app/api/v1/routers/profile.py` (`/v1/me*`).
class FakeProfileBackend implements HttpClientAdapter {
  String alias = '@jenny';
  ({int status, Object? body})? forced;
  DioException? throwIt;

  static final _alias = RegExp(r'^@[a-z0-9_.]{3,20}$');

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (throwIt case final e?) throw e;
    final (status, body) = switch (forced) {
      final f? => (f.status, f.body),
      _ => _route(o),
    };
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  (int, Object?) _route(RequestOptions o) {
    if (o.uri.path == '/v1/me' && o.method == 'GET') {
      return (200, {
        'dni': '71234567',
        'nombres': 'Jenny Marisol',
        'apellidos': 'Ruiz',
        'email_masked': 'j•••••@correo.pe',
        'alias': alias,
        'kyc_status': 'verified',
        'created_at': '2026-09-01T15:00:00.000000Z',
      });
    }
    if (o.uri.path == '/v1/me/alias' && o.method == 'PATCH') {
      final crudo = ((o.data as Map)['alias'] as String).trim().toLowerCase();
      final nuevo = crudo.startsWith('@') ? crudo : '@$crudo';
      if (!_alias.hasMatch(nuevo)) {
        return (422, {'code': 'INVALID_ALIAS', 'detail': 'x'});
      }
      alias = nuevo;
      return (200, {'alias': nuevo});
    }
    return (404, {'code': 'NOPE', 'detail': 'x'});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  HttpProfileRepository construir([FakeProfileBackend? backend]) {
    final dio = Dio(BaseOptions(
      baseUrl: 'http://x',
      validateStatus: (s) => s != null && s < 500,
    ))..httpClientAdapter = backend ?? FakeProfileBackend();
    return HttpProfileRepository(dio: dio);
  }

  probarContratoDePerfil(
    'HttpProfileRepository',
    construir,
    dni: '71234567',
    aliasInicial: '@jenny',
  );

  ProfileFailure? falloDe(Result<ProfileFailure, Object?> r) =>
      switch (r.getLeft().toNullable()) {
        ServerFailure(:final failure) => failure,
        _ => null,
      };

  test('401 es unauthenticated', () async {
    final backend = FakeProfileBackend()
      ..forced = (status: 401, body: {'code': 'UNAUTHENTICATED', 'detail': 'x'});
    expect(falloDe(await construir(backend).me()), isA<ProfileUnauthenticated>());
  });

  test('sin red es network', () async {
    final backend = FakeProfileBackend()
      ..throwIt = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
      );
    expect(falloDe(await construir(backend).me()), isA<ProfileNetworkFailure>());
  });

  test('kyc_status distinto de verified es kycVerified=false', () async {
    final backend = FakeProfileBackend();
    final repo = construir(backend);
    backend.forced = (status: 200, body: {
      'dni': '71234567',
      'nombres': 'J',
      'apellidos': 'R',
      'email_masked': 'j•••••@c.pe',
      'alias': '@j',
      'kyc_status': 'pending',
      'created_at': '2026-09-01T15:00:00.000000Z',
    });
    final datos = (await repo.me()).getRight().toNullable();
    expect(datos?.kycVerified, isFalse);
  });
}
```

**Hallazgo:** hoy ninguna ruta escribe `users.kyc_status`; queda siempre en `"pending"`, porque el KYC lo hace la app directamente contra el servicio externo y el backend nunca se entera. `kycVerified` es `true` solo si el servidor dice `"verified"`, y la pantalla (Task 8) **no afirma nada** cuando es `false`: mostrar "Verificación pendiente" a todos los usuarios sería falso. Que el backend registre el resultado del KYC queda fuera de este plan.

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd apps/mobile && flutter test test/feature/profile`
Expected: FAIL (imports inexistentes).

- [ ] **Step 3: Implement**

`lib/feature/profile/domain/personal_data.dart`:

```dart
/// Datos del titular tal como los guarda el servidor (vienen del KYC). Solo
/// lectura: cambiarlos exigiría volver a verificar la identidad.
class PersonalData {
  const PersonalData({
    required this.dni,
    required this.nombres,
    required this.apellidos,
    required this.emailMasked,
    required this.alias,
    required this.kycVerified,
    required this.clienteDesde,
  });

  final String dni;
  final String nombres;
  final String apellidos;

  /// Nunca el correo completo: el servidor ya lo manda enmascarado.
  final String emailMasked;
  final String alias;
  final bool kycVerified;

  /// En UTC; se pasa a hora local solo al mostrar.
  final DateTime clienteDesde;

  PersonalData copyWith({String? alias, bool? kycVerified}) => PersonalData(
        dni: dni,
        nombres: nombres,
        apellidos: apellidos,
        emailMasked: emailMasked,
        alias: alias ?? this.alias,
        kycVerified: kycVerified ?? this.kycVerified,
        clienteDesde: clienteDesde,
      );
}
```

`lib/feature/profile/domain/alias_rules.dart`:

```dart
/// La regla del alias, idéntica a la de `services/api/.../profile.py`. Vive en
/// el dominio para validar en vivo sin esperar al servidor; el servidor la
/// vuelve a aplicar.
abstract final class AliasRules {
  static final _valido = RegExp(r'^@[a-z0-9_.]{3,20}$');

  static String normalize(String texto) {
    final limpio = texto.trim().toLowerCase();
    return limpio.startsWith('@') ? limpio : '@$limpio';
  }

  static bool isValid(String normalizado) => _valido.hasMatch(normalizado);
}
```

`lib/feature/profile/domain/profile_failure.dart`:

```dart
/// Failures del perfil (viajan en `GlobalFailure.server`). Prefijo `Profile`
/// porque `NetworkFailure`/`Unauthenticated` ya existen en otras features.
sealed class ProfileFailure {
  const ProfileFailure();

  const factory ProfileFailure.invalidAlias() = ProfileInvalidAlias;
  const factory ProfileFailure.unauthenticated() = ProfileUnauthenticated;
  const factory ProfileFailure.network() = ProfileNetworkFailure;
  const factory ProfileFailure.unexpected() = ProfileUnexpectedFailure;
}

/// El servidor rechazó el formato del alias (422 `INVALID_ALIAS`).
final class ProfileInvalidAlias extends ProfileFailure {
  const ProfileInvalidAlias();
}

final class ProfileUnauthenticated extends ProfileFailure {
  const ProfileUnauthenticated();
}

final class ProfileNetworkFailure extends ProfileFailure {
  const ProfileNetworkFailure();
}

final class ProfileUnexpectedFailure extends ProfileFailure {
  const ProfileUnexpectedFailure();
}
```

`lib/feature/profile/domain/profile_repository.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';

import 'personal_data.dart';
import 'profile_failure.dart';

/// Datos del titular. Nunca lanza: devuelve `Result`.
abstract interface class ProfileRepository {
  FutureResult<ProfileFailure, PersonalData> me();

  /// Devuelve el alias ya normalizado por el servidor.
  FutureResult<ProfileFailure, String> updateAlias(String alias);
}
```

`lib/feature/profile/application/profile_actions.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';

import '../domain/personal_data.dart';
import '../domain/profile_failure.dart';
import '../domain/profile_repository.dart';

/// Operaciones finas del perfil. El bloc las consume; nunca toca el repo.
class ProfileActions {
  const ProfileActions(this._repo);

  final ProfileRepository _repo;

  FutureResult<ProfileFailure, PersonalData> me() => _repo.me();

  FutureResult<ProfileFailure, String> updateAlias(String alias) =>
      _repo.updateAlias(alias);
}
```

`lib/feature/profile/infrastructure/memory_profile_repository.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/alias_rules.dart';
import '../domain/personal_data.dart';
import '../domain/profile_failure.dart';
import '../domain/profile_repository.dart';

/// Impl en memoria (flavor `mock`). Aplica la misma regla de alias que el
/// backend.
class MemoryProfileRepository implements ProfileRepository {
  MemoryProfileRepository({PersonalData? initial}) : _datos = initial ?? demo;

  static final demo = PersonalData(
    dni: '70123456',
    nombres: 'Jheampierre',
    apellidos: 'Ruiz Salas',
    emailMasked: 'j•••••@correo.pe',
    alias: '@jheampierre',
    kycVerified: true,
    clienteDesde: DateTime.utc(2026, 9, 1, 15),
  );

  PersonalData _datos;

  @override
  FutureResult<ProfileFailure, PersonalData> me() async => right(_datos);

  @override
  FutureResult<ProfileFailure, String> updateAlias(String alias) async {
    final nuevo = AliasRules.normalize(alias);
    if (!AliasRules.isValid(nuevo)) {
      return left(const GlobalFailure.server(ProfileFailure.invalidAlias()));
    }
    _datos = _datos.copyWith(alias: nuevo);
    return right(nuevo);
  }
}
```

`lib/feature/profile/infrastructure/http_profile_repository.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/personal_data.dart';
import '../domain/profile_failure.dart';
import '../domain/profile_repository.dart';

/// Impl real contra `services/api` (`GET /v1/me`, `PATCH /v1/me/alias`).
/// [dio] debe venir de `buildAuthenticatedDio`. Errores por `code`, nunca por
/// el texto de `detail`.
class HttpProfileRepository implements ProfileRepository {
  HttpProfileRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  FutureResult<ProfileFailure, PersonalData> me() => _guard(() async {
        final response = await _dio.get<dynamic>('/v1/me');
        if (_failureFor(response) case final f?) {
          return left(GlobalFailure.server(f));
        }
        return right(_datos(_cuerpo(response)));
      });

  @override
  FutureResult<ProfileFailure, String> updateAlias(String alias) =>
      _guard(() async {
        final response =
            await _dio.patch<dynamic>('/v1/me/alias', data: {'alias': alias});
        if (_failureFor(response) case final f?) {
          return left(GlobalFailure.server(f));
        }
        return right(_cuerpo(response)['alias'] as String);
      });

  PersonalData _datos(Map<String, dynamic> j) => PersonalData(
        dni: j['dni'] as String,
        nombres: j['nombres'] as String,
        apellidos: j['apellidos'] as String,
        emailMasked: j['email_masked'] as String,
        alias: j['alias'] as String,
        kycVerified: j['kyc_status'] == 'verified',
        clienteDesde: DateTime.parse(j['created_at'] as String).toUtc(),
      );

  Map<String, dynamic> _cuerpo(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Cuerpo que no es un objeto JSON');
  }

  ProfileFailure? _failureFor(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) return null;
    if (status == 401) return const ProfileFailure.unauthenticated();
    final data = response.data;
    final body = data is Map ? data : const <Object?, Object?>{};
    return switch (body['code']) {
      'INVALID_ALIAS' => const ProfileFailure.invalidAlias(),
      _ => const ProfileFailure.unexpected(),
    };
  }

  Future<Either<GlobalFailure<ProfileFailure>, T>> _guard<T>(
    Future<Either<GlobalFailure<ProfileFailure>, T>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      return left(GlobalFailure.server(switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError => const ProfileFailure.network(),
        _ => const ProfileFailure.unexpected(),
      }));
    } catch (error, stackTrace) {
      return left(GlobalFailure.unexpected(error, stackTrace));
    }
  }
}
```

- [ ] **Step 4: Run tests and analyze**

Run: `cd apps/mobile && flutter test test/feature/profile && cd ../.. && flutter analyze`
Expected: PASS, `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/feature/profile apps/mobile/test/feature/profile
git commit -m "feat(app): feature profile con Memory y HTTP"
```

---

### Task 8: App — composición del perfil y pantalla de datos personales

**Files:**
- Modify: `apps/mobile/lib/core/injection/app_dependencies.dart`, `envs/mock_dependencies.dart`, `envs/shared/shared_backend_dependencies.dart`
- Create: `apps/mobile/lib/core/injection/modules/profile_module.dart`
- Create: `apps/mobile/lib/presentation/profile/personal_data/bloc/personal_data_bloc.dart` (+ `_event.dart`, `_state.dart`, `.freezed.dart`), `personal_data_screen.dart`
- Modify: `apps/mobile/lib/presentation/app/app_routes.dart`, `router.dart`, `apps/mobile/lib/presentation/profile/profile_screen.dart`, `apps/mobile/lib/l10n/arb/app_es.arb`
- Test: `apps/mobile/test/presentation/profile/personal_data_screen_test.dart`, `apps/mobile/test/presentation/profile/profile_screen_test.dart`

**Interfaces:**
- Consumes: `ProfileActions` (Task 7), `SkeletonBox`.
- Produces:
  - `AppDependencies.profileRepository` y `profileActions`; `ProfileModule.create(deps) -> ProfileActions`.
  - Rutas `AppRoutes.perfilDatos = '/perfil/datos'`, `perfilAlias = '/perfil/alias'`, `perfilPin = '/perfil/pin'`, `perfilBiometria = '/perfil/biometria'`, `perfilDispositivos = '/perfil/dispositivos'`, todas declaradas ya (las pantallas llegan en las tareas siguientes).
  - `PersonalDataBloc(ProfileActions)` con eventos `started`/`retried` y estado `{status: loading|ready|error, datos: PersonalData?, failure: ProfileFailure?}`.

- [ ] **Step 1: ARB**

Añadir a `app_es.arb`:

```json
  "personalDataTitle": "Datos personales",
  "personalDataNames": "Nombres",
  "personalDataSurnames": "Apellidos",
  "personalDataEmail": "Correo",
  "personalDataAlias": "Alias",
  "personalDataSince": "Cliente desde",
  "personalDataVerified": "Identidad verificada",
  "personalDataReadOnly": "Estos datos vienen de tu verificación de identidad. Si alguno no es correcto, escríbenos por WhatsApp.",
  "personalDataError": "No pudimos cargar tus datos.",
```

Run: `cd apps/mobile && flutter gen-l10n`

- [ ] **Step 2: Write the failing widget test**

`test/presentation/profile/personal_data_screen_test.dart`:

```dart
import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/profile/application/profile_actions.dart';
import 'package:cuycash/feature/profile/domain/personal_data.dart';
import 'package:cuycash/feature/profile/domain/profile_failure.dart';
import 'package:cuycash/feature/profile/domain/profile_repository.dart';
import 'package:cuycash/feature/profile/infrastructure/memory_profile_repository.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/profile/personal_data/bloc/personal_data_bloc.dart';
import 'package:cuycash/presentation/profile/personal_data/personal_data_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _Controlado implements ProfileRepository {
  final pendiente = Completer<Result<ProfileFailure, PersonalData>>();
  int llamadas = 0;

  @override
  FutureResult<ProfileFailure, PersonalData> me() {
    llamadas++;
    return pendiente.future;
  }

  @override
  FutureResult<ProfileFailure, String> updateAlias(String alias) async =>
      right(alias);
}

Widget _app(ProfileRepository repo) => MaterialApp(
      theme: CuyCashTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider(
        create: (_) => PersonalDataBloc(ProfileActions(repo))
          ..add(const PersonalDataEvent.started()),
        child: const PersonalDataScreen(),
      ),
    );

void main() {
  testWidgets('mientras carga muestra la silueta', (tester) async {
    final repo = _Controlado();
    await tester.pumpWidget(_app(repo));
    await tester.pump();

    expect(find.byType(SkeletonBox), findsWidgets);
    repo.pendiente.complete(right(MemoryProfileRepository.demo));
    await tester.pumpAndSettle();
  });

  testWidgets('con KYC sin confirmar no afirma nada sobre la verificación',
      (tester) async {
    await tester.pumpWidget(_app(MemoryProfileRepository(
      initial: MemoryProfileRepository.demo.copyWith(kycVerified: false),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Identidad verificada'), findsNothing);
    expect(find.textContaining('pendiente'), findsNothing);
  });

  testWidgets('muestra los datos y el sello de verificación', (tester) async {
    await tester.pumpWidget(_app(MemoryProfileRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Jheampierre'), findsOneWidget);
    expect(find.text('Ruiz Salas'), findsOneWidget);
    expect(find.text('70123456'), findsOneWidget);
    expect(find.text('j•••••@correo.pe'), findsOneWidget);
    expect(find.text('@jheampierre'), findsOneWidget);
    expect(find.text('Identidad verificada'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('un error ofrece reintentar y vuelve a pedir', (tester) async {
    final repo = _Controlado();
    await tester.pumpWidget(_app(repo));
    repo.pendiente.complete(
        left(const GlobalFailure.server(ProfileFailure.network())));
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar tus datos.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(repo.llamadas, 2);
  });
}
```

(`Reintentar` es `homeRetry` en el ARB; se reutiliza.)

- [ ] **Step 3: Run test to verify it fails**

Run: `cd apps/mobile && flutter test test/presentation/profile/personal_data_screen_test.dart`
Expected: FAIL (imports inexistentes).

- [ ] **Step 4: Implement bloc**

`lib/presentation/profile/personal_data/bloc/personal_data_event.dart`:

```dart
part of 'personal_data_bloc.dart';

@freezed
sealed class PersonalDataEvent with _$PersonalDataEvent {
  const factory PersonalDataEvent.started() = PersonalDataStarted;
}
```

`personal_data_state.dart`:

```dart
part of 'personal_data_bloc.dart';

enum PersonalDataStatus { loading, ready, error }

@freezed
abstract class PersonalDataState with _$PersonalDataState {
  const factory PersonalDataState({
    @Default(PersonalDataStatus.loading) PersonalDataStatus status,
    PersonalData? datos,
  }) = _PersonalDataState;
}
```

`personal_data_bloc.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../feature/profile/application/profile_actions.dart';
import '../../../../feature/profile/domain/personal_data.dart';

part 'personal_data_bloc.freezed.dart';
part 'personal_data_event.dart';
part 'personal_data_state.dart';

/// Carga los datos del titular. `started` también sirve para reintentar.
class PersonalDataBloc extends Bloc<PersonalDataEvent, PersonalDataState> {
  PersonalDataBloc(this._actions) : super(const PersonalDataState()) {
    on<PersonalDataStarted>((event, emit) async {
      emit(const PersonalDataState());
      final result = await _actions.me();
      emit(result.match(
        (_) => const PersonalDataState(status: PersonalDataStatus.error),
        (datos) =>
            PersonalDataState(status: PersonalDataStatus.ready, datos: datos),
      ));
    });
  }

  final ProfileActions _actions;
}
```

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Implement screen**

`lib/presentation/profile/personal_data/personal_data_screen.dart`:

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../feature/profile/domain/personal_data.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/profile_data_row.dart';
import 'bloc/personal_data_bloc.dart';

/// Datos personales: solo lectura. Vienen del KYC; corregirlos es un trámite
/// con soporte, no un campo editable.
class PersonalDataScreen extends StatelessWidget {
  const PersonalDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: CuyCashColors.surfaceContainerLow,
      appBar: AppBar(
        title: Text(l10n.personalDataTitle),
        backgroundColor: CuyCashColors.surfaceContainerLow,
      ),
      body: BlocBuilder<PersonalDataBloc, PersonalDataState>(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
          children: switch ((state.status, state.datos)) {
            (PersonalDataStatus.ready, final PersonalData datos) =>
              _ready(l10n, datos),
            (PersonalDataStatus.error, _) => _error(context, l10n),
            _ => _loading(),
          },
        ),
      ),
    );
  }

  List<Widget> _ready(AppLocalizations l10n, PersonalData d) => [
        // Solo se afirma lo que el servidor confirmó. Hoy el backend no
        // registra el resultado del KYC (`kyc_status` queda en `pending`), así
        // que decir "pendiente" sería falso para todos.
        if (d.kycVerified) ...[
          Row(
            children: [
              const Icon(Icons.verified_user,
                  size: 18, color: CuyCashColors.success),
              const SizedBox(width: CuyCashSpacing.stackSm),
              Text(l10n.personalDataVerified, style: CuyCashTypography.labelMd),
            ],
          ),
          const SizedBox(height: CuyCashSpacing.stackMd),
        ],
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, (label, value)) in [
                (l10n.personalDataNames, d.nombres),
                (l10n.personalDataSurnames, d.apellidos),
                (l10n.profileDniLabel, d.dni),
                (l10n.personalDataEmail, d.emailMasked),
                (l10n.personalDataAlias, d.alias),
                (
                  l10n.personalDataSince,
                  DateFormat('dd/MM/yyyy').format(d.clienteDesde.toLocal()),
                ),
              ].indexed) ...[
                if (i > 0)
                  const Divider(height: 1, color: CuyCashColors.divider),
                ProfileDataRow(label: label, value: value),
              ],
            ],
          ),
        ),
        const SizedBox(height: CuyCashSpacing.stackMd),
        InfoStrip(icon: Icons.info_outline, text: l10n.personalDataReadOnly),
      ];

  List<Widget> _error(BuildContext context, AppLocalizations l10n) => [
        const SizedBox(height: CuyCashSpacing.stackLg),
        Text(
          l10n.personalDataError,
          textAlign: TextAlign.center,
          style: CuyCashTypography.bodyMd,
        ),
        const SizedBox(height: CuyCashSpacing.stackMd),
        SecondaryButton(
          label: l10n.homeRetry,
          onPressed: () => context
              .read<PersonalDataBloc>()
              .add(const PersonalDataEvent.started()),
        ),
      ];

  List<Widget> _loading() => [
        const SkeletonBox(width: 160),
        const SizedBox(height: CuyCashSpacing.stackMd),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 6; i++) ...[
                if (i > 0) const SizedBox(height: CuyCashSpacing.stackMd),
                const SkeletonBox(width: 220),
              ],
            ],
          ),
        ),
      ];
}
```

Antes de usar `ProfileDataRow`, leer `lib/presentation/profile/widgets/profile_data_row.dart` y confirmar que acepta `label`/`value` (así lo usa `profile_screen.dart`).

- [ ] **Step 6: Wire dependencies, routes and the profile tile**

`app_dependencies.dart`: import `../../feature/profile/application/profile_actions.dart` y `../../feature/profile/domain/profile_repository.dart`; añadir `required this.profileRepository,` al constructor y:

```dart
  /// Datos del titular y alias. Los blocs consumen [profileActions].
  final ProfileRepository profileRepository;
  ProfileActions get profileActions => ProfileActions(profileRepository);
```

`mock_dependencies.dart`: `profileRepository: MemoryProfileRepository(),`.
`shared_backend_dependencies.dart`: `profileRepository: HttpProfileRepository(dio: dio),`.
Buscar con `grep -rn "AppDependencies(" apps/mobile/test` los tests que construyen `AppDependencies` a mano y añadirles `profileRepository: MemoryProfileRepository(),`.

`lib/core/injection/modules/profile_module.dart`:

```dart
import '../../../feature/profile/application/profile_actions.dart';
import '../app_dependencies.dart';

/// Wiring del perfil: los blocs reciben las acciones, nunca el repositorio.
abstract final class ProfileModule {
  static ProfileActions create(AppDependencies deps) => deps.profileActions;
}
```

`app_routes.dart`, junto a `perfil`:

```dart
  // Subpantallas del perfil. Se abren con `push` sobre la pestaña y fuera del
  // shell, para que tapen la barra inferior como el detalle de movimiento.
  static const perfilDatos = '/perfil/datos';
  static const perfilAlias = '/perfil/alias';
  static const perfilPin = '/perfil/pin';
  static const perfilBiometria = '/perfil/biometria';
  static const perfilDispositivos = '/perfil/dispositivos';
```

`router.dart`: tras la `GoRoute` de `AppRoutes.movimiento`:

```dart
      GoRoute(
        path: AppRoutes.perfilDatos,
        builder: (context, state) => BlocProvider(
          create: (_) => PersonalDataBloc(ProfileModule.create(deps))
            ..add(const PersonalDataEvent.started()),
          child: const PersonalDataScreen(),
        ),
      ),
```

(imports de `profile_module.dart`, `personal_data_bloc.dart`, `personal_data_screen.dart`).

`profile_screen.dart`: en el tile de `profileItemPersonalData`, `onTap: () => context.push(AppRoutes.perfilDatos),` (import `package:go_router/go_router.dart` y `../app/app_routes.dart`).

- [ ] **Step 7: Update the profile screen test**

En `test/presentation/profile/profile_screen_test.dart`, añadir:

```dart
  testWidgets('"Datos personales" navega a su pantalla', (tester) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const ProfileScreen()),
      GoRoute(
        path: '/perfil/datos',
        builder: (_, _) => const Scaffold(body: Text('DATOS')),
      ),
    ]);
    addTearDown(router.dispose);
    // Envolver con los mismos providers que el test existente usa para
    // ProfileScreen (DeviceActions + AuthBloc), con MaterialApp.router.
    await tester.pumpWidget(wrapRouter(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Datos personales'));
    await tester.pumpAndSettle();

    expect(find.text('DATOS'), findsOneWidget);
  });
```

`wrapRouter` es un helper local nuevo en ese archivo: copia el `wrap()` existente del test, pero con `MaterialApp.router(routerConfig: router, …)` en lugar de `MaterialApp(home: …)`.

- [ ] **Step 8: Run tests and analyze**

Run: `cd apps/mobile && flutter test && cd ../.. && flutter analyze`
Expected: PASS, `No issues found!`.

- [ ] **Step 9: Commit**

```bash
git add apps/mobile/lib apps/mobile/test
git commit -m "feat(app): pantalla de datos personales"
```

---

### Task 9: App — editar alias

**Files:**
- Create: `apps/mobile/lib/presentation/profile/alias/bloc/edit_alias_bloc.dart` (+ `_event`, `_state`, `.freezed`), `edit_alias_screen.dart`
- Modify: `router.dart`, `profile_screen.dart`, `app_es.arb`
- Test: `apps/mobile/test/presentation/profile/edit_alias_screen_test.dart`

**Interfaces:**
- Consumes: `ProfileActions.updateAlias`, `AliasRules`, `DeviceActions.readUser/saveUser`.
- Produces: `EditAliasBloc({required ProfileActions profile, required DeviceActions device, required String initial})`; eventos `changed(String)`, `submitted()`; estado `{input, initial, status: editing|saving|saved, error: AliasError?}` con `enum AliasError { invalid, network, generic }` y getters `normalized`, `canSave`.
- `EditAliasScreen` hace `pop(true)` al guardar; `ProfileScreen` muestra `aliasSaved` si vuelve `true`.

- [ ] **Step 1: ARB**

```json
  "aliasTitle": "Editar mi alias",
  "aliasLabel": "Tu alias",
  "aliasHelp": "De 3 a 20 letras, números, punto o guion bajo. Es como te saludamos; para enviarte dinero se usa tu DNI.",
  "aliasInvalid": "Usa de 3 a 20 letras sin tildes, números, punto o guion bajo.",
  "aliasSave": "Guardar",
  "aliasSaved": "Listo, tu alias cambió.",
  "aliasNetwork": "No pudimos guardar tu alias. Revisa tu conexión e inténtalo de nuevo.",
```

Run: `cd apps/mobile && flutter gen-l10n`

- [ ] **Step 2: Write the failing test**

`test/presentation/profile/edit_alias_screen_test.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/domain/remembered_user.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/profile/application/profile_actions.dart';
import 'package:cuycash/feature/profile/domain/personal_data.dart';
import 'package:cuycash/feature/profile/domain/profile_failure.dart';
import 'package:cuycash/feature/profile/domain/profile_repository.dart';
import 'package:cuycash/feature/profile/infrastructure/memory_profile_repository.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/profile/alias/bloc/edit_alias_bloc.dart';
import 'package:cuycash/presentation/profile/alias/edit_alias_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

class _SinRed implements ProfileRepository {
  @override
  FutureResult<ProfileFailure, PersonalData> me() async =>
      right(MemoryProfileRepository.demo);

  @override
  FutureResult<ProfileFailure, String> updateAlias(String alias) async =>
      left(const GlobalFailure.server(ProfileFailure.network()));
}

void main() {
  late DeviceActions device;
  bool? resultado;

  setUp(() async {
    device = DeviceActions(MemoryDeviceStore());
    await device.saveUser(const RememberedUser(
        dni: '70123456', fullName: 'Jheampierre Ruiz', alias: '@jheampierre'));
    resultado = null;
  });

  Future<void> abrir(WidgetTester tester, ProfileRepository repo) async {
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => TextButton(
          onPressed: () async =>
              resultado = await context.push<bool>('/alias'),
          child: const Text('ABRIR'),
        ),
      ),
      GoRoute(
        path: '/alias',
        builder: (_, _) => BlocProvider(
          create: (_) => EditAliasBloc(
            profile: ProfileActions(repo),
            device: device,
            initial: '@jheampierre',
          ),
          child: const EditAliasScreen(),
        ),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      theme: CuyCashTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ));
    await tester.tap(find.text('ABRIR'));
    await tester.pumpAndSettle();
  }

  Finder guardar() => find.widgetWithText(ElevatedButton, 'Guardar');

  testWidgets('sin cambios o con formato inválido no deja guardar',
      (tester) async {
    await abrir(tester, MemoryProfileRepository());
    expect(tester.widget<ElevatedButton>(guardar()).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'ñandú');
    await tester.pump();
    expect(find.text('Usa de 3 a 20 letras sin tildes, números, punto o guion bajo.'),
        findsOneWidget);
    expect(tester.widget<ElevatedButton>(guardar()).onPressed, isNull);
  });

  testWidgets('guardar actualiza el usuario recordado y vuelve con true',
      (tester) async {
    await abrir(tester, MemoryProfileRepository());

    await tester.enterText(find.byType(TextField), 'Jheam_01');
    await tester.pump();
    await tester.tap(guardar());
    await tester.pumpAndSettle();

    expect(resultado, isTrue);
    expect((await device.readUser())?.alias, '@jheam_01');
  });

  testWidgets('sin red avisa y se queda', (tester) async {
    await abrir(tester, _SinRed());

    await tester.enterText(find.byType(TextField), 'otro_alias');
    await tester.pump();
    await tester.tap(guardar());
    await tester.pumpAndSettle();

    expect(find.textContaining('No pudimos guardar tu alias'), findsOneWidget);
    expect(resultado, isNull);
    expect((await device.readUser())?.alias, '@jheampierre');
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd apps/mobile && flutter test test/presentation/profile/edit_alias_screen_test.dart`
Expected: FAIL.

- [ ] **Step 4: Implement bloc**

`edit_alias_event.dart`:

```dart
part of 'edit_alias_bloc.dart';

@freezed
sealed class EditAliasEvent with _$EditAliasEvent {
  const factory EditAliasEvent.changed(String input) = EditAliasChanged;
  const factory EditAliasEvent.submitted() = EditAliasSubmitted;
}
```

`edit_alias_state.dart`:

```dart
part of 'edit_alias_bloc.dart';

enum EditAliasStatus { editing, saving, saved }

enum AliasError { invalid, network, generic }

@freezed
abstract class EditAliasState with _$EditAliasState {
  const factory EditAliasState({
    required String initial,
    @Default('') String input,
    @Default(EditAliasStatus.editing) EditAliasStatus status,
    AliasError? error,
  }) = _EditAliasState;

  const EditAliasState._();

  String get normalized => AliasRules.normalize(input);

  /// El formato se avisa en vivo solo cuando hay algo escrito.
  bool get showsFormatError =>
      input.trim().isNotEmpty && !AliasRules.isValid(normalized);

  bool get canSave =>
      status == EditAliasStatus.editing &&
      AliasRules.isValid(normalized) &&
      normalized != initial;
}
```

`edit_alias_bloc.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../feature/device/application/device_actions.dart';
import '../../../../feature/device/domain/remembered_user.dart';
import '../../../../feature/profile/application/profile_actions.dart';
import '../../../../feature/profile/domain/alias_rules.dart';
import '../../../../feature/profile/domain/profile_failure.dart';

part 'edit_alias_bloc.freezed.dart';
part 'edit_alias_event.dart';
part 'edit_alias_state.dart';

/// Edita el alias. Al guardar también actualiza el usuario recordado en este
/// teléfono, para que el saludo del inicio lo muestre sin volver a entrar.
class EditAliasBloc extends Bloc<EditAliasEvent, EditAliasState> {
  EditAliasBloc({
    required ProfileActions profile,
    required DeviceActions device,
    required String initial,
  })  : _profile = profile,
        _device = device,
        super(EditAliasState(
          initial: initial,
          input: initial.startsWith('@') ? initial.substring(1) : initial,
        )) {
    on<EditAliasChanged>((event, emit) =>
        emit(state.copyWith(input: event.input, error: null)));
    on<EditAliasSubmitted>(_onSubmitted);
  }

  final ProfileActions _profile;
  final DeviceActions _device;

  Future<void> _onSubmitted(
    EditAliasSubmitted event,
    Emitter<EditAliasState> emit,
  ) async {
    if (!state.canSave) return;
    emit(state.copyWith(status: EditAliasStatus.saving, error: null));
    final result = await _profile.updateAlias(state.normalized);
    await result.match(
      (failure) async => emit(state.copyWith(
        status: EditAliasStatus.editing,
        error: switch (failure) {
          ServerFailure(failure: ProfileInvalidAlias()) => AliasError.invalid,
          ServerFailure(failure: ProfileNetworkFailure()) => AliasError.network,
          _ => AliasError.generic,
        },
      )),
      (alias) async {
        final user = await _device.readUser();
        if (user != null) {
          await _device.saveUser(RememberedUser(
              dni: user.dni, fullName: user.fullName, alias: alias));
        }
        emit(state.copyWith(status: EditAliasStatus.saved));
      },
    );
  }
}
```

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Implement screen**

`edit_alias_screen.dart`:

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import 'bloc/edit_alias_bloc.dart';

/// Editar alias: un campo con `@` fijo y validación en vivo. Cierra con
/// `pop(true)` al guardar; el perfil avisa.
class EditAliasScreen extends StatefulWidget {
  const EditAliasScreen({super.key});

  @override
  State<EditAliasScreen> createState() => _EditAliasScreenState();
}

class _EditAliasScreenState extends State<EditAliasScreen> {
  late final _controller =
      TextEditingController(text: context.read<EditAliasBloc>().state.input);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _errorText(AppLocalizations l10n, EditAliasState state) =>
      switch (state.error) {
        AliasError.invalid => l10n.aliasInvalid,
        AliasError.network => l10n.aliasNetwork,
        AliasError.generic => l10n.errorGeneric,
        null => state.showsFormatError ? l10n.aliasInvalid : null,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<EditAliasBloc, EditAliasState>(
      listenWhen: (p, c) => c.status == EditAliasStatus.saved,
      listener: (context, _) => context.pop(true),
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(l10n.aliasTitle)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CuyCashTextField(
                  label: l10n.aliasLabel,
                  controller: _controller,
                  autofocus: true,
                  prefixText: '@',
                  errorText: _errorText(l10n, state),
                  onChanged: (v) => context
                      .read<EditAliasBloc>()
                      .add(EditAliasEvent.changed(v)),
                ),
                const SizedBox(height: CuyCashSpacing.stackSm),
                Text(
                  l10n.aliasHelp,
                  style: CuyCashTypography.labelSm.copyWith(
                    color: CuyCashColors.secondaryText,
                  ),
                ),
                const Spacer(),
                PrimaryButton(
                  label: l10n.aliasSave,
                  loading: state.status == EditAliasStatus.saving,
                  onPressed: state.canSave
                      ? () => context
                          .read<EditAliasBloc>()
                          .add(const EditAliasEvent.submitted())
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

`CuyCashTextField` hoy no tiene `prefixText`. Leer `packages/design_system/lib/src/cuycash_text_field.dart` y añadir un parámetro opcional `final String? prefixText;` pasado a `InputDecoration(prefixText: prefixText, …)`, siguiendo cómo ya pasa `prefixIcon`.

- [ ] **Step 6: Wire route and tile**

`router.dart`:

```dart
      GoRoute(
        path: AppRoutes.perfilAlias,
        builder: (context, state) => BlocProvider(
          create: (_) => EditAliasBloc(
            profile: ProfileModule.create(deps),
            device: DeviceModule.create(deps),
            // El alias vigente llega del perfil; sin él se parte vacío.
            initial: state.extra as String? ?? '',
          ),
          child: const EditAliasScreen(),
        ),
      ),
```

(Confirmar con `cat apps/mobile/lib/core/injection/modules/device_module.dart` que `DeviceModule.create(deps)` devuelve `DeviceActions`; el router ya lo usa así.)

`profile_screen.dart`, tile `profileItemAlias`:

```dart
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final cambio = await context.push<bool>(
                          AppRoutes.perfilAlias,
                          extra: user.alias);
                      if (cambio == true) {
                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                              SnackBar(content: Text(l10n.aliasSaved)));
                      }
                    },
```

`RememberedUserBuilder` (`lib/presentation/session/remembered_user_builder.dart`) hoy lee el usuario **una sola vez** en `initState` (`_load()`), así que el perfil seguiría mostrando el alias viejo. Darle un `GlobalKey<RememberedUserBuilderState>` desde `ProfileScreen` y hacer público su `_load` como `Future<void> reload()`; el perfil llama `await _userKey.currentState?.reload()` cuando `cambio == true`. `ProfileScreen` pasa a ser `StatefulWidget` para guardar la key. Añadir un test en `profile_screen_test.dart`: tras volver con `true` y un `DeviceActions` cuyo usuario ya tiene el alias nuevo, el alias nuevo aparece en pantalla.

- [ ] **Step 7: Run tests and analyze**

Run: `cd apps/mobile && flutter test && cd ../.. && flutter analyze`
Expected: PASS, `No issues found!`.

- [ ] **Step 8: Commit**

```bash
git add apps/mobile packages/design_system
git commit -m "feat(app): editar el alias desde el perfil"
```

---

### Task 10: App — feature `security`, sesión con huella y credencial guardada

**Files:**
- Create: `apps/mobile/lib/feature/security/domain/linked_device.dart`, `security_failure.dart`, `security_repository.dart`
- Create: `apps/mobile/lib/feature/security/application/security_actions.dart`
- Create: `apps/mobile/lib/feature/security/infrastructure/memory_security_state.dart`, `memory_security_repository.dart`, `http_security_repository.dart`
- Create: `apps/mobile/lib/feature/auth/domain/pin_rules.dart`
- Modify: `apps/mobile/lib/presentation/register/bloc/register_bloc.dart:38-58` (delegar en `PinRules`)
- Modify: `apps/mobile/lib/feature/auth/domain/auth_repository.dart`, `auth_failure.dart`, `application/auth_actions.dart`, `infrastructure/http_auth_repository.dart`, `infrastructure/memory_auth_repository.dart`
- Modify: `apps/mobile/lib/feature/device/domain/device_store.dart`, `infrastructure/secure_device_store.dart`, `infrastructure/memory_device_store.dart`, `application/device_actions.dart`
- Modify: `app_dependencies.dart`, `mock_dependencies.dart`, `shared_backend_dependencies.dart`; create `modules/security_module.dart`
- Test: `apps/mobile/test/feature/security/security_repository_contract.dart`, `memory_security_repository_test.dart`, `http_security_repository_test.dart`; `apps/mobile/test/feature/auth/pin_rules_test.dart`; add to `test/feature/auth/memory_auth_repository_test.dart`, `http_auth_repository_test.dart`, `test/feature/device/memory_device_store_test.dart`

**Interfaces:**
- Produces:
  - `class LinkedDevice { id: String; nombre: String?; plataforma: String?; vinculadoEl: DateTime; ultimoUso: DateTime; esEste: bool; conHuella: bool }`
  - `sealed class SecurityFailure` → `SecurityWrongPin(int attemptsLeft)`, `SecurityLocked(DateTime until)`, `SecurityWeakPin`, `SecurityPinUnchanged`, `SecurityCannotUnlinkCurrent`, `SecurityDeviceNotFound`, `SecurityBiometricUnavailable`, `SecurityUnauthenticated`, `SecurityNetworkFailure`, `SecurityUnexpectedFailure`.
  - `abstract interface class SecurityRepository { FutureResult<SecurityFailure, int> changePin({required String current, required String nuevo}); FutureResult<SecurityFailure, List<LinkedDevice>> devices(); FutureResult<SecurityFailure, Unit> unlinkDevice(String id); FutureResult<SecurityFailure, String> enrollBiometric(String pin); FutureResult<SecurityFailure, Unit> revokeBiometric(); }`
  - `class SecurityActions` (misma firma, delegación fina).
  - `class MemorySecurityState { String pin; String dni; String thisDeviceId; List<LinkedDevice> devices; Map<String, String> credentials /* secreto → deviceId */; int attemptsLeft; DateTime? lockedUntil }`
  - `AuthRepository.signInWithBiometric({required String dni, required String credential})` → `FutureResult<AuthFailure, AuthSession>`; `AuthFailure.biometricRevoked()` = `BiometricRevoked`.
  - `DeviceStore.readBiometricCredential() -> Future<String?>`, `saveBiometricCredential(String) -> Future<bool>` (false si no se pudo escribir), `clearBiometricCredential() -> Future<void>`; `clearUser()` también borra la credencial. `DeviceActions` expone las tres.
  - `abstract final class PinRules { hasSixDigits, hasNoRepeatedDigit, hasNoSequence, isValid }` (cada una `static bool f(String pin)`).
  - `AppDependencies.securityRepository`, `securityActions`; `SecurityModule.create(deps) -> SecurityActions`.

- [ ] **Step 1: Write the failing tests**

`test/feature/auth/pin_rules_test.dart`:

```dart
import 'package:cuycash/feature/auth/domain/pin_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('las mismas reglas que el backend (pin_is_valid)', () {
    expect(PinRules.isValid('839201'), isTrue);
    expect(PinRules.isValid('111111'), isFalse);
    expect(PinRules.isValid('123456'), isFalse);
    expect(PinRules.isValid('654321'), isFalse);
    expect(PinRules.isValid('12345'), isFalse);
  });
}
```

`test/feature/security/security_repository_contract.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/security/domain/security_failure.dart';
import 'package:cuycash/feature/security/domain/security_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Escenario que [construir] entrega con estado nuevo: PIN actual [pin],
/// dos dispositivos (este primero, sin huella; otro con id [otroId]),
/// 5 intentos antes del bloqueo.
void probarContratoDeSeguridad(
  String nombre,
  SecurityRepository Function() construir, {
  required String pin,
  required String otroId,
}) {
  T valorDe<T>(Result<SecurityFailure, T> r) =>
      r.match((f) => fail('No debía fallar: $f'), (v) => v);

  SecurityFailure falloDe(Result<SecurityFailure, Object?> r) {
    final failure = r.getLeft().toNullable();
    expect(failure, isA<ServerFailure<SecurityFailure>>(), reason: '$r');
    return (failure! as ServerFailure<SecurityFailure>).failure;
  }

  group('$nombre · contrato de SecurityRepository', () {
    test('cambiar el PIN devuelve las sesiones cerradas', () async {
      expect(valorDe(await construir().changePin(current: pin, nuevo: '502718')),
          greaterThanOrEqualTo(0));
    });

    test('PIN actual errado trae los intentos restantes', () async {
      final f = falloDe(
          await construir().changePin(current: '111222', nuevo: '502718'));
      expect(f, isA<SecurityWrongPin>());
      expect((f as SecurityWrongPin).attemptsLeft, 4);
    });

    test('al quinto fallo, locked', () async {
      final repo = construir();
      for (var i = 0; i < 4; i++) {
        await repo.changePin(current: '111222', nuevo: '502718');
      }
      expect(falloDe(await repo.changePin(current: '111222', nuevo: '502718')),
          isA<SecurityLocked>());
    });

    test('PIN nuevo previsible o igual al actual', () async {
      expect(falloDe(await construir().changePin(current: pin, nuevo: '123456')),
          isA<SecurityWeakPin>());
      expect(falloDe(await construir().changePin(current: pin, nuevo: pin)),
          isA<SecurityPinUnchanged>());
    });

    test('lista con este teléfono primero', () async {
      final lista = valorDe(await construir().devices());
      expect(lista, hasLength(2));
      expect(lista.first.esEste, isTrue);
      expect(lista.last.id, otroId);
    });

    test('desvincular otro lo quita; dos veces es deviceNotFound', () async {
      final repo = construir();
      valorDe(await repo.unlinkDevice(otroId));
      expect(valorDe(await repo.devices()), hasLength(1));
      expect(falloDe(await repo.unlinkDevice(otroId)),
          isA<SecurityDeviceNotFound>());
    });

    test('desvincular este teléfono es cannotUnlinkCurrent', () async {
      final repo = construir();
      final este = valorDe(await repo.devices()).first.id;
      expect(falloDe(await repo.unlinkDevice(este)),
          isA<SecurityCannotUnlinkCurrent>());
    });

    test('activar la huella da un secreto y marca este teléfono', () async {
      final repo = construir();
      expect(valorDe(await repo.enrollBiometric(pin)), isNotEmpty);
      expect(valorDe(await repo.devices()).first.conHuella, isTrue);
      valorDe(await repo.revokeBiometric());
      expect(valorDe(await repo.devices()).first.conHuella, isFalse);
    });

    test('activar con PIN errado es wrongPin', () async {
      expect(falloDe(await construir().enrollBiometric('111222')),
          isA<SecurityWrongPin>());
    });
  });
}
```

`test/feature/security/memory_security_repository_test.dart`:

```dart
import 'package:cuycash/feature/security/infrastructure/memory_security_repository.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'security_repository_contract.dart';

void main() {
  probarContratoDeSeguridad(
    'MemorySecurityRepository',
    () => MemorySecurityRepository(
      MemorySecurityState.demo(clock: () => DateTime.utc(2026, 10, 6, 12)),
      clock: () => DateTime.utc(2026, 10, 6, 12),
    ),
    pin: '000000',
    otroId: MemorySecurityState.otroDispositivoId,
  );

  test('cambiar el PIN revoca la huella de los otros, no la de este', () async {
    final estado = MemorySecurityState.demo(clock: DateTime.now);
    final repo = MemorySecurityRepository(estado, clock: DateTime.now);
    final mia = (await repo.enrollBiometric('000000')).getRight().toNullable();
    estado.credentials['ajena'] = MemorySecurityState.otroDispositivoId;

    await repo.changePin(current: '000000', nuevo: '502718');

    expect(estado.credentials.keys, [mia]);
  });
}
```

`test/feature/security/http_security_repository_test.dart`: fake con estado que reproduce las rutas de las Tasks 3–5:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/security/domain/security_failure.dart';
import 'package:cuycash/feature/security/infrastructure/http_security_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'security_repository_contract.dart';

/// Reproduce `auth.py` (`pin/change`, `biometric/*`) y `profile.py`
/// (`/v1/devices*`): cuerpos de error PLANOS `{code, detail, <extras>}`.
class FakeSecurityBackend implements HttpClientAdapter {
  String pin = '839201';
  int intentos = 5;
  bool conHuella = false;
  final dispositivos = <Map<String, Object?>>[
    _disp('d-este', esEste: true),
    _disp('d-otro', esEste: false),
  ];
  ({int status, Object? body})? forced;
  DioException? throwIt;

  static Map<String, Object?> _disp(String id, {required bool esEste}) => {
        'id': id,
        'nombre': esEste ? 'Pixel 8' : null,
        'plataforma': esEste ? 'android' : null,
        'vinculado_el': '2026-09-01T15:00:00.000000Z',
        'ultimo_uso': '2026-10-06T12:00:00.000000Z',
        'es_este': esEste,
        'con_huella': false,
      };

  static (int, Object?) _err(int s, String code, [Map<String, Object?> x = const {}]) =>
      (s, {'code': code, 'detail': 'x', ...x});

  (int, Object?)? _verificar(String propuesto) {
    if (intentos <= 0) {
      return _err(423, 'IDENTIFIER_LOCKED',
          {'locked_until': '2026-10-06T12:15:00+00:00'});
    }
    if (propuesto == pin) return null;
    intentos--;
    if (intentos == 0) {
      return _err(423, 'IDENTIFIER_LOCKED',
          {'locked_until': '2026-10-06T12:15:00+00:00'});
    }
    return _err(401, 'INVALID_CREDENTIALS', {'attempts_left': intentos});
  }

  (int, Object?) _route(RequestOptions o) {
    final path = o.uri.path;
    final data = o.data is Map ? o.data as Map : const {};
    if (path == '/v1/auth/pin/change') {
      if (_verificar(data['current_pin'] as String) case final e?) return e;
      final nuevo = data['new_pin'] as String;
      if ({'123456', '111111', '654321'}.contains(nuevo)) {
        return _err(422, 'WEAK_PIN');
      }
      if (nuevo == pin) return _err(422, 'PIN_UNCHANGED');
      pin = nuevo;
      return (200, {'revoked_sessions': 1});
    }
    if (path == '/v1/devices' && o.method == 'GET') {
      return (200, {
        'dispositivos': [
          for (final d in dispositivos)
            {...d, 'con_huella': d['es_este'] == true && conHuella},
        ],
      });
    }
    if (path.startsWith('/v1/devices/') && o.method == 'DELETE') {
      final id = path.split('/').last;
      final i = dispositivos.indexWhere((d) => d['id'] == id);
      if (i < 0) return _err(404, 'DEVICE_NOT_FOUND');
      if (dispositivos[i]['es_este'] == true) {
        return _err(409, 'CANNOT_UNLINK_CURRENT');
      }
      dispositivos.removeAt(i);
      return (204, null);
    }
    if (path == '/v1/auth/biometric/enroll') {
      if (_verificar(data['pin'] as String) case final e?) return e;
      conHuella = true;
      return (200, {'credential': 'secreto-${DateTime.now().microsecond}'});
    }
    if (path == '/v1/auth/biometric/current' && o.method == 'DELETE') {
      conHuella = false;
      return (204, null);
    }
    return _err(404, 'NOPE');
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (throwIt case final e?) throw e;
    final (status, body) = switch (forced) {
      final f? => (f.status, f.body),
      _ => _route(o),
    };
    return ResponseBody.fromString(body == null ? '' : jsonEncode(body), status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
  }

  @override
  void close({bool force = false}) {}
}

HttpSecurityRepository construir([FakeSecurityBackend? backend]) =>
    HttpSecurityRepository(
      dio: Dio(BaseOptions(
        baseUrl: 'http://x',
        validateStatus: (s) => s != null && s < 500,
      ))
        ..httpClientAdapter = backend ?? FakeSecurityBackend(),
    );

void main() {
  probarContratoDeSeguridad(
    'HttpSecurityRepository',
    construir,
    pin: '839201',
    otroId: 'd-otro',
  );

  test('sin red al cambiar el PIN es network (resultado desconocido)',
      () async {
    final backend = FakeSecurityBackend()
      ..throwIt = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.receiveTimeout,
      );
    final r = await construir(backend)
        .changePin(current: '839201', nuevo: '502718');
    expect(
      switch (r.getLeft().toNullable()) {
        ServerFailure(:final failure) => failure,
        _ => null,
      },
      isA<SecurityNetworkFailure>(),
    );
  });
}
```

Añadir a `test/feature/device/memory_device_store_test.dart`:

```dart
  test('clearUser también borra la credencial biométrica', () async {
    final store = MemoryDeviceStore();
    expect(await store.saveBiometricCredential('s3cr3t'), isTrue);
    expect(await store.readBiometricCredential(), 's3cr3t');

    await store.clearUser();

    expect(await store.readBiometricCredential(), isNull);
  });
```

Añadir a `test/feature/auth/memory_auth_repository_test.dart`:

```dart
  test('signInWithBiometric acepta la credencial vigente de este teléfono',
      () async {
    final estado = MemorySecurityState.demo(clock: DateTime.now);
    estado.credentials['ok'] = estado.thisDeviceId;
    final repo = MemoryAuthRepository(security: estado);

    final bien = await repo.signInWithBiometric(dni: estado.dni, credential: 'ok');
    final mal = await repo.signInWithBiometric(dni: estado.dni, credential: 'x');

    expect(bien.isRight(), isTrue);
    expect(repo.currentSession?.identifier, estado.dni);
    expect(
      switch (mal.getLeft().toNullable()) {
        ServerFailure(:final failure) => failure,
        _ => null,
      },
      isA<BiometricRevoked>(),
    );
  });
```

Añadir a `test/feature/auth/http_auth_repository_test.dart`, siguiendo el fake que ese archivo ya usa (leerlo antes): un caso donde `POST /v1/auth/sessions/biometric` responde `{result: session, session_token: 't', user: {id: 'u', dni: '71234567', alias: '@j'}}` y `signInWithBiometric` emite la sesión y deja el token en el holder; y otro donde responde `401 {code: BIOMETRIC_REVOKED}` y devuelve `BiometricRevoked`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd apps/mobile && flutter test test/feature`
Expected: FAIL (imports y métodos inexistentes).

- [ ] **Step 3: Implement `PinRules`**

`lib/feature/auth/domain/pin_rules.dart`: mover aquí, sin cambiar su lógica, `hasSixDigits`, `hasNoRepeatedDigit`, `hasNoSequence` y `pinValid` (renombrado a `isValid`) desde `RegisterValidators` en `register_bloc.dart` (líneas 38–58), con sus comentarios. En `RegisterValidators`, cada método pasa a delegar:

```dart
  static bool hasSixDigits(String pin) => PinRules.hasSixDigits(pin);
  static bool hasNoRepeatedDigit(String pin) => PinRules.hasNoRepeatedDigit(pin);
  static bool hasNoSequence(String pin) => PinRules.hasNoSequence(pin);
  static bool pinValid(String pin) => PinRules.isValid(pin);
```

- [ ] **Step 4: Implement the security domain**

`lib/feature/security/domain/linked_device.dart`:

```dart
/// Un teléfono con acceso a la cuenta, tal como lo describe el servidor.
class LinkedDevice {
  const LinkedDevice({
    required this.id,
    required this.nombre,
    required this.plataforma,
    required this.vinculadoEl,
    required this.ultimoUso,
    required this.esEste,
    required this.conHuella,
  });

  final String id;

  /// Modelo que el teléfono declaró; `null` si nunca lo dijo.
  final String? nombre;

  /// `android` / `ios`; `null` si no se sabe.
  final String? plataforma;
  final DateTime vinculadoEl;
  final DateTime ultimoUso;
  final bool esEste;
  final bool conHuella;

  LinkedDevice copyWith({bool? conHuella}) => LinkedDevice(
        id: id,
        nombre: nombre,
        plataforma: plataforma,
        vinculadoEl: vinculadoEl,
        ultimoUso: ultimoUso,
        esEste: esEste,
        conHuella: conHuella ?? this.conHuella,
      );
}
```

`security_failure.dart`:

```dart
/// Failures de seguridad (viajan en `GlobalFailure.server`). Prefijo
/// `Security` porque los nombres genéricos ya existen en otras features.
sealed class SecurityFailure {
  const SecurityFailure();

  const factory SecurityFailure.wrongPin(int attemptsLeft) = SecurityWrongPin;
  const factory SecurityFailure.locked(DateTime until) = SecurityLocked;
  const factory SecurityFailure.weakPin() = SecurityWeakPin;
  const factory SecurityFailure.pinUnchanged() = SecurityPinUnchanged;
  const factory SecurityFailure.cannotUnlinkCurrent() =
      SecurityCannotUnlinkCurrent;
  const factory SecurityFailure.deviceNotFound() = SecurityDeviceNotFound;
  const factory SecurityFailure.biometricUnavailable() =
      SecurityBiometricUnavailable;
  const factory SecurityFailure.unauthenticated() = SecurityUnauthenticated;
  const factory SecurityFailure.network() = SecurityNetworkFailure;
  const factory SecurityFailure.unexpected() = SecurityUnexpectedFailure;
}

/// El PIN actual no es correcto; [attemptsLeft] lo cuenta el servidor.
final class SecurityWrongPin extends SecurityFailure {
  const SecurityWrongPin(this.attemptsLeft);
  final int attemptsLeft;
}

/// Se agotaron los intentos: bloqueado hasta [until] y la sesión cerrada.
final class SecurityLocked extends SecurityFailure {
  const SecurityLocked(this.until);
  final DateTime until;
}

final class SecurityWeakPin extends SecurityFailure {
  const SecurityWeakPin();
}

final class SecurityPinUnchanged extends SecurityFailure {
  const SecurityPinUnchanged();
}

/// Este teléfono no se desvincula desde la lista: para eso está cerrar sesión.
final class SecurityCannotUnlinkCurrent extends SecurityFailure {
  const SecurityCannotUnlinkCurrent();
}

/// Ya no estaba vinculado (otro teléfono lo sacó antes).
final class SecurityDeviceNotFound extends SecurityFailure {
  const SecurityDeviceNotFound();
}

/// Sin sensor o sin huellas registradas en el sistema.
final class SecurityBiometricUnavailable extends SecurityFailure {
  const SecurityBiometricUnavailable();
}

final class SecurityUnauthenticated extends SecurityFailure {
  const SecurityUnauthenticated();
}

/// Sin red o timeout. En `changePin` el resultado es DESCONOCIDO.
final class SecurityNetworkFailure extends SecurityFailure {
  const SecurityNetworkFailure();
}

final class SecurityUnexpectedFailure extends SecurityFailure {
  const SecurityUnexpectedFailure();
}
```

`security_repository.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import 'linked_device.dart';
import 'security_failure.dart';

/// Seguridad de la cuenta con sesión abierta. Nunca lanza.
abstract interface class SecurityRepository {
  /// Devuelve cuántas sesiones de OTROS teléfonos se cerraron.
  FutureResult<SecurityFailure, int> changePin({
    required String current,
    required String nuevo,
  });

  FutureResult<SecurityFailure, List<LinkedDevice>> devices();

  FutureResult<SecurityFailure, Unit> unlinkDevice(String id);

  /// El secreto que la huella liberará; el servidor solo guarda su hash.
  FutureResult<SecurityFailure, String> enrollBiometric(String pin);

  FutureResult<SecurityFailure, Unit> revokeBiometric();
}
```

`lib/feature/security/application/security_actions.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/linked_device.dart';
import '../domain/security_failure.dart';
import '../domain/security_repository.dart';

/// Operaciones finas de seguridad. Lo que orquesta más de una dependencia
/// (huella + repo + almacén) vive en su `*_use_case.dart`.
class SecurityActions {
  const SecurityActions(this._repo);

  final SecurityRepository _repo;

  FutureResult<SecurityFailure, int> changePin({
    required String current,
    required String nuevo,
  }) =>
      _repo.changePin(current: current, nuevo: nuevo);

  FutureResult<SecurityFailure, List<LinkedDevice>> devices() =>
      _repo.devices();

  FutureResult<SecurityFailure, Unit> unlinkDevice(String id) =>
      _repo.unlinkDevice(id);

  FutureResult<SecurityFailure, String> enrollBiometric(String pin) =>
      _repo.enrollBiometric(pin);

  FutureResult<SecurityFailure, Unit> revokeBiometric() =>
      _repo.revokeBiometric();
}
```

- [ ] **Step 5: Implement the memory side**

`memory_security_state.dart`:

```dart
import '../domain/linked_device.dart';

/// "Servidor" en memoria compartido por `MemoryAuthRepository` y
/// `MemorySecurityRepository` (como `MemoryLedger` para cuentas): cambiar el
/// PIN aquí cambia el PIN con el que entra el login, y una credencial
/// emitida aquí es la que acepta `signInWithBiometric`.
class MemorySecurityState {
  MemorySecurityState({
    required this.pin,
    required this.dni,
    required this.thisDeviceId,
    required List<LinkedDevice> devices,
  }) : devices = [...devices];

  static const otroDispositivoId = 'mem-otro';
  static const maxAttempts = 5;

  factory MemorySecurityState.demo({
    required DateTime Function() clock,
    String pin = '000000',
  }) {
    final ahora = clock().toUtc();
    return MemorySecurityState(
      pin: pin,
      dni: '70123456',
      thisDeviceId: 'mem-este',
      devices: [
        LinkedDevice(
          id: 'mem-este',
          nombre: 'Este teléfono (demo)',
          plataforma: 'android',
          vinculadoEl: ahora.subtract(const Duration(days: 30)),
          ultimoUso: ahora,
          esEste: true,
          conHuella: false,
        ),
        LinkedDevice(
          id: otroDispositivoId,
          nombre: 'iPhone14,5',
          plataforma: 'ios',
          vinculadoEl: ahora.subtract(const Duration(days: 10)),
          ultimoUso: ahora.subtract(const Duration(days: 2)),
          esEste: false,
          conHuella: false,
        ),
      ],
    );
  }

  String pin;
  final String dni;
  final String thisDeviceId;
  final List<LinkedDevice> devices;

  /// Secreto vigente → id del dispositivo que lo tiene.
  final Map<String, String> credentials = {};
  int attemptsLeft = maxAttempts;
  DateTime? lockedUntil;
}
```

`memory_security_repository.dart`:

```dart
import 'dart:math';

import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../../auth/domain/pin_rules.dart';
import '../domain/linked_device.dart';
import '../domain/security_failure.dart';
import '../domain/security_repository.dart';
import 'memory_security_state.dart';

/// Impl en memoria (flavor `mock`). Mismas reglas que `services/api`: el PIN
/// errado descuenta intentos y al quinto bloquea 15 min; cambiar el PIN
/// revoca las huellas de los otros teléfonos.
class MemorySecurityRepository implements SecurityRepository {
  MemorySecurityRepository(this._s, {required DateTime Function() clock})
      : _clock = clock;

  final MemorySecurityState _s;
  final DateTime Function() _clock;

  static const _bloqueo = Duration(minutes: 15);

  GlobalFailure<SecurityFailure>? _verificar(String pin) {
    final hasta = _s.lockedUntil;
    if (hasta != null && _clock().isBefore(hasta)) {
      return GlobalFailure.server(SecurityFailure.locked(hasta));
    }
    if (pin == _s.pin) {
      _s.attemptsLeft = MemorySecurityState.maxAttempts;
      return null;
    }
    _s.attemptsLeft--;
    if (_s.attemptsLeft <= 0) {
      final nuevo = _clock().add(_bloqueo);
      _s.lockedUntil = nuevo;
      _s.attemptsLeft = MemorySecurityState.maxAttempts;
      return GlobalFailure.server(SecurityFailure.locked(nuevo));
    }
    return GlobalFailure.server(SecurityFailure.wrongPin(_s.attemptsLeft));
  }

  @override
  FutureResult<SecurityFailure, int> changePin({
    required String current,
    required String nuevo,
  }) async {
    if (_verificar(current) case final f?) return left(f);
    if (!PinRules.isValid(nuevo)) {
      return left(const GlobalFailure.server(SecurityFailure.weakPin()));
    }
    if (nuevo == _s.pin) {
      return left(const GlobalFailure.server(SecurityFailure.pinUnchanged()));
    }
    _s.pin = nuevo;
    _s.credentials.removeWhere((_, device) => device != _s.thisDeviceId);
    return right(_s.devices.where((d) => !d.esEste).length);
  }

  @override
  FutureResult<SecurityFailure, List<LinkedDevice>> devices() async {
    final conHuella = _s.credentials.values.toSet();
    return right([
      for (final d in _s.devices) d.copyWith(conHuella: conHuella.contains(d.id)),
    ]);
  }

  @override
  FutureResult<SecurityFailure, Unit> unlinkDevice(String id) async {
    final i = _s.devices.indexWhere((d) => d.id == id);
    if (i < 0) {
      return left(const GlobalFailure.server(SecurityFailure.deviceNotFound()));
    }
    if (_s.devices[i].esEste) {
      return left(
          const GlobalFailure.server(SecurityFailure.cannotUnlinkCurrent()));
    }
    _s.devices.removeAt(i);
    _s.credentials.removeWhere((_, device) => device == id);
    return right(unit);
  }

  @override
  FutureResult<SecurityFailure, String> enrollBiometric(String pin) async {
    if (_verificar(pin) case final f?) return left(f);
    _s.credentials.removeWhere((_, device) => device == _s.thisDeviceId);
    final random = Random.secure();
    final secreto = List.generate(32, (_) => random.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    _s.credentials[secreto] = _s.thisDeviceId;
    return right(secreto);
  }

  @override
  FutureResult<SecurityFailure, Unit> revokeBiometric() async {
    _s.credentials.removeWhere((_, device) => device == _s.thisDeviceId);
    return right(unit);
  }
}
```

`MemoryAuthRepository`: añadir el parámetro `MemorySecurityState? security` al constructor; el PIN pasa a vivir en el estado compartido:

```dart
  MemoryAuthRepository({
    AuthSession? initial,
    String validPin = '000000',
    List<String> otherDeviceTokens = const [],
    MemorySecurityState? security,
  })  : _session = initial,
        _security = security ??
            MemorySecurityState.demo(clock: DateTime.now, pin: validPin),
        _otherDeviceTokens = [...otherDeviceTokens] {
    if (initial != null) _registered.add(initial.identifier);
  }

  final MemorySecurityState _security;

  /// PIN aceptado por `signIn`. Cambia con `resetPin` y con el cambio de PIN
  /// del perfil (estado compartido).
  String get validPin => _security.pin;
```

Reemplazar en el archivo cada uso de `_validPin` por `_security.pin` (lectura y escritura en `resetPin`) y borrar el campo `_validPin`. Añadir:

```dart
  @override
  FutureResult<AuthFailure, AuthSession> signInWithBiometric({
    required String dni,
    required String credential,
  }) async {
    final device = _security.credentials[credential];
    if (device != _security.thisDeviceId || dni != _security.dni) {
      return left(const GlobalFailure.server(AuthFailure.biometricRevoked()));
    }
    final session = AuthSession(userId: 'mem-${dni.hashCode}', identifier: dni);
    _emit(session);
    return right(session);
  }
```

- [ ] **Step 6: Implement the auth and device changes**

`auth_failure.dart`: factory `const factory AuthFailure.biometricRevoked() = BiometricRevoked;` y la clase:

```dart
/// La credencial biométrica ya no vale (revocada, de otro teléfono, o el
/// dispositivo se desvinculó). Se borra del teléfono y se entra con PIN.
final class BiometricRevoked extends AuthFailure {
  const BiometricRevoked();
}
```

Buscar con `grep -rn "switch (.*AuthFailure\|case .*AuthUnavailable\|AuthUnavailable()" apps/mobile/lib` los `switch` exhaustivos sobre `AuthFailure` y añadir el caso `BiometricRevoked()` con el mismo texto que el `default` o `AuthUnavailable` de cada uno (el compilador los señala en `flutter analyze`).

`auth_repository.dart`, antes de `signOut`:

```dart
  /// Abre sesión con la credencial que la huella liberó. No suma intentos al
  /// bloqueo en el servidor, pero sí lo respeta (`accessLocked`).
  FutureResult<AuthFailure, AuthSession> signInWithBiometric({
    required String dni,
    required String credential,
  });
```

`auth_actions.dart`: delegación `signInWithBiometric`.

`http_auth_repository.dart`:

```dart
  @override
  FutureResult<AuthFailure, AuthSession> signInWithBiometric({
    required String dni,
    required String credential,
  }) =>
      _guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/v1/auth/sessions/biometric',
          data: {'dni': dni, 'credential': credential},
        );
        final failure = _failureFor(response);
        if (failure != null) return left(GlobalFailure.server(failure));

        final data = response.data ?? const {};
        final user = data['user'] as Map? ?? const {};
        _tokenHolder.token = data['session_token'] as String?;
        final session = AuthSession(
          userId: user['id'] as String? ?? '',
          identifier: dni,
          alias: user['alias'] as String?,
        );
        _emit(session);
        return right(session);
      });
```

Y en `_failureFor`, antes de `_ =>`: `'BIOMETRIC_REVOKED' => const AuthFailure.biometricRevoked(),`.

`device_store.dart`:

```dart
  /// Credencial biométrica de ESTE teléfono para el usuario recordado.
  Future<String?> readBiometricCredential();

  /// `false` si no se pudo escribir: quien activó la huella debe revocarla en
  /// el servidor para no dejar una credencial huérfana.
  Future<bool> saveBiometricCredential(String credential);

  Future<void> clearBiometricCredential();
```

y documentar en `clearUser` que también borra la credencial.

`secure_device_store.dart`:

```dart
  static const _biometricKey = 'cuycash.biometric_credential';

  @override
  Future<void> clearUser() async {
    await _storage.delete(key: _userKey);
    // Otro usuario en este teléfono no hereda la huella del anterior.
    await _storage.delete(key: _biometricKey);
  }

  @override
  Future<String?> readBiometricCredential() => _storage.read(key: _biometricKey);

  @override
  Future<bool> saveBiometricCredential(String credential) async {
    try {
      await _storage.write(key: _biometricKey, value: credential);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> clearBiometricCredential() => _storage.delete(key: _biometricKey);
```

`memory_device_store.dart`: campo `String? _credential;` y `bool failCredentialWrites = false;` (para simular disco que no escribe en tests); implementar los tres métodos; `clearUser` hace `_user = null; _credential = null;`; `saveBiometricCredential` devuelve `false` sin guardar si `failCredentialWrites`.

`device_actions.dart`: delegaciones `readBiometricCredential`, `saveBiometricCredential`, `clearBiometricCredential`.

- [ ] **Step 7: Implement HTTP security repo**

`http_security_repository.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/linked_device.dart';
import '../domain/security_failure.dart';
import '../domain/security_repository.dart';

/// Impl real contra `services/api`: `/v1/auth/pin/change`,
/// `/v1/auth/biometric/*`, `/v1/devices*`. [dio] de `buildAuthenticatedDio`.
///
/// Un 401 `INVALID_CREDENTIALS` aquí es "PIN actual errado", no sesión
/// vencida: el interceptor solo cierra sesión ante `UNAUTHENTICATED` o sin
/// `code`.
class HttpSecurityRepository implements SecurityRepository {
  HttpSecurityRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  FutureResult<SecurityFailure, int> changePin({
    required String current,
    required String nuevo,
  }) =>
      _guard(() async {
        final response = await _dio.post<dynamic>('/v1/auth/pin/change',
            data: {'current_pin': current, 'new_pin': nuevo});
        if (_failureFor(response) case final f?) {
          return left(GlobalFailure.server(f));
        }
        return right(_cuerpo(response)['revoked_sessions'] as int);
      });

  @override
  FutureResult<SecurityFailure, List<LinkedDevice>> devices() =>
      _guard(() async {
        final response = await _dio.get<dynamic>('/v1/devices');
        if (_failureFor(response) case final f?) {
          return left(GlobalFailure.server(f));
        }
        return right([
          for (final d in _cuerpo(response)['dispositivos'] as List)
            _device(d as Map<String, dynamic>),
        ]);
      });

  @override
  FutureResult<SecurityFailure, Unit> unlinkDevice(String id) =>
      _guard(() async {
        final response = await _dio
            .delete<dynamic>('/v1/devices/${Uri.encodeComponent(id)}');
        if (_failureFor(response) case final f?) {
          return left(GlobalFailure.server(f));
        }
        return right(unit);
      });

  @override
  FutureResult<SecurityFailure, String> enrollBiometric(String pin) =>
      _guard(() async {
        final response = await _dio
            .post<dynamic>('/v1/auth/biometric/enroll', data: {'pin': pin});
        if (_failureFor(response) case final f?) {
          return left(GlobalFailure.server(f));
        }
        return right(_cuerpo(response)['credential'] as String);
      });

  @override
  FutureResult<SecurityFailure, Unit> revokeBiometric() => _guard(() async {
        final response = await _dio.delete<dynamic>('/v1/auth/biometric/current');
        if (_failureFor(response) case final f?) {
          return left(GlobalFailure.server(f));
        }
        return right(unit);
      });

  LinkedDevice _device(Map<String, dynamic> j) => LinkedDevice(
        id: j['id'] as String,
        nombre: j['nombre'] as String?,
        plataforma: j['plataforma'] as String?,
        vinculadoEl: DateTime.parse(j['vinculado_el'] as String).toUtc(),
        ultimoUso: DateTime.parse(j['ultimo_uso'] as String).toUtc(),
        esEste: j['es_este'] as bool,
        conHuella: j['con_huella'] as bool,
      );

  Map<String, dynamic> _cuerpo(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Cuerpo que no es un objeto JSON');
  }

  SecurityFailure? _failureFor(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) return null;
    final data = response.data;
    final body = data is Map ? data : const <Object?, Object?>{};
    return switch (body['code']) {
      'INVALID_CREDENTIALS' => switch (body['attempts_left']) {
          final int n => SecurityFailure.wrongPin(n),
          _ => const SecurityFailure.wrongPin(0),
        },
      'IDENTIFIER_LOCKED' || 'DEVICE_LOCKED' =>
        switch (DateTime.tryParse('${body['locked_until']}')) {
          final DateTime until => SecurityFailure.locked(until),
          _ => const SecurityFailure.unexpected(),
        },
      'WEAK_PIN' => const SecurityFailure.weakPin(),
      'PIN_UNCHANGED' => const SecurityFailure.pinUnchanged(),
      'CANNOT_UNLINK_CURRENT' => const SecurityFailure.cannotUnlinkCurrent(),
      'DEVICE_NOT_FOUND' => const SecurityFailure.deviceNotFound(),
      'UNAUTHENTICATED' => const SecurityFailure.unauthenticated(),
      _ when status == 401 => const SecurityFailure.unauthenticated(),
      _ => const SecurityFailure.unexpected(),
    };
  }

  Future<Either<GlobalFailure<SecurityFailure>, T>> _guard<T>(
    Future<Either<GlobalFailure<SecurityFailure>, T>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      return left(GlobalFailure.server(switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError => const SecurityFailure.network(),
        _ => const SecurityFailure.unexpected(),
      }));
    } catch (error, stackTrace) {
      return left(GlobalFailure.unexpected(error, stackTrace));
    }
  }
}
```

- [ ] **Step 8: Wire dependencies**

`app_dependencies.dart`: `required this.securityRepository,` y

```dart
  /// Cambio de PIN, dispositivos y huella. Los blocs consumen
  /// [securityActions] o los use cases de `feature/security/application`.
  final SecurityRepository securityRepository;
  SecurityActions get securityActions => SecurityActions(securityRepository);
```

`mock_dependencies.dart`: antes del `return`, `final security = MemorySecurityState.demo(clock: DateTime.now);`; `authRepository: MemoryAuthRepository(security: security),`; `securityRepository: MemorySecurityRepository(security, clock: DateTime.now),`.

`shared_backend_dependencies.dart`: `securityRepository: HttpSecurityRepository(dio: dio),`.

`modules/security_module.dart`:

```dart
import '../../../feature/security/application/security_actions.dart';
import '../app_dependencies.dart';

/// Wiring de seguridad: los blocs reciben las acciones, nunca el repositorio.
abstract final class SecurityModule {
  static SecurityActions create(AppDependencies deps) => deps.securityActions;
}
```

Añadir `securityRepository: MemorySecurityRepository(MemorySecurityState.demo(clock: DateTime.now), clock: DateTime.now),` en cada test que construye `AppDependencies` a mano.

- [ ] **Step 9: Run tests and analyze**

Run: `cd apps/mobile && flutter test && cd ../.. && flutter analyze`
Expected: PASS, `No issues found!`.

- [ ] **Step 10: Commit**

```bash
git add apps/mobile/lib apps/mobile/test
git commit -m "feat(app): feature security, sesión con huella y credencial en el teléfono"
```

---

### Task 11: App — cambiar el PIN (tres pasos)

**Files:**
- Create: `apps/mobile/lib/presentation/profile/change_pin/bloc/change_pin_bloc.dart` (+ `_event`, `_state`, `.freezed`), `change_pin_screen.dart`
- Modify: `router.dart`, `profile_screen.dart`, `app_es.arb`
- Test: `apps/mobile/test/presentation/profile/change_pin_bloc_test.dart`, `change_pin_screen_test.dart`

**Interfaces:**
- Consumes: `SecurityActions.changePin`, `PinRules`, `PinEntryView`, `PinRule`.
- Produces:
  - `ChangePinBloc(SecurityActions)`; eventos `digitPressed(int)`, `backspace()`, `back()`.
  - Estado: `{step: actual|nuevo|confirmar, pin, currentPin, newPin, status: idle|submitting|done, error: ChangePinError?, attemptsLeft: int?, lockedUntil: DateTime?, revokedSessions: int}`; `enum ChangePinError { wrongPin, weakPin, samePin, mismatch, unknownOutcome, generic }`.
  - `ChangePinScreen({required void Function(DateTime until) onLocked})`.

Flujo del bloc:
- `actual`: al sexto dígito guarda `currentPin` y pasa a `nuevo` (sin llamar al servidor).
- `nuevo`: al sexto dígito, si `!PinRules.isValid` → `weakPin` y limpia; si es igual a `currentPin` → `samePin` y limpia; si no, guarda `newPin` y pasa a `confirmar`.
- `confirmar`: si no coincide → `mismatch`, vuelve a `nuevo` con `newPin` vacío. Si coincide → `submitting` y `changePin`.
  - `SecurityWrongPin(n)` → `step: actual`, todo limpio, `error: wrongPin`, `attemptsLeft: n`.
  - `SecurityLocked(until)` → `lockedUntil: until` (la pantalla llama `onLocked`).
  - `SecurityWeakPin` → `step: nuevo`, `weakPin`. `SecurityPinUnchanged` → `step: nuevo`, `samePin`.
  - `SecurityNetworkFailure` → `status: idle`, `error: unknownOutcome`, se queda en `confirmar` con el PIN vacío y **no** reintenta.
  - Otro → `generic`, se queda en `confirmar`.
  - Éxito → `status: done`, `revokedSessions: n`.
- `back`: `confirmar` → `nuevo`; `nuevo` → `actual`; `actual` no hace nada (la pantalla hace `pop`). Ignorado mientras `submitting`.

- [ ] **Step 1: ARB**

```json
  "changePinTitle": "Cambiar mi PIN",
  "changePinCurrentHeadline": "Ingresa tu PIN actual",
  "changePinCurrentSubtitle": "Lo usamos para confirmar que eres tú.",
  "changePinNewHeadline": "Crea tu nuevo PIN",
  "changePinNewSubtitle": "Elige 6 dígitos que no uses en otro lado.",
  "changePinConfirmHeadline": "Confirma tu nuevo PIN",
  "changePinConfirmSubtitle": "Escríbelo otra vez.",
  "changePinWrong": "{count, plural, =1{PIN actual incorrecto. Te queda 1 intento.} other{PIN actual incorrecto. Te quedan {count} intentos.}}",
  "@changePinWrong": {"placeholders": {"count": {"type": "int"}}},
  "changePinUnknown": "No sabemos si tu PIN cambió. Intenta entrar con el nuevo o con el anterior.",
  "changePinDoneTitle": "Tu PIN cambió",
  "changePinDoneOthers": "{count, plural, =0{Desde ahora entra con tu nuevo PIN.} =1{Cerramos tu sesión en 1 dispositivo.} other{Cerramos tu sesión en {count} dispositivos.}}",
  "@changePinDoneOthers": {"placeholders": {"count": {"type": "int"}}},
  "changePinDoneCta": "Listo",
```

Run: `cd apps/mobile && flutter gen-l10n`

- [ ] **Step 2: Write the failing bloc test**

`test/presentation/profile/change_pin_bloc_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/security/application/security_actions.dart';
import 'package:cuycash/feature/security/domain/linked_device.dart';
import 'package:cuycash/feature/security/domain/security_failure.dart';
import 'package:cuycash/feature/security/domain/security_repository.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_repository.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_state.dart';
import 'package:cuycash/presentation/profile/change_pin/bloc/change_pin_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _SinRed implements SecurityRepository {
  int llamadas = 0;

  @override
  FutureResult<SecurityFailure, int> changePin({
    required String current,
    required String nuevo,
  }) async {
    llamadas++;
    return left(const GlobalFailure.server(SecurityFailure.network()));
  }

  @override
  FutureResult<SecurityFailure, List<LinkedDevice>> devices() async => right([]);
  @override
  FutureResult<SecurityFailure, Unit> unlinkDevice(String id) async => right(unit);
  @override
  FutureResult<SecurityFailure, String> enrollBiometric(String pin) async =>
      right('x');
  @override
  FutureResult<SecurityFailure, Unit> revokeBiometric() async => right(unit);
}

ChangePinBloc _bloc([SecurityRepository? repo]) => ChangePinBloc(
      SecurityActions(repo ??
          MemorySecurityRepository(
            MemorySecurityState.demo(clock: DateTime.now),
            clock: DateTime.now,
          )),
    );

void _teclear(ChangePinBloc b, String pin) {
  for (final d in pin.split('')) {
    b.add(ChangePinEvent.digitPressed(int.parse(d)));
  }
}

void main() {
  blocTest<ChangePinBloc, ChangePinState>(
    'tres pasos y éxito',
    build: _bloc,
    act: (b) {
      _teclear(b, '000000');
      _teclear(b, '502718');
      _teclear(b, '502718');
    },
    wait: const Duration(milliseconds: 10),
    verify: (b) {
      expect(b.state.status, ChangePinStatus.done);
      expect(b.state.revokedSessions, 1);
    },
  );

  blocTest<ChangePinBloc, ChangePinState>(
    'un PIN nuevo previsible no avanza a confirmar',
    build: _bloc,
    act: (b) {
      _teclear(b, '000000');
      _teclear(b, '123456');
    },
    verify: (b) {
      expect(b.state.step, ChangePinStep.nuevo);
      expect(b.state.error, ChangePinError.weakPin);
      expect(b.state.pin, isEmpty);
    },
  );

  blocTest<ChangePinBloc, ChangePinState>(
    'el nuevo igual al actual se rechaza sin preguntar al servidor',
    build: _bloc,
    act: (b) {
      _teclear(b, '502718');
      _teclear(b, '502718');
    },
    verify: (b) => expect(b.state.error, ChangePinError.samePin),
  );

  blocTest<ChangePinBloc, ChangePinState>(
    'confirmación distinta vuelve a elegir el nuevo',
    build: _bloc,
    act: (b) {
      _teclear(b, '000000');
      _teclear(b, '502718');
      _teclear(b, '502719');
    },
    verify: (b) {
      expect(b.state.step, ChangePinStep.nuevo);
      expect(b.state.error, ChangePinError.mismatch);
    },
  );

  blocTest<ChangePinBloc, ChangePinState>(
    'PIN actual errado vuelve al paso 1 con los intentos',
    build: _bloc,
    act: (b) {
      _teclear(b, '111222');
      _teclear(b, '502718');
      _teclear(b, '502718');
    },
    wait: const Duration(milliseconds: 10),
    verify: (b) {
      expect(b.state.step, ChangePinStep.actual);
      expect(b.state.error, ChangePinError.wrongPin);
      expect(b.state.attemptsLeft, 4);
      expect(b.state.currentPin, isEmpty);
    },
  );

  test('sin red: resultado desconocido y UNA sola llamada', () async {
    final repo = _SinRed();
    final b = _bloc(repo);
    _teclear(b, '000000');
    _teclear(b, '502718');
    _teclear(b, '502718');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(b.state.error, ChangePinError.unknownOutcome);
    expect(b.state.status, ChangePinStatus.idle);
    expect(repo.llamadas, 1);
    await b.close();
  });

  test('al quinto PIN actual errado expone lockedUntil', () async {
    final b = _bloc();
    for (var i = 0; i < 5; i++) {
      _teclear(b, '111222');
      _teclear(b, '502718');
      _teclear(b, '502718');
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(b.state.lockedUntil, isNotNull);
    await b.close();
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd apps/mobile && flutter test test/presentation/profile/change_pin_bloc_test.dart`
Expected: FAIL.

- [ ] **Step 4: Implement bloc**

`change_pin_event.dart`:

```dart
part of 'change_pin_bloc.dart';

@freezed
sealed class ChangePinEvent with _$ChangePinEvent {
  const factory ChangePinEvent.digitPressed(int digit) = ChangePinDigitPressed;
  const factory ChangePinEvent.backspace() = ChangePinBackspace;
  const factory ChangePinEvent.back() = ChangePinBack;
}
```

`change_pin_state.dart`:

```dart
part of 'change_pin_bloc.dart';

enum ChangePinStep { actual, nuevo, confirmar }

enum ChangePinStatus { idle, submitting, done }

enum ChangePinError { wrongPin, weakPin, samePin, mismatch, unknownOutcome, generic }

@freezed
abstract class ChangePinState with _$ChangePinState {
  const factory ChangePinState({
    @Default(ChangePinStep.actual) ChangePinStep step,

    /// Dígitos del paso activo: lo único que pintan las casillas.
    @Default('') String pin,
    @Default('') String currentPin,
    @Default('') String newPin,
    @Default(ChangePinStatus.idle) ChangePinStatus status,
    ChangePinError? error,
    int? attemptsLeft,
    DateTime? lockedUntil,
    @Default(0) int revokedSessions,
  }) = _ChangePinState;
}
```

`change_pin_bloc.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../feature/auth/domain/pin_rules.dart';
import '../../../../feature/security/application/security_actions.dart';
import '../../../../feature/security/domain/security_failure.dart';

part 'change_pin_bloc.freezed.dart';
part 'change_pin_event.dart';
part 'change_pin_state.dart';

/// Cambiar el PIN con sesión abierta: actual → nuevo → confirmar, sobre la
/// misma ruta y sin botón (el sexto dígito avanza), como `ResetPinBloc`.
///
/// El PIN actual se verifica en el servidor AL FINAL, en la misma llamada que
/// fija el nuevo: un endpoint que solo verifique sería un oráculo.
///
/// Sin red el resultado es DESCONOCIDO: no se reintenta solo, porque si el
/// cambio sí ocurrió, reintentar con el PIN "actual" viejo fallaría y sumaría
/// un intento al bloqueo.
class ChangePinBloc extends Bloc<ChangePinEvent, ChangePinState> {
  ChangePinBloc(this._actions) : super(const ChangePinState()) {
    on<ChangePinDigitPressed>(_onDigit);
    on<ChangePinBackspace>((event, emit) {
      if (state.status != ChangePinStatus.idle || state.pin.isEmpty) return;
      emit(state.copyWith(
          pin: state.pin.substring(0, state.pin.length - 1), error: null));
    });
    on<ChangePinBack>(_onBack);
  }

  final SecurityActions _actions;

  Future<void> _onDigit(
    ChangePinDigitPressed event,
    Emitter<ChangePinState> emit,
  ) async {
    if (state.status != ChangePinStatus.idle || state.pin.length >= 6) return;
    final pin = '${state.pin}${event.digit}';
    emit(state.copyWith(pin: pin, error: null));
    if (pin.length < 6) return;

    switch (state.step) {
      case ChangePinStep.actual:
        emit(state.copyWith(
            step: ChangePinStep.nuevo, currentPin: pin, pin: ''));
      case ChangePinStep.nuevo:
        if (!PinRules.isValid(pin)) {
          emit(state.copyWith(pin: '', error: ChangePinError.weakPin));
        } else if (pin == state.currentPin) {
          emit(state.copyWith(pin: '', error: ChangePinError.samePin));
        } else {
          emit(state.copyWith(
              step: ChangePinStep.confirmar, newPin: pin, pin: ''));
        }
      case ChangePinStep.confirmar:
        await _confirm(pin, emit);
    }
  }

  Future<void> _confirm(String pin, Emitter<ChangePinState> emit) async {
    if (pin != state.newPin) {
      emit(state.copyWith(
        step: ChangePinStep.nuevo,
        pin: '',
        newPin: '',
        error: ChangePinError.mismatch,
      ));
      return;
    }
    emit(state.copyWith(status: ChangePinStatus.submitting));
    final result =
        await _actions.changePin(current: state.currentPin, nuevo: pin);
    emit(result.match(
      (failure) => switch (failure) {
        ServerFailure(failure: SecurityWrongPin(:final attemptsLeft)) =>
          ChangePinState(
            error: ChangePinError.wrongPin,
            attemptsLeft: attemptsLeft,
          ),
        ServerFailure(failure: SecurityLocked(:final until)) =>
          state.copyWith(status: ChangePinStatus.idle, pin: '', lockedUntil: until),
        ServerFailure(failure: SecurityWeakPin()) => state.copyWith(
            status: ChangePinStatus.idle,
            step: ChangePinStep.nuevo,
            pin: '',
            newPin: '',
            error: ChangePinError.weakPin,
          ),
        ServerFailure(failure: SecurityPinUnchanged()) => state.copyWith(
            status: ChangePinStatus.idle,
            step: ChangePinStep.nuevo,
            pin: '',
            newPin: '',
            error: ChangePinError.samePin,
          ),
        ServerFailure(failure: SecurityNetworkFailure()) => state.copyWith(
            status: ChangePinStatus.idle,
            pin: '',
            error: ChangePinError.unknownOutcome,
          ),
        _ => state.copyWith(
            status: ChangePinStatus.idle,
            pin: '',
            error: ChangePinError.generic,
          ),
      },
      (revocadas) => state.copyWith(
        status: ChangePinStatus.done,
        revokedSessions: revocadas,
      ),
    ));
  }

  void _onBack(ChangePinBack event, Emitter<ChangePinState> emit) {
    if (state.status != ChangePinStatus.idle) return;
    switch (state.step) {
      case ChangePinStep.actual:
        return;
      case ChangePinStep.nuevo:
        emit(const ChangePinState());
      case ChangePinStep.confirmar:
        emit(state.copyWith(
            step: ChangePinStep.nuevo, pin: '', newPin: '', error: null));
    }
  }
}
```

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Write the failing screen test**

`test/presentation/profile/change_pin_screen_test.dart`:

```dart
import 'package:cuycash/feature/security/application/security_actions.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_repository.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_state.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/profile/change_pin/bloc/change_pin_bloc.dart';
import 'package:cuycash/presentation/profile/change_pin/change_pin_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime? bloqueo;

  Future<void> abrir(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    bloqueo = null;
    await tester.pumpWidget(MaterialApp(
      theme: CuyCashTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider(
        create: (_) => ChangePinBloc(SecurityActions(MemorySecurityRepository(
          MemorySecurityState.demo(clock: DateTime.now),
          clock: DateTime.now,
        ))),
        child: ChangePinScreen(onLocked: (until) => bloqueo = until),
      ),
    ));
  }

  Future<void> teclear(WidgetTester tester, String pin) async {
    for (final d in pin.split('')) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('recorre los tres pasos y muestra la constancia',
      (tester) async {
    await abrir(tester);
    expect(find.text('Ingresa tu PIN actual'), findsOneWidget);

    await teclear(tester, '000000');
    expect(find.text('Crea tu nuevo PIN'), findsOneWidget);
    expect(find.text('Sin secuencias como 123456'), findsOneWidget);

    await teclear(tester, '502718');
    expect(find.text('Confirma tu nuevo PIN'), findsOneWidget);

    await teclear(tester, '502718');
    expect(find.text('Tu PIN cambió'), findsOneWidget);
    expect(find.text('Cerramos tu sesión en 1 dispositivo.'), findsOneWidget);
  });

  testWidgets('la flecha retrocede un paso', (tester) async {
    await abrir(tester);
    await teclear(tester, '000000');
    await teclear(tester, '502718');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Crea tu nuevo PIN'), findsOneWidget);
  });

  testWidgets('PIN actual errado avisa los intentos', (tester) async {
    await abrir(tester);
    await teclear(tester, '111222');
    await teclear(tester, '502718');
    await teclear(tester, '502718');

    expect(find.text('Ingresa tu PIN actual'), findsOneWidget);
    expect(find.text('PIN actual incorrecto. Te quedan 4 intentos.'),
        findsOneWidget);
  });

  testWidgets('al bloquear avisa a quien abrió la pantalla', (tester) async {
    await abrir(tester);
    for (var i = 0; i < 5; i++) {
      await teclear(tester, '111222');
      await teclear(tester, '502718');
      await teclear(tester, '502718');
    }
    expect(bloqueo, isNotNull);
  });
}
```

- [ ] **Step 6: Implement screen**

`change_pin_screen.dart`:

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/secure_screen_scope.dart';
import '../../../feature/auth/domain/pin_rules.dart';
import '../../../l10n/app_localizations.dart';
import '../../pin/pin_entry_view.dart';
import 'bloc/change_pin_bloc.dart';

/// Cambiar el PIN: tres pasos sobre la misma ruta, con la mecánica de
/// `RestablecerPinScreen` (`PinEntryView`, sexto dígito = avanzar).
///
/// [onLocked] lo provee el router: cerrar la sesión y llevar a `/bloqueado`
/// no es asunto de esta pantalla.
class ChangePinScreen extends StatelessWidget {
  const ChangePinScreen({required this.onLocked, super.key});

  final void Function(DateTime until) onLocked;

  String? _errorText(AppLocalizations l10n, ChangePinState s) =>
      switch (s.error) {
        ChangePinError.wrongPin => l10n.changePinWrong(s.attemptsLeft ?? 0),
        ChangePinError.weakPin => l10n.errorWeakPin,
        ChangePinError.samePin => l10n.resetPinSamePin,
        ChangePinError.mismatch => l10n.resetPinMismatch,
        ChangePinError.unknownOutcome => l10n.changePinUnknown,
        ChangePinError.generic => l10n.errorGeneric,
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SecureScreenScope(
      child: BlocConsumer<ChangePinBloc, ChangePinState>(
        listenWhen: (p, c) => p.lockedUntil != c.lockedUntil,
        listener: (context, state) {
          if (state.lockedUntil case final until?) onLocked(until);
        },
        builder: (context, state) {
          final bloc = context.read<ChangePinBloc>();
          if (state.status == ChangePinStatus.done) {
            return _DoneView(revoked: state.revokedSessions);
          }
          final enActual = state.step == ChangePinStep.actual;
          return PopScope(
            canPop: enActual && state.status == ChangePinStatus.idle,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) bloc.add(const ChangePinEvent.back());
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(l10n.changePinTitle),
                leading: BackButton(
                  onPressed: () => enActual
                      ? context.pop()
                      : bloc.add(const ChangePinEvent.back()),
                ),
              ),
              body: SafeArea(
                child: PinEntryView(
                  headline: switch (state.step) {
                    ChangePinStep.actual => l10n.changePinCurrentHeadline,
                    ChangePinStep.nuevo => l10n.changePinNewHeadline,
                    ChangePinStep.confirmar => l10n.changePinConfirmHeadline,
                  },
                  subtitle: switch (state.step) {
                    ChangePinStep.actual => l10n.changePinCurrentSubtitle,
                    ChangePinStep.nuevo => l10n.changePinNewSubtitle,
                    ChangePinStep.confirmar => l10n.changePinConfirmSubtitle,
                  },
                  pin: state.pin,
                  hasError: state.error != null,
                  errorText: _errorText(l10n, state),
                  rules: state.step == ChangePinStep.nuevo
                      ? [
                          PinRule(
                              label: l10n.pinRule6,
                              done: PinRules.hasSixDigits(state.pin)),
                          PinRule(
                              label: l10n.pinRuleNoRepeats,
                              done: PinRules.hasNoRepeatedDigit(state.pin)),
                          PinRule(
                              label: l10n.pinRuleNoSequence,
                              done: PinRules.hasNoSequence(state.pin)),
                        ]
                      : const [],
                  extra: state.status == ChangePinStatus.submitting
                      ? PinSubmittingNotice(
                          label: l10n.pinVerifying,
                          patienceLabel: l10n.pinVerifyingSlow,
                        )
                      : null,
                  onDigit: (d) => bloc.add(ChangePinEvent.digitPressed(d)),
                  onBackspace: () => bloc.add(const ChangePinEvent.backspace()),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView({required this.revoked});

  final int revoked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle,
                  size: 56, color: CuyCashColors.success),
              const SizedBox(height: CuyCashSpacing.stackMd),
              Text(l10n.changePinDoneTitle, style: CuyCashTypography.headlineSm),
              const SizedBox(height: CuyCashSpacing.stackXs),
              Text(l10n.changePinDoneOthers(revoked),
                  style: CuyCashTypography.bodyLg),
              const Spacer(),
              PrimaryButton(
                label: l10n.changePinDoneCta,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Las reglas usan `PinRules.hasSixDigits(state.pin)` sobre los dígitos que se van tecleando, igual que el registro. `errorWeakPin`, `resetPinSamePin`, `resetPinMismatch`, `pinVerifying` y `pinVerifyingSlow` ya existen en el ARB.

- [ ] **Step 7: Wire route and tile**

`router.dart`:

```dart
      GoRoute(
        path: AppRoutes.perfilPin,
        builder: (context, state) => BlocProvider(
          create: (_) => ChangePinBloc(SecurityModule.create(deps)),
          child: ChangePinScreen(
            onLocked: (until) => _cerrarPorBloqueo(context, authBloc, until),
          ),
        ),
      ),
```

Y al final de `router.dart`, función privada reutilizada por la Task 14:

```dart
/// El servidor ya cerró la sesión al bloquear. Un autenticado en
/// `/bloqueado` sería devuelto al inicio por `appRedirect`, así que primero se
/// cierra la sesión local y DESPUÉS se navega.
Future<void> _cerrarPorBloqueo(
  BuildContext context,
  AuthBloc authBloc,
  DateTime until,
) async {
  final router = GoRouter.of(context);
  final dni = switch (authBloc.state) {
    AuthAuthenticated(:final session) => session.identifier,
    AuthUnauthenticated() => null,
  };
  authBloc.add(const AuthEvent.signedOut());
  await authBloc.stream.firstWhere((s) => s is AuthUnauthenticated);
  router.go(
    AppRoutes.blocked,
    extra: BlockedArgs(
      origin: BlockedOrigin.login,
      lockedUntil: until,
      resumeDni: dni,
    ),
  );
}
```

Si `authBloc.state` ya es `AuthUnauthenticated` cuando llega el bloqueo, el `firstWhere` esperaría para siempre: protegerlo con `if (authBloc.state is! AuthUnauthenticated) { …add + await… }`.

`profile_screen.dart`: tile `profileItemChangePin` → `onTap: () => context.push(AppRoutes.perfilPin),`.

Añadir a `test/presentation/app/` (o donde estén los tests del router con `createAppRouter`; buscar con `grep -rln createAppRouter apps/mobile/test`) un test de recorrido con el flavor `mock`: abrir `/perfil/pin`, teclear `000000`/`502718`/`502718` y ver "Tu PIN cambió"; luego cerrar sesión y verificar que `MemoryAuthRepository.validPin` es `502718` (comprueba que el estado compartido funciona).

- [ ] **Step 8: Run tests and analyze**

Run: `cd apps/mobile && flutter test && cd ../.. && flutter analyze`
Expected: PASS, `No issues found!`.

- [ ] **Step 9: Commit**

```bash
git add apps/mobile/lib apps/mobile/test
git commit -m "feat(app): cambiar el PIN desde el perfil"
```

---

### Task 12: App — dispositivos vinculados

**Files:**
- Create: `apps/mobile/lib/presentation/profile/devices/bloc/linked_devices_bloc.dart` (+ `_event`, `_state`, `.freezed`), `linked_devices_screen.dart`, `widgets/linked_device_tile.dart`
- Modify: `router.dart`, `profile_screen.dart`, `app_es.arb`
- Test: `apps/mobile/test/presentation/profile/linked_devices_screen_test.dart`

**Interfaces:**
- Consumes: `SecurityActions.devices/unlinkDevice`.
- Produces: `LinkedDevicesBloc(SecurityActions)`; eventos `started()`, `unlinkRequested(String id)`; estado `{status: loading|ready|error, devices: List<LinkedDevice>, unlinking: String?, message: DevicesMessage?}`; `enum DevicesMessage { unlinked, cannotUnlinkCurrent, error }`.

Reglas: `unlinkRequested` → `unlinking: id` → `unlinkDevice`. Éxito **o `SecurityDeviceNotFound`** → `message: unlinked` y recarga la lista. `SecurityCannotUnlinkCurrent` → `cannotUnlinkCurrent`. Otro → `error`. Un segundo `unlinkRequested` mientras `unlinking != null` se ignora.

- [ ] **Step 1: ARB**

```json
  "devicesTitle": "Dispositivos vinculados",
  "devicesThisPhone": "Este teléfono",
  "devicesUnknownModel": "Dispositivo sin nombre",
  "devicesLinkedOn": "Vinculado el {date}",
  "@devicesLinkedOn": {"placeholders": {"date": {"type": "String"}}},
  "devicesLastUse": "Último uso: {date}",
  "@devicesLastUse": {"placeholders": {"date": {"type": "String"}}},
  "devicesBiometric": "Con huella activa",
  "devicesUnlink": "Desvincular",
  "devicesUnlinkTitle": "¿Desvincular este dispositivo?",
  "devicesUnlinkBody": "Cerraremos su sesión y, para volver a entrar desde ahí, pediremos un código a tu correo.",
  "devicesUnlinked": "Listo, ese dispositivo ya no tiene acceso.",
  "devicesCannotUnlinkCurrent": "Para salir de este teléfono, cierra sesión.",
  "devicesError": "No pudimos cargar tus dispositivos.",
  "devicesHelp": "Si no reconoces alguno, desvincúlalo y cambia tu PIN.",
```

Run: `cd apps/mobile && flutter gen-l10n`

- [ ] **Step 2: Write the failing test**

`test/presentation/profile/linked_devices_screen_test.dart`:

```dart
import 'package:cuycash/feature/security/application/security_actions.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_repository.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_state.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/profile/devices/bloc/linked_devices_bloc.dart';
import 'package:cuycash/presentation/profile/devices/linked_devices_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemorySecurityState estado;

  Future<void> abrir(WidgetTester tester) async {
    estado = MemorySecurityState.demo(clock: DateTime.now);
    await tester.pumpWidget(MaterialApp(
      theme: CuyCashTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider(
        create: (_) => LinkedDevicesBloc(SecurityActions(
            MemorySecurityRepository(estado, clock: DateTime.now)))
          ..add(const LinkedDevicesEvent.started()),
        child: const LinkedDevicesScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('lista con "Este teléfono" y sin desvincular en esa fila',
      (tester) async {
    await abrir(tester);

    expect(find.text('Este teléfono'), findsOneWidget);
    expect(find.text('iPhone14,5'), findsOneWidget);
    expect(find.text('Desvincular'), findsOneWidget);
  });

  testWidgets('desvincular pide confirmación, quita la fila y avisa',
      (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Desvincular'));
    await tester.pumpAndSettle();
    expect(find.text('¿Desvincular este dispositivo?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Desvincular'));
    await tester.pumpAndSettle();

    expect(find.text('iPhone14,5'), findsNothing);
    expect(find.text('Listo, ese dispositivo ya no tiene acceso.'),
        findsOneWidget);
  });

  testWidgets('si otro teléfono ya lo había sacado, también es éxito',
      (tester) async {
    await abrir(tester);
    estado.devices.removeWhere((d) => !d.esEste);

    await tester.tap(find.text('Desvincular'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Desvincular'));
    await tester.pumpAndSettle();

    expect(find.text('Listo, ese dispositivo ya no tiene acceso.'),
        findsOneWidget);
    expect(find.text('iPhone14,5'), findsNothing);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd apps/mobile && flutter test test/presentation/profile/linked_devices_screen_test.dart`
Expected: FAIL.

- [ ] **Step 4: Implement bloc**

`linked_devices_event.dart`:

```dart
part of 'linked_devices_bloc.dart';

@freezed
sealed class LinkedDevicesEvent with _$LinkedDevicesEvent {
  const factory LinkedDevicesEvent.started() = LinkedDevicesStarted;
  const factory LinkedDevicesEvent.unlinkRequested(String id) =
      LinkedDevicesUnlinkRequested;
}
```

`linked_devices_state.dart`:

```dart
part of 'linked_devices_bloc.dart';

enum LinkedDevicesStatus { loading, ready, error }

enum DevicesMessage { unlinked, cannotUnlinkCurrent, error }

@freezed
abstract class LinkedDevicesState with _$LinkedDevicesState {
  const factory LinkedDevicesState({
    @Default(LinkedDevicesStatus.loading) LinkedDevicesStatus status,
    @Default(<LinkedDevice>[]) List<LinkedDevice> devices,
    String? unlinking,
    DevicesMessage? message,
  }) = _LinkedDevicesState;
}
```

`linked_devices_bloc.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../feature/security/application/security_actions.dart';
import '../../../../feature/security/domain/linked_device.dart';
import '../../../../feature/security/domain/security_failure.dart';

part 'linked_devices_bloc.freezed.dart';
part 'linked_devices_event.dart';
part 'linked_devices_state.dart';

/// Lista y desvincula teléfonos. Que el dispositivo ya no exista (otro
/// teléfono lo sacó antes) es el resultado que el usuario quería: éxito.
class LinkedDevicesBloc extends Bloc<LinkedDevicesEvent, LinkedDevicesState> {
  LinkedDevicesBloc(this._actions) : super(const LinkedDevicesState()) {
    on<LinkedDevicesStarted>((event, emit) => _load(emit));
    on<LinkedDevicesUnlinkRequested>(_onUnlink);
  }

  final SecurityActions _actions;

  Future<void> _load(Emitter<LinkedDevicesState> emit,
      {DevicesMessage? message}) async {
    final result = await _actions.devices();
    emit(result.match(
      (_) => state.copyWith(
          status: LinkedDevicesStatus.error, unlinking: null, message: message),
      (devices) => state.copyWith(
        status: LinkedDevicesStatus.ready,
        devices: devices,
        unlinking: null,
        message: message,
      ),
    ));
  }

  Future<void> _onUnlink(
    LinkedDevicesUnlinkRequested event,
    Emitter<LinkedDevicesState> emit,
  ) async {
    if (state.unlinking != null) return;
    emit(state.copyWith(unlinking: event.id, message: null));
    final result = await _actions.unlinkDevice(event.id);
    final message = result.match(
      (failure) => switch (failure) {
        ServerFailure(failure: SecurityDeviceNotFound()) =>
          DevicesMessage.unlinked,
        ServerFailure(failure: SecurityCannotUnlinkCurrent()) =>
          DevicesMessage.cannotUnlinkCurrent,
        _ => DevicesMessage.error,
      },
      (_) => DevicesMessage.unlinked,
    );
    await _load(emit, message: message);
  }
}
```

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Implement screen and tile**

`widgets/linked_device_tile.dart`:

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../feature/security/domain/linked_device.dart';
import '../../../../l10n/app_localizations.dart';

/// Una fila de "Dispositivos vinculados". Sin acción en este teléfono.
class LinkedDeviceTile extends StatelessWidget {
  const LinkedDeviceTile({
    required this.device,
    required this.busy,
    this.onUnlink,
    super.key,
  });

  final LinkedDevice device;
  final bool busy;
  final VoidCallback? onUnlink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fecha = DateFormat('dd/MM/yyyy');
    return Padding(
      padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
      child: Row(
        children: [
          Icon(
            device.plataforma == 'ios' ? Icons.phone_iphone : Icons.phone_android,
            color: CuyCashColors.primaryContainer,
          ),
          const SizedBox(width: CuyCashSpacing.stackSm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.esEste
                      ? l10n.devicesThisPhone
                      : device.nombre ?? l10n.devicesUnknownModel,
                  style: CuyCashTypography.labelMd,
                ),
                if (device.esEste && device.nombre != null)
                  Text(device.nombre ?? '', style: CuyCashTypography.labelSm),
                Text(
                  l10n.devicesLinkedOn(
                      fecha.format(device.vinculadoEl.toLocal())),
                  style: CuyCashTypography.labelSm,
                ),
                Text(
                  l10n.devicesLastUse(fecha.format(device.ultimoUso.toLocal())),
                  style: CuyCashTypography.labelSm,
                ),
                if (device.conHuella)
                  Row(
                    children: [
                      const Icon(Icons.fingerprint,
                          size: 14, color: CuyCashColors.success),
                      const SizedBox(width: CuyCashSpacing.stackXs),
                      Text(l10n.devicesBiometric,
                          style: CuyCashTypography.labelSm),
                    ],
                  ),
              ],
            ),
          ),
          if (!device.esEste)
            busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : GhostButton(label: l10n.devicesUnlink, onPressed: onUnlink),
        ],
      ),
    );
  }
}
```

(`Text(device.nombre ?? '')` evita el `!` prohibido; la condición ya garantiza que no es nulo.)

`linked_devices_screen.dart`:

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../feature/security/domain/linked_device.dart';
import '../../../l10n/app_localizations.dart';
import 'bloc/linked_devices_bloc.dart';
import 'widgets/linked_device_tile.dart';

/// Teléfonos con acceso a la cuenta. Desvincular cierra su sesión, revoca su
/// huella y le vuelve a pedir OTP.
class LinkedDevicesScreen extends StatelessWidget {
  const LinkedDevicesScreen({super.key});

  Future<void> _confirmUnlink(BuildContext context, LinkedDevice device) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<LinkedDevicesBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.devicesUnlinkTitle),
        content: Text(l10n.devicesUnlinkBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.devicesUnlink),
          ),
        ],
      ),
    );
    if (ok == true) bloc.add(LinkedDevicesEvent.unlinkRequested(device.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: CuyCashColors.surfaceContainerLow,
      appBar: AppBar(
        title: Text(l10n.devicesTitle),
        backgroundColor: CuyCashColors.surfaceContainerLow,
      ),
      body: BlocConsumer<LinkedDevicesBloc, LinkedDevicesState>(
        listenWhen: (p, c) => c.message != null && p.message != c.message,
        listener: (context, state) {
          final texto = switch (state.message) {
            DevicesMessage.unlinked => l10n.devicesUnlinked,
            DevicesMessage.cannotUnlinkCurrent => l10n.devicesCannotUnlinkCurrent,
            DevicesMessage.error => l10n.errorGeneric,
            null => null,
          };
          if (texto == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(texto)));
        },
        builder: (context, state) => switch (state.status) {
          LinkedDevicesStatus.loading =>
            const Center(child: CircularProgressIndicator()),
          LinkedDevicesStatus.error => Center(
              child: Padding(
                padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.devicesError, style: CuyCashTypography.bodyMd),
                    const SizedBox(height: CuyCashSpacing.stackMd),
                    SecondaryButton(
                      label: l10n.homeRetry,
                      onPressed: () => context
                          .read<LinkedDevicesBloc>()
                          .add(const LinkedDevicesEvent.started()),
                    ),
                  ],
                ),
              ),
            ),
          LinkedDevicesStatus.ready => ListView(
              padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
              children: [
                SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (i, d) in state.devices.indexed) ...[
                        if (i > 0)
                          const Divider(height: 1, color: CuyCashColors.divider),
                        LinkedDeviceTile(
                          device: d,
                          busy: state.unlinking == d.id,
                          onUnlink: () => _confirmUnlink(context, d),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: CuyCashSpacing.stackMd),
                InfoStrip(icon: Icons.shield_outlined, text: l10n.devicesHelp),
              ],
            ),
        },
      ),
    );
  }
}
```

- [ ] **Step 6: Wire route and tile**

`router.dart`:

```dart
      GoRoute(
        path: AppRoutes.perfilDispositivos,
        builder: (context, state) => BlocProvider(
          create: (_) => LinkedDevicesBloc(SecurityModule.create(deps))
            ..add(const LinkedDevicesEvent.started()),
          child: const LinkedDevicesScreen(),
        ),
      ),
```

`profile_screen.dart`: tile `profileItemDevices` → `onTap: () => context.push(AppRoutes.perfilDispositivos),`.

- [ ] **Step 7: Run tests and analyze**

Run: `cd apps/mobile && flutter test && cd ../.. && flutter analyze`
Expected: PASS, `No issues found!`.

- [ ] **Step 8: Commit**

```bash
git add apps/mobile/lib apps/mobile/test
git commit -m "feat(app): dispositivos vinculados"
```

---

### Task 13: App — `BiometricGate` y casos de uso de la huella

**Files:**
- Modify: `apps/mobile/pubspec.yaml`, `apps/mobile/android/app/build.gradle.kts:27`, `apps/mobile/android/app/src/main/AndroidManifest.xml`, `apps/mobile/android/app/src/main/kotlin/pe/cuycash/cuycash/MainActivity.kt`, `apps/mobile/ios/Runner/Info.plist`
- Create: `apps/mobile/lib/feature/biometric/domain/biometric_gate.dart`, `apps/mobile/lib/feature/biometric/infrastructure/local_auth_biometric_gate.dart`, `memory_biometric_gate.dart`
- Create: `apps/mobile/lib/feature/security/application/enable_biometric_use_case.dart`, `disable_biometric_use_case.dart`, `biometric_sign_in_use_case.dart`
- Modify: `app_dependencies.dart`, `mock_dependencies.dart`, `shared_backend_dependencies.dart`, `modules/security_module.dart`
- Test: `apps/mobile/test/feature/security/biometric_use_cases_test.dart`

**Interfaces:**
- Produces:
  - `enum BiometricOutcome { success, cancelled, unavailable, failed }`
  - `abstract interface class BiometricGate { Future<bool> isAvailable(); Future<BiometricOutcome> authenticate(String reason); }`
  - `MemoryBiometricGate({bool available = true, BiometricOutcome outcome = BiometricOutcome.success})` con campos mutables `available`, `outcome` y contador `prompts`.
  - `LocalAuthBiometricGate()`.
  - `EnableBiometricUseCase({required SecurityRepository repo, required BiometricGate gate, required DeviceStore store})`: `Future<bool> isAvailable()` y `FutureResult<SecurityFailure, bool> call({required String pin, required String reason})`. `right(true)` = activada; `right(false)` = el usuario canceló el diálogo.
  - `DisableBiometricUseCase({repo, store})`: `Future<void> call()`.
  - `BiometricSignInUseCase({required AuthRepository auth, required BiometricGate gate, required DeviceStore store})`: `Future<bool> canUse()` y `Future<BiometricSignIn> call({required String dni, required String reason})`.
  - `sealed class BiometricSignIn` → `BiometricSignInSuccess`, `BiometricSignInCancelled`, `BiometricSignInUnavailable`, `BiometricSignInRevoked`, `BiometricSignInLocked(DateTime until)`, `BiometricSignInFailed`.
  - `AppDependencies.biometricGate`; `SecurityModule.enableBiometric(deps)`, `disableBiometric(deps)`, `biometricSignIn(deps)`.

- [ ] **Step 1: Dependencies and native config**

Run: `cd apps/mobile && flutter pub add local_auth`

`android/app/build.gradle.kts`: `minSdk = maxOf(flutter.minSdkVersion, 24)` (`local_auth` exige SDK 24+).

`AndroidManifest.xml`, junto a los otros permisos: `<uses-permission android:name="android.permission.USE_BIOMETRIC"/>`.

`MainActivity.kt`: `import io.flutter.embedding.android.FlutterFragmentActivity` en lugar de `FlutterActivity`, y `class MainActivity : FlutterFragmentActivity() {`. El resto (canal de `FLAG_SECURE`) queda igual: `configureFlutterEngine` existe también en `FlutterFragmentActivity`.

`ios/Runner/Info.plist`, junto a `NSCameraUsageDescription`:

```xml
	<key>NSFaceIDUsageDescription</key>
	<string>CuyCash usa Face ID para que entres a tu cuenta sin escribir tu PIN.</string>
```

- [ ] **Step 2: Write the failing test**

`test/feature/security/biometric_use_cases_test.dart`:

```dart
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/biometric/domain/biometric_gate.dart';
import 'package:cuycash/feature/biometric/infrastructure/memory_biometric_gate.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/security/application/biometric_sign_in_use_case.dart';
import 'package:cuycash/feature/security/application/disable_biometric_use_case.dart';
import 'package:cuycash/feature/security/application/enable_biometric_use_case.dart';
import 'package:cuycash/feature/security/domain/security_failure.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_repository.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_state.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemorySecurityState estado;
  late MemoryDeviceStore store;
  late MemoryBiometricGate gate;
  late EnableBiometricUseCase activar;
  late BiometricSignInUseCase entrar;

  setUp(() {
    estado = MemorySecurityState.demo(clock: DateTime.now);
    store = MemoryDeviceStore();
    gate = MemoryBiometricGate();
    final repo = MemorySecurityRepository(estado, clock: DateTime.now);
    activar = EnableBiometricUseCase(repo: repo, gate: gate, store: store);
    entrar = BiometricSignInUseCase(
      auth: MemoryAuthRepository(security: estado),
      gate: gate,
      store: store,
    );
  });

  test('activar: huella, servidor y secreto guardado', () async {
    final r = await activar(pin: '000000', reason: 'r');

    expect(r.getRight().toNullable(), isTrue);
    expect(await store.readBiometricCredential(), isNotNull);
    expect(estado.credentials.values, [estado.thisDeviceId]);
    expect(await entrar.canUse(), isTrue);
  });

  test('cancelar el diálogo no llama al servidor', () async {
    gate.outcome = BiometricOutcome.cancelled;

    final r = await activar(pin: '000000', reason: 'r');

    expect(r.getRight().toNullable(), isFalse);
    expect(estado.credentials, isEmpty);
  });

  test('sin sensor es biometricUnavailable', () async {
    gate.available = false;

    final r = await activar(pin: '000000', reason: 'r');

    expect(
      switch (r.getLeft().toNullable()) {
        ServerFailure(:final failure) => failure,
        _ => null,
      },
      isA<SecurityBiometricUnavailable>(),
    );
  });

  test('si no se puede guardar el secreto, se revoca en el servidor', () async {
    store.failCredentialWrites = true;

    final r = await activar(pin: '000000', reason: 'r');

    expect(r.isLeft(), isTrue);
    expect(estado.credentials, isEmpty);
  });

  test('entrar con huella abre sesión', () async {
    await activar(pin: '000000', reason: 'r');

    expect(await entrar(dni: estado.dni, reason: 'r'),
        isA<BiometricSignInSuccess>());
  });

  test('credencial revocada: se borra del teléfono y canUse es false',
      () async {
    await activar(pin: '000000', reason: 'r');
    estado.credentials.clear();

    expect(await entrar(dni: estado.dni, reason: 'r'),
        isA<BiometricSignInRevoked>());
    expect(await store.readBiometricCredential(), isNull);
    expect(await entrar.canUse(), isFalse);
  });

  test('sin huellas en el sistema el botón no aplica aunque haya credencial',
      () async {
    await activar(pin: '000000', reason: 'r');
    gate.available = false;

    expect(await entrar.canUse(), isFalse);
  });

  test('desactivar borra local y servidor', () async {
    await activar(pin: '000000', reason: 'r');

    await DisableBiometricUseCase(
      repo: MemorySecurityRepository(estado, clock: DateTime.now),
      store: store,
    )();

    expect(await store.readBiometricCredential(), isNull);
    expect(estado.credentials, isEmpty);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd apps/mobile && flutter test test/feature/security/biometric_use_cases_test.dart`
Expected: FAIL.

- [ ] **Step 4: Implement gate**

`lib/feature/biometric/domain/biometric_gate.dart`:

```dart
/// Resultado del diálogo biométrico del sistema. Cancelar no es un error: el
/// usuario eligió el PIN.
enum BiometricOutcome { success, cancelled, unavailable, failed }

/// La huella o el rostro del sistema. El teléfono no guarda nada aquí: solo
/// pregunta "¿es el dueño?".
abstract interface class BiometricGate {
  /// Hay sensor Y al menos una huella o rostro registrado.
  Future<bool> isAvailable();

  Future<BiometricOutcome> authenticate(String reason);
}
```

`local_auth_biometric_gate.dart`:

```dart
import 'package:local_auth/local_auth.dart';

import '../domain/biometric_gate.dart';

/// `BiometricGate` sobre `local_auth`. Solo biometría (`biometricOnly`): el
/// PIN del sistema no sustituye al de CuyCash.
class LocalAuthBiometricGate implements BiometricGate {
  LocalAuthBiometricGate([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<BiometricOutcome> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
      return ok ? BiometricOutcome.success : BiometricOutcome.failed;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.userRequestedFallback ||
        LocalAuthExceptionCode.timeout => BiometricOutcome.cancelled,
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
          BiometricOutcome.unavailable,
        _ => BiometricOutcome.failed,
      };
    } catch (_) {
      return BiometricOutcome.failed;
    }
  }
}
```

Tras el `pub add`, comprobar contra la versión instalada que existen `LocalAuthException`, `LocalAuthExceptionCode` y el parámetro `biometricOnly` directo en `authenticate` (API de `local_auth` 3.x). Si se resolvió una 2.x, usar `options: const AuthenticationOptions(biometricOnly: true)` y `PlatformException` con los códigos de `local_auth/error_codes.dart`.

`memory_biometric_gate.dart`:

```dart
import '../domain/biometric_gate.dart';

/// Gate configurable para tests y para el flavor `mock` (un emulador sin
/// huella igual puede recorrer la demo).
class MemoryBiometricGate implements BiometricGate {
  MemoryBiometricGate({
    this.available = true,
    this.outcome = BiometricOutcome.success,
  });

  bool available;
  BiometricOutcome outcome;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<BiometricOutcome> authenticate(String reason) async {
    prompts++;
    return available ? outcome : BiometricOutcome.unavailable;
  }
}
```

- [ ] **Step 5: Implement use cases**

`enable_biometric_use_case.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../../biometric/domain/biometric_gate.dart';
import '../../device/domain/device_store.dart';
import '../domain/security_failure.dart';
import '../domain/security_repository.dart';

/// Activa la huella: sensor → diálogo del sistema → servidor → secreto en el
/// teléfono. El diálogo va ANTES del servidor: si el usuario cancela, no
/// queda una credencial emitida que nadie guardó.
class EnableBiometricUseCase {
  const EnableBiometricUseCase({
    required SecurityRepository repo,
    required BiometricGate gate,
    required DeviceStore store,
  })  : _repo = repo,
        _gate = gate,
        _store = store;

  final SecurityRepository _repo;
  final BiometricGate _gate;
  final DeviceStore _store;

  Future<bool> isAvailable() => _gate.isAvailable();

  /// `right(true)` activada; `right(false)` el usuario canceló.
  FutureResult<SecurityFailure, bool> call({
    required String pin,
    required String reason,
  }) async {
    const noDisponible =
        GlobalFailure<SecurityFailure>.server(SecurityFailure.biometricUnavailable());
    if (!await _gate.isAvailable()) return left(noDisponible);

    switch (await _gate.authenticate(reason)) {
      case BiometricOutcome.cancelled:
        return right(false);
      case BiometricOutcome.unavailable:
        return left(noDisponible);
      case BiometricOutcome.failed:
        return left(const GlobalFailure.server(SecurityFailure.unexpected()));
      case BiometricOutcome.success:
        break;
    }

    final emitida = await _repo.enrollBiometric(pin);
    return emitida.match(
      (failure) async => left(failure),
      (secreto) async {
        if (await _store.saveBiometricCredential(secreto)) return right(true);
        // Una credencial que el teléfono no pudo guardar no la usará nadie:
        // se revoca para no dejarla viva en el servidor.
        await _repo.revokeBiometric();
        return left(const GlobalFailure.server(SecurityFailure.unexpected()));
      },
    );
  }
}
```

`disable_biometric_use_case.dart`:

```dart
import '../../device/domain/device_store.dart';
import '../domain/security_repository.dart';

/// Apaga la huella. El secreto local se borra SIEMPRE, aunque el servidor no
/// conteste: sin él, la credencial del servidor no la puede usar nadie, y se
/// revoca en el próximo `enroll`.
class DisableBiometricUseCase {
  const DisableBiometricUseCase({
    required SecurityRepository repo,
    required DeviceStore store,
  })  : _repo = repo,
        _store = store;

  final SecurityRepository _repo;
  final DeviceStore _store;

  Future<void> call() async {
    await _store.clearBiometricCredential();
    await _repo.revokeBiometric();
  }
}
```

`biometric_sign_in_use_case.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';

import '../../auth/domain/auth_failure.dart';
import '../../auth/domain/auth_repository.dart';
import '../../biometric/domain/biometric_gate.dart';
import '../../device/domain/device_store.dart';

/// Cómo terminó un intento de entrar con huella.
sealed class BiometricSignIn {
  const BiometricSignIn();
}

final class BiometricSignInSuccess extends BiometricSignIn {
  const BiometricSignInSuccess();
}

final class BiometricSignInCancelled extends BiometricSignIn {
  const BiometricSignInCancelled();
}

final class BiometricSignInUnavailable extends BiometricSignIn {
  const BiometricSignInUnavailable();
}

/// La credencial ya no vale: se borró del teléfono; hay que entrar con PIN.
final class BiometricSignInRevoked extends BiometricSignIn {
  const BiometricSignInRevoked();
}

final class BiometricSignInLocked extends BiometricSignIn {
  const BiometricSignInLocked(this.until);
  final DateTime until;
}

final class BiometricSignInFailed extends BiometricSignIn {
  const BiometricSignInFailed();
}

/// Entrar con huella desde el acceso rápido. Un fallo de huella NO suma al
/// bloqueo local del acceso rápido: ese contador es del PIN.
class BiometricSignInUseCase {
  const BiometricSignInUseCase({
    required AuthRepository auth,
    required BiometricGate gate,
    required DeviceStore store,
  })  : _auth = auth,
        _gate = gate,
        _store = store;

  final AuthRepository _auth;
  final BiometricGate _gate;
  final DeviceStore _store;

  /// Hay credencial guardada Y el sistema puede pedir la huella.
  Future<bool> canUse() async =>
      await _store.readBiometricCredential() != null &&
      await _gate.isAvailable();

  Future<BiometricSignIn> call({
    required String dni,
    required String reason,
  }) async {
    final credencial = await _store.readBiometricCredential();
    if (credencial == null) return const BiometricSignInRevoked();

    switch (await _gate.authenticate(reason)) {
      case BiometricOutcome.cancelled:
        return const BiometricSignInCancelled();
      case BiometricOutcome.unavailable:
        return const BiometricSignInUnavailable();
      case BiometricOutcome.failed:
        return const BiometricSignInFailed();
      case BiometricOutcome.success:
        break;
    }

    final result =
        await _auth.signInWithBiometric(dni: dni, credential: credencial);
    return result.match(
      (failure) => switch (failure) {
        ServerFailure(failure: BiometricRevoked()) => _forget(),
        ServerFailure(failure: AccessLocked(:final until)) =>
          Future.value(BiometricSignInLocked(until)),
        _ => Future.value(const BiometricSignInFailed()),
      },
      (_) => Future.value(const BiometricSignInSuccess()),
    );
  }

  Future<BiometricSignIn> _forget() async {
    await _store.clearBiometricCredential();
    return const BiometricSignInRevoked();
  }
}
```

(`result.match` devuelve `Future<BiometricSignIn>` en ambas ramas; el `return` del método lo espera.)

- [ ] **Step 6: Wire dependencies**

`app_dependencies.dart`: `required this.biometricGate,` y `final BiometricGate biometricGate;` con doc. `mock_dependencies.dart`: `biometricGate: MemoryBiometricGate(),`. `shared_backend_dependencies.dart`: `biometricGate: LocalAuthBiometricGate(),`. Tests que construyen `AppDependencies`: `biometricGate: MemoryBiometricGate(),`.

`security_module.dart`:

```dart
  static EnableBiometricUseCase enableBiometric(AppDependencies deps) =>
      EnableBiometricUseCase(
        repo: deps.securityRepository,
        gate: deps.biometricGate,
        store: deps.deviceStore,
      );

  static DisableBiometricUseCase disableBiometric(AppDependencies deps) =>
      DisableBiometricUseCase(
          repo: deps.securityRepository, store: deps.deviceStore);

  static BiometricSignInUseCase biometricSignIn(AppDependencies deps) =>
      BiometricSignInUseCase(
        auth: deps.authRepository,
        gate: deps.biometricGate,
        store: deps.deviceStore,
      );
```

- [ ] **Step 7: Run tests, analyze, and build Android**

Run: `cd apps/mobile && flutter test && cd ../.. && flutter analyze && cd apps/mobile && flutter build apk --flavor mock -t lib/main_mock.dart --dart-define-from-file=config.mock.json --debug`
Expected: PASS, `No issues found!`, APK generado (comprueba `FlutterFragmentActivity` y `minSdk`). Si `config.mock.json` no existe, crearlo desde `config.example.json` como indica el README.

- [ ] **Step 8: Commit**

```bash
git add apps/mobile pubspec.lock
git commit -m "feat(app): BiometricGate con local_auth y casos de uso de la huella"
```

---

### Task 14: App — pantalla "Acceso biométrico"

**Files:**
- Create: `apps/mobile/lib/presentation/profile/biometric/bloc/biometric_settings_bloc.dart` (+ `_event`, `_state`, `.freezed`), `biometric_settings_screen.dart`
- Modify: `router.dart`, `profile_screen.dart`, `app_es.arb`
- Test: `apps/mobile/test/presentation/profile/biometric_settings_screen_test.dart`

**Interfaces:**
- Consumes: `EnableBiometricUseCase`, `DisableBiometricUseCase`, `DeviceActions.readBiometricCredential`.
- Produces:
  - `BiometricSettingsBloc({required EnableBiometricUseCase enable, required DisableBiometricUseCase disable, required DeviceActions device})`; eventos `started()`, `enableRequested()`, `pinDigit(int)`, `pinBackspace()`, `pinCancelled()`, `disableRequested()`.
  - Estado `{status: loading|ready|askingPin|working, available: bool, enabled: bool, pin: String, error: BiometricSettingsError?, attemptsLeft: int?, lockedUntil: DateTime?}`; `enum BiometricSettingsError { wrongPin, unavailable, generic }`.
  - `BiometricSettingsScreen({required void Function(DateTime) onLocked})`.

Flujo: `started` lee `available` y `enabled` (credencial guardada). `enableRequested` → `askingPin`. Al sexto dígito → `working` → `enable(pin:, reason:)`; la pantalla pasa el `reason` del ARB con el evento `pinDigit` (el bloc no conoce l10n). Para eso el evento final lleva la razón: `pinDigit(int digit, {required String reason})`.
- `right(true)` → `ready, enabled: true`.
- `right(false)` → `ready, enabled: false`, sin error.
- `SecurityWrongPin(n)` → `askingPin`, `pin: ''`, `wrongPin`, `attemptsLeft: n`.
- `SecurityLocked` → `lockedUntil`.
- `SecurityBiometricUnavailable` → `ready`, `available: false`, `unavailable`.
- Otro → `ready`, `generic`.
- `disableRequested` → `working` → `disable()` → `ready, enabled: false`.

- [ ] **Step 1: ARB**

```json
  "biometricSettingsTitle": "Acceso biométrico",
  "biometricSettingsSwitch": "Entrar con huella o rostro",
  "biometricSettingsBody": "Entra a CuyCash sin escribir tu PIN. Tu PIN sigue funcionando siempre.",
  "biometricSettingsUnavailable": "Este teléfono no tiene huella ni rostro registrados. Configúralos en los ajustes del sistema y vuelve aquí.",
  "biometricSettingsPinHeadline": "Confirma con tu PIN",
  "biometricSettingsPinSubtitle": "Después te pediremos tu huella o tu rostro.",
  "biometricSettingsReason": "Confirma que eres tú para activar el acceso biométrico",
  "biometricSettingsWrong": "{count, plural, =1{PIN incorrecto. Te queda 1 intento.} other{PIN incorrecto. Te quedan {count} intentos.}}",
  "@biometricSettingsWrong": {"placeholders": {"count": {"type": "int"}}},
  "biometricSettingsEnabled": "Listo, ya puedes entrar con tu huella o rostro.",
```

Run: `cd apps/mobile && flutter gen-l10n`

- [ ] **Step 2: Write the failing test**

`test/presentation/profile/biometric_settings_screen_test.dart`:

```dart
import 'package:cuycash/feature/biometric/domain/biometric_gate.dart';
import 'package:cuycash/feature/biometric/infrastructure/memory_biometric_gate.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/security/application/disable_biometric_use_case.dart';
import 'package:cuycash/feature/security/application/enable_biometric_use_case.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_repository.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_state.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/profile/biometric/bloc/biometric_settings_bloc.dart';
import 'package:cuycash/presentation/profile/biometric/biometric_settings_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryBiometricGate gate;
  late MemoryDeviceStore store;
  late MemorySecurityState estado;

  Future<void> abrir(WidgetTester tester, {bool available = true}) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    gate = MemoryBiometricGate(available: available);
    store = MemoryDeviceStore();
    estado = MemorySecurityState.demo(clock: DateTime.now);
    final repo = MemorySecurityRepository(estado, clock: DateTime.now);
    await tester.pumpWidget(MaterialApp(
      theme: CuyCashTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider(
        create: (_) => BiometricSettingsBloc(
          enable: EnableBiometricUseCase(repo: repo, gate: gate, store: store),
          disable: DisableBiometricUseCase(repo: repo, store: store),
          device: DeviceActions(store),
        )..add(const BiometricSettingsEvent.started()),
        child: BiometricSettingsScreen(onLocked: (_) {}),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> teclear(WidgetTester tester, String pin) async {
    for (final d in pin.split('')) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('encender pide PIN, luego la huella, y queda activo',
      (tester) async {
    await abrir(tester);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Confirma con tu PIN'), findsOneWidget);

    await teclear(tester, '000000');

    expect(gate.prompts, 1);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(await store.readBiometricCredential(), isNotNull);
  });

  testWidgets('cancelar la huella deja el interruptor apagado sin error',
      (tester) async {
    await abrir(tester);
    gate.outcome = BiometricOutcome.cancelled;

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await teclear(tester, '000000');

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(estado.credentials, isEmpty);
  });

  testWidgets('sin sensor lo explica y no deja encender', (tester) async {
    await abrir(tester, available: false);

    expect(find.textContaining('no tiene huella ni rostro'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
  });

  testWidgets('apagar borra la credencial', (tester) async {
    await abrir(tester);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await teclear(tester, '000000');

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(await store.readBiometricCredential(), isNull);
    expect(estado.credentials, isEmpty);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd apps/mobile && flutter test test/presentation/profile/biometric_settings_screen_test.dart`
Expected: FAIL.

- [ ] **Step 4: Implement bloc**

`biometric_settings_event.dart`:

```dart
part of 'biometric_settings_bloc.dart';

@freezed
sealed class BiometricSettingsEvent with _$BiometricSettingsEvent {
  const factory BiometricSettingsEvent.started() = BiometricSettingsStarted;
  const factory BiometricSettingsEvent.enableRequested() =
      BiometricSettingsEnableRequested;

  /// [reason] es el texto del diálogo del sistema (viene del ARB).
  const factory BiometricSettingsEvent.pinDigit(int digit,
      {required String reason}) = BiometricSettingsPinDigit;
  const factory BiometricSettingsEvent.pinBackspace() =
      BiometricSettingsPinBackspace;
  const factory BiometricSettingsEvent.pinCancelled() =
      BiometricSettingsPinCancelled;
  const factory BiometricSettingsEvent.disableRequested() =
      BiometricSettingsDisableRequested;
}
```

`biometric_settings_state.dart`:

```dart
part of 'biometric_settings_bloc.dart';

enum BiometricSettingsStatus { loading, ready, askingPin, working }

enum BiometricSettingsError { wrongPin, unavailable, generic }

@freezed
abstract class BiometricSettingsState with _$BiometricSettingsState {
  const factory BiometricSettingsState({
    @Default(BiometricSettingsStatus.loading) BiometricSettingsStatus status,
    @Default(false) bool available,
    @Default(false) bool enabled,
    @Default('') String pin,
    BiometricSettingsError? error,
    int? attemptsLeft,
    DateTime? lockedUntil,
    @Default(false) bool justEnabled,
  }) = _BiometricSettingsState;
}
```

`biometric_settings_bloc.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../feature/device/application/device_actions.dart';
import '../../../../feature/security/application/disable_biometric_use_case.dart';
import '../../../../feature/security/application/enable_biometric_use_case.dart';
import '../../../../feature/security/domain/security_failure.dart';

part 'biometric_settings_bloc.freezed.dart';
part 'biometric_settings_event.dart';
part 'biometric_settings_state.dart';

/// Encender o apagar la huella. "Encendida" es: hay credencial guardada en
/// este teléfono (el servidor la confirma la próxima vez que se use).
class BiometricSettingsBloc
    extends Bloc<BiometricSettingsEvent, BiometricSettingsState> {
  BiometricSettingsBloc({
    required EnableBiometricUseCase enable,
    required DisableBiometricUseCase disable,
    required DeviceActions device,
  })  : _enable = enable,
        _disable = disable,
        _device = device,
        super(const BiometricSettingsState()) {
    on<BiometricSettingsStarted>(_onStarted);
    on<BiometricSettingsEnableRequested>((event, emit) {
      if (state.status != BiometricSettingsStatus.ready || !state.available) {
        return;
      }
      emit(state.copyWith(
          status: BiometricSettingsStatus.askingPin, pin: '', error: null));
    });
    on<BiometricSettingsPinDigit>(_onDigit);
    on<BiometricSettingsPinBackspace>((event, emit) {
      if (state.status != BiometricSettingsStatus.askingPin ||
          state.pin.isEmpty) {
        return;
      }
      emit(state.copyWith(pin: state.pin.substring(0, state.pin.length - 1)));
    });
    on<BiometricSettingsPinCancelled>((event, emit) => emit(state.copyWith(
        status: BiometricSettingsStatus.ready, pin: '', error: null)));
    on<BiometricSettingsDisableRequested>(_onDisable);
  }

  final EnableBiometricUseCase _enable;
  final DisableBiometricUseCase _disable;
  final DeviceActions _device;

  Future<void> _onStarted(
    BiometricSettingsStarted event,
    Emitter<BiometricSettingsState> emit,
  ) async {
    final available = await _enable.isAvailable();
    final enabled = await _device.readBiometricCredential() != null;
    emit(BiometricSettingsState(
      status: BiometricSettingsStatus.ready,
      available: available,
      enabled: enabled,
    ));
  }

  Future<void> _onDigit(
    BiometricSettingsPinDigit event,
    Emitter<BiometricSettingsState> emit,
  ) async {
    if (state.status != BiometricSettingsStatus.askingPin ||
        state.pin.length >= 6) {
      return;
    }
    final pin = '${state.pin}${event.digit}';
    emit(state.copyWith(pin: pin, error: null));
    if (pin.length < 6) return;

    emit(state.copyWith(status: BiometricSettingsStatus.working));
    final result = await _enable(pin: pin, reason: event.reason);
    emit(result.match(
      (failure) => switch (failure) {
        ServerFailure(failure: SecurityWrongPin(:final attemptsLeft)) =>
          state.copyWith(
            status: BiometricSettingsStatus.askingPin,
            pin: '',
            error: BiometricSettingsError.wrongPin,
            attemptsLeft: attemptsLeft,
          ),
        ServerFailure(failure: SecurityLocked(:final until)) =>
          state.copyWith(lockedUntil: until),
        ServerFailure(failure: SecurityBiometricUnavailable()) =>
          state.copyWith(
            status: BiometricSettingsStatus.ready,
            pin: '',
            available: false,
            error: BiometricSettingsError.unavailable,
          ),
        _ => state.copyWith(
            status: BiometricSettingsStatus.ready,
            pin: '',
            error: BiometricSettingsError.generic,
          ),
      },
      (activada) => state.copyWith(
        status: BiometricSettingsStatus.ready,
        pin: '',
        enabled: activada,
        justEnabled: activada,
      ),
    ));
  }

  Future<void> _onDisable(
    BiometricSettingsDisableRequested event,
    Emitter<BiometricSettingsState> emit,
  ) async {
    if (state.status != BiometricSettingsStatus.ready) return;
    emit(state.copyWith(status: BiometricSettingsStatus.working));
    await _disable();
    emit(state.copyWith(
        status: BiometricSettingsStatus.ready,
        enabled: false,
        justEnabled: false));
  }
}
```

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Implement screen**

`biometric_settings_screen.dart`:

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/security/secure_screen_scope.dart';
import '../../../l10n/app_localizations.dart';
import '../../pin/pin_entry_view.dart';
import 'bloc/biometric_settings_bloc.dart';

/// Acceso biométrico: un interruptor. Encender pide el PIN (aquí, con
/// `PinEntryView`) y después la huella del sistema.
class BiometricSettingsScreen extends StatelessWidget {
  const BiometricSettingsScreen({required this.onLocked, super.key});

  final void Function(DateTime until) onLocked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<BiometricSettingsBloc, BiometricSettingsState>(
      listener: (context, state) {
        if (state.lockedUntil case final until?) onLocked(until);
        if (state.justEnabled) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
                SnackBar(content: Text(l10n.biometricSettingsEnabled)));
        }
      },
      listenWhen: (p, c) =>
          p.lockedUntil != c.lockedUntil ||
          (!p.justEnabled && c.justEnabled),
      builder: (context, state) {
        final bloc = context.read<BiometricSettingsBloc>();
        final pidiendoPin = state.status == BiometricSettingsStatus.askingPin ||
            (state.status == BiometricSettingsStatus.working &&
                state.pin.length == 6);
        if (pidiendoPin) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) bloc.add(const BiometricSettingsEvent.pinCancelled());
            },
            child: SecureScreenScope(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(l10n.biometricSettingsTitle),
                  leading: BackButton(
                    onPressed: () =>
                        bloc.add(const BiometricSettingsEvent.pinCancelled()),
                  ),
                ),
                body: SafeArea(
                  child: PinEntryView(
                    headline: l10n.biometricSettingsPinHeadline,
                    subtitle: l10n.biometricSettingsPinSubtitle,
                    pin: state.pin,
                    hasError: state.error == BiometricSettingsError.wrongPin,
                    errorText: state.error == BiometricSettingsError.wrongPin
                        ? l10n.biometricSettingsWrong(state.attemptsLeft ?? 0)
                        : null,
                    onDigit: (d) => bloc.add(BiometricSettingsEvent.pinDigit(d,
                        reason: l10n.biometricSettingsReason)),
                    onBackspace: () =>
                        bloc.add(const BiometricSettingsEvent.pinBackspace()),
                  ),
                ),
              ),
            ),
          );
        }
        final listo = state.status == BiometricSettingsStatus.ready;
        return Scaffold(
          backgroundColor: CuyCashColors.surfaceContainerLow,
          appBar: AppBar(
            title: Text(l10n.biometricSettingsTitle),
            backgroundColor: CuyCashColors.surfaceContainerLow,
          ),
          body: ListView(
            padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
            children: [
              SurfaceCard(
                child: Row(
                  children: [
                    const Icon(Icons.fingerprint,
                        color: CuyCashColors.primaryContainer),
                    const SizedBox(width: CuyCashSpacing.stackSm + 4),
                    Expanded(
                      child: Text(l10n.biometricSettingsSwitch,
                          style: CuyCashTypography.labelMd),
                    ),
                    Switch(
                      value: state.enabled,
                      onChanged: listo && (state.available || state.enabled)
                          ? (on) => bloc.add(on
                              ? const BiometricSettingsEvent.enableRequested()
                              : const BiometricSettingsEvent.disableRequested())
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CuyCashSpacing.stackMd),
              InfoStrip(
                icon: Icons.info_outline,
                text: state.available || state.status ==
                        BiometricSettingsStatus.loading
                    ? l10n.biometricSettingsBody
                    : l10n.biometricSettingsUnavailable,
              ),
              if (state.error == BiometricSettingsError.generic) ...[
                const SizedBox(height: CuyCashSpacing.stackSm),
                Text(l10n.errorGeneric,
                    style: CuyCashTypography.bodyMd
                        .copyWith(color: CuyCashColors.error)),
              ],
            ],
          ),
        );
      },
    );
  }
}
```

Con la huella encendida y el sensor ya no disponible, el interruptor sigue habilitado para **apagarla** (`state.enabled`), pero no para volver a encenderla.

- [ ] **Step 6: Wire route and tile**

`router.dart`:

```dart
      GoRoute(
        path: AppRoutes.perfilBiometria,
        builder: (context, state) => BlocProvider(
          create: (_) => BiometricSettingsBloc(
            enable: SecurityModule.enableBiometric(deps),
            disable: SecurityModule.disableBiometric(deps),
            device: DeviceModule.create(deps),
          )..add(const BiometricSettingsEvent.started()),
          child: BiometricSettingsScreen(
            onLocked: (until) => _cerrarPorBloqueo(context, authBloc, until),
          ),
        ),
      ),
```

`profile_screen.dart`: tile `profileItemBiometrics` → `onTap: () => context.push(AppRoutes.perfilBiometria),`. Tras este cambio, `_notYet` queda usado solo por "Ayuda": dejarlo así.

- [ ] **Step 7: Run tests and analyze**

Run: `cd apps/mobile && flutter test && cd ../.. && flutter analyze`
Expected: PASS, `No issues found!`.

- [ ] **Step 8: Commit**

```bash
git add apps/mobile/lib apps/mobile/test
git commit -m "feat(app): activar y desactivar el acceso biométrico"
```

---

### Task 15: App — huella real en el acceso rápido

**Files:**
- Modify: `apps/mobile/lib/presentation/quick_access/bloc/quick_access_bloc.dart`, `quick_access_state.dart`, `quick_access_event.dart`, `quick_access_screen.dart`
- Modify: `router.dart:187-191`, `app_es.arb`
- Test: `apps/mobile/test/presentation/quick_access/quick_access_screen_test.dart` (y el test del bloc si existe: `grep -rln QuickAccessBloc apps/mobile/test`)

**Interfaces:**
- Consumes: `BiometricSignInUseCase.canUse/call`.
- Produces: `QuickAccessBloc({..., required BiometricSignInUseCase biometric})`; evento nuevo `QuickAccessEvent.started()`; `QuickAccessEvent.biometric({required String reason})` reemplaza al evento sin argumentos; estado gana `bool biometricAvailable` (default `false`) y `bool biometricRevoked` (default `false`).

Reglas:
- `started` → `biometricAvailable = await biometric.canUse()`.
- `biometric(reason)` ignorado si `status == verifying` o `!biometricAvailable`. Emite `verifying` y llama `biometric(dni: user.dni, reason:)`:
  - `Success` → `resetLockout()` (la sesión llega por el stream).
  - `Cancelled`/`Failed` → `idle`, sin cambios.
  - `Unavailable` → `idle`, `biometricAvailable: false`.
  - `Revoked` → `idle`, `biometricAvailable: false`, `biometricRevoked: true`.
  - `Locked(until)` → `idle`, `lockedUntil: until` (la pantalla ya navega a `/bloqueado`).
- Se borra la sesión simulada `'mem-…'` de `_onBiometric`.

- [ ] **Step 1: ARB**

```json
  "quickAccessBiometricReason": "Confirma que eres tú para entrar a CuyCash",
  "quickAccessBiometricRevoked": "Tu acceso con huella ya no es válido. Entra con tu PIN y vuelve a activarlo desde tu perfil.",
```

Run: `cd apps/mobile && flutter gen-l10n`

- [ ] **Step 2: Write the failing tests**

En `test/presentation/quick_access/quick_access_screen_test.dart`, construir el bloc con un `BiometricSignInUseCase` armado sobre `MemoryAuthRepository(security: estado)`, `MemoryBiometricGate` y el `MemoryDeviceStore` del test, y añadir:

```dart
  testWidgets('sin credencial guardada no hay botón de huella',
      (tester) async {
    await pumpQuickAccess(tester); // helper existente o nuevo del archivo
    expect(find.byIcon(Icons.fingerprint), findsNothing);
    expect(find.text('0'), findsOneWidget); // el teclado sigue ahí
  });

  testWidgets('con credencial y sensor, la huella abre sesión',
      (tester) async {
    estado.credentials['ok'] = estado.thisDeviceId;
    await store.saveBiometricCredential('ok');
    await pumpQuickAccess(tester);

    await tester.tap(find.byIcon(Icons.fingerprint));
    await tester.pumpAndSettle();

    expect(auth.currentSession?.identifier, estado.dni);
  });

  testWidgets('con credencial pero sin huellas en el sistema, sin botón',
      (tester) async {
    estado.credentials['ok'] = estado.thisDeviceId;
    await store.saveBiometricCredential('ok');
    gate.available = false;
    await pumpQuickAccess(tester);

    expect(find.byIcon(Icons.fingerprint), findsNothing);
  });

  testWidgets('credencial revocada: la borra, oculta el botón y avisa',
      (tester) async {
    await store.saveBiometricCredential('vieja');
    await pumpQuickAccess(tester);

    await tester.tap(find.byIcon(Icons.fingerprint));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.fingerprint), findsNothing);
    expect(find.textContaining('Tu acceso con huella ya no es válido'),
        findsOneWidget);
    expect(await store.readBiometricCredential(), isNull);
  });
```

`pumpQuickAccess` debe usar el `MemoryDeviceStore` (`store`), `MemoryBiometricGate` (`gate`), `MemorySecurityState` (`estado`) y `MemoryAuthRepository(security: estado)` (`auth`) creados en `setUp`, con un `RememberedUser` de DNI `estado.dni`. Leer el archivo actual y adaptar su `setUp` y su helper, sin borrar los tests de PIN que ya tiene.

Confirmar en `packages/design_system/lib/src/pin_keypad.dart` el ícono de `_biometricKey` (`Icons.fingerprint` u otro) y usar ese en los `find.byIcon`.

- [ ] **Step 3: Run tests to verify they fail**

Run: `cd apps/mobile && flutter test test/presentation/quick_access`
Expected: FAIL.

- [ ] **Step 4: Implement**

`quick_access_event.dart`:

```dart
  const factory QuickAccessEvent.started() = QuickAccessStarted;
  const factory QuickAccessEvent.biometric({required String reason}) =
      QuickAccessBiometric;
```

`quick_access_state.dart`, nuevos campos:

```dart
    /// Hay credencial guardada y el sistema puede pedir la huella.
    @Default(false) bool biometricAvailable,

    /// El servidor rechazó la credencial: se borró y hay que entrar con PIN.
    @Default(false) bool biometricRevoked,
```

`quick_access_bloc.dart`: constructor con `required BiometricSignInUseCase biometric,` guardado en `_biometric`; registrar `on<QuickAccessStarted>` y reemplazar `_onBiometric`:

```dart
  Future<void> _onStarted(
    QuickAccessStarted event,
    Emitter<QuickAccessState> emit,
  ) async {
    emit(state.copyWith(biometricAvailable: await _biometric.canUse()));
  }

  Future<void> _onBiometric(
    QuickAccessBiometric event,
    Emitter<QuickAccessState> emit,
  ) async {
    if (state.status == QuickAccessStatus.verifying ||
        !state.biometricAvailable) {
      return;
    }
    emit(state.copyWith(status: QuickAccessStatus.verifying, lastWrong: false));
    final resultado =
        await _biometric(dni: state.user.dni, reason: event.reason);
    switch (resultado) {
      case BiometricSignInSuccess():
        await _device.resetLockout();
        emit(state.copyWith(status: QuickAccessStatus.idle));
      case BiometricSignInCancelled() || BiometricSignInFailed():
        emit(state.copyWith(status: QuickAccessStatus.idle));
      case BiometricSignInUnavailable():
        emit(state.copyWith(
            status: QuickAccessStatus.idle, biometricAvailable: false));
      case BiometricSignInRevoked():
        emit(state.copyWith(
          status: QuickAccessStatus.idle,
          biometricAvailable: false,
          biometricRevoked: true,
        ));
      case BiometricSignInLocked(:final until):
        emit(state.copyWith(status: QuickAccessStatus.idle, lockedUntil: until));
    }
  }
```

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs`

`quick_access_screen.dart`:
- `onBiometric: state.biometricAvailable ? () => bloc.add(QuickAccessEvent.biometric(reason: l10n.quickAccessBiometricReason)) : null,`
- Tras el bloque de `state.lastWrong`:

```dart
                  if (state.biometricRevoked)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CuyCashSpacing.marginMobile,
                      ),
                      child: InfoStrip(
                        icon: Icons.fingerprint,
                        text: l10n.quickAccessBiometricRevoked,
                      ),
                    ),
```

`router.dart`, en la construcción del `QuickAccessBloc`: `biometric: SecurityModule.biometricSignIn(deps),` y `..add(const QuickAccessEvent.started())`.

- [ ] **Step 5: Run tests and analyze**

Run: `cd apps/mobile && flutter test && cd ../.. && flutter analyze`
Expected: PASS, `No issues found!`.

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib apps/mobile/test
git commit -m "feat(app): la huella del acceso rápido abre una sesión real"
```

---

### Task 16: App — activar la huella al terminar el registro

**Files:**
- Modify: `apps/mobile/lib/presentation/register/bloc/register_bloc.dart`, `register_state.dart`, `register_event.dart`, `widgets/register_biometric_step.dart`, `apps/mobile/lib/core/injection/modules/register_module.dart`, `app_es.arb`
- Test: `apps/mobile/test/presentation/register/` (el test del bloc existente; buscar con `grep -rln RegisterBloc apps/mobile/test`)

**Interfaces:**
- Consumes: `EnableBiometricUseCase`.
- Produces: `RegisterBloc(AuthActions actions, {required EnableBiometricUseCase biometric})`; evento `RegisterEvent.biometricChecked()` despachado al crear el bloc; `RegisterState.biometricAvailable: bool` (default `false`) y `biometricEnrollFailed: bool` (default `false`); `RegisterEvent.accountOpened({required String biometricReason})` reemplaza al evento sin argumentos.

Reglas:
- `biometricChecked`: `available = await biometric.isAvailable()`; si es `false`, también `draft.biometricEnabled = false`.
- El paso 4C solo muestra el `Switch` si `state.biometricAvailable`.
- `accountOpened(reason)`: tras `activate` con éxito, si `draft.biometricEnabled && biometricAvailable`, llama `biometric(pin: draft.pin, reason:)`. Cualquier `left` → `biometricEnrollFailed: true`; nunca revierte el alta. `right(false)` (canceló) no es fallo.
- Orden: `activate` primero (el token ya existe tras `register`), luego `enroll`. La activación emite la sesión y el router navega al inicio; `enroll` corre igual porque el bloc sigue vivo hasta que la ruta se desmonta. Si el bloc se cierra antes, el `emit` posterior fallaría: proteger con `if (isClosed) return;` antes de cada `emit` posterior a un `await`.

Si `biometricEnrollFailed`, la pantalla de éxito del registro (la que dispara `accountOpened`) muestra `registerBiometricLater` en un `SnackBar` antes de salir. Si la navegación ya ocurrió, el aviso se pierde: es aceptable, porque el perfil muestra el estado real del interruptor.

- [ ] **Step 1: ARB**

```json
  "registerBiometricLater": "No pudimos activar tu huella. Puedes hacerlo desde tu perfil, en Acceso biométrico.",
  "registerBiometricReason": "Confirma tu huella o rostro para entrar más rápido a CuyCash",
```

Run: `cd apps/mobile && flutter gen-l10n`

- [ ] **Step 2: Write the failing tests**

En el test existente del `RegisterBloc`, construir con `biometric: EnableBiometricUseCase(repo: MemorySecurityRepository(estado, clock: DateTime.now), gate: gate, store: store)` y añadir:

```dart
  blocTest<RegisterBloc, RegisterState>(
    'sin sensor apaga la opción de huella',
    build: () {
      gate.available = false;
      return construirBloc();
    },
    act: (b) => b.add(const RegisterEvent.biometricChecked()),
    verify: (b) {
      expect(b.state.biometricAvailable, isFalse);
      expect(b.state.draft.biometricEnabled, isFalse);
    },
  );

  test('al abrir la cuenta con la huella encendida, la activa', () async {
    final b = construirBloc()..add(const RegisterEvent.biometricChecked());
    await recorrerHastaCrearCuenta(b, pin: '000000');

    b.add(const RegisterEvent.accountOpened(biometricReason: 'r'));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(await store.readBiometricCredential(), isNotNull);
    expect(b.state.biometricEnrollFailed, isFalse);
    await b.close();
  });

  test('si activar la huella falla, el alta sigue y se avisa', () async {
    store.failCredentialWrites = true;
    final b = construirBloc()..add(const RegisterEvent.biometricChecked());
    await recorrerHastaCrearCuenta(b, pin: '000000');

    b.add(const RegisterEvent.accountOpened(biometricReason: 'r'));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(b.state.biometricEnrollFailed, isTrue);
    expect(auth.currentSession, isNotNull);
    await b.close();
  });
```

`construirBloc` y `recorrerHastaCrearCuenta` son helpers del archivo de test: leer cómo el test actual llega a `createdSession` (eventos de datos, captura, PIN y `submitted`) y extraer esa secuencia a `recorrerHastaCrearCuenta(RegisterBloc b, {required String pin})`. El `MemorySecurityState.demo` usa PIN `000000`, el mismo que el `MemoryAuthRepository(security: estado)` del test. El PIN del alta (`000000`) no pasa `PinRules`, pero el `MemoryAuthRepository.register` solo exige 6 dígitos: si el wizard real lo bloquea por las reglas, usar `839201` y crear el estado con `MemorySecurityState.demo(clock: DateTime.now, pin: '839201')`.

- [ ] **Step 3: Run tests to verify they fail**

Run: `cd apps/mobile && flutter test test/presentation/register`
Expected: FAIL.

- [ ] **Step 4: Implement**

- `register_event.dart`: `const factory RegisterEvent.biometricChecked() = RegisterBiometricChecked;` y cambiar `accountOpened` a `const factory RegisterEvent.accountOpened({required String biometricReason}) = RegisterAccountOpened;`.
- `register_state.dart`: `@Default(false) bool biometricAvailable,` y `@Default(false) bool biometricEnrollFailed,`.
- `register_bloc.dart`: constructor `RegisterBloc(AuthActions actions, {required EnableBiometricUseCase biometric})`, guardado en `_biometric`;

```dart
    on<RegisterBiometricChecked>((event, emit) async {
      final available = await _biometric.isAvailable();
      if (isClosed) return;
      emit(state.copyWith(
        biometricAvailable: available,
        draft: available
            ? state.draft
            : state.draft.copyWith(biometricEnabled: false),
      ));
    });
    on<RegisterAccountOpened>((event, emit) async {
      final session = state.createdSession;
      if (session == null) return;
      final resultado = await _actions.activate(session);
      if (resultado.isLeft()) {
        resultado.match(
          (failure) => emit(state.copyWith(submitError: _errorFor(failure))),
          (_) => null,
        );
        return;
      }
      if (!state.draft.biometricEnabled || !state.biometricAvailable) return;
      final huella = await _biometric(
          pin: state.draft.pin, reason: event.biometricReason);
      if (isClosed) return;
      if (huella.isLeft()) emit(state.copyWith(biometricEnrollFailed: true));
    });
```

  (borrar el handler anterior de `RegisterAccountOpened`).
- `register_module.dart`: `RegisterBloc(AuthActions(deps.authRepository), biometric: SecurityModule.enableBiometric(deps))..add(const RegisterEvent.biometricChecked())`.
- `register_biometric_step.dart`: envolver la fila del `Switch` (línea ~82) en `if (state.biometricAvailable)`.
- Donde se despacha `RegisterEvent.accountOpened()` (buscar con `grep -rn "accountOpened" apps/mobile/lib`): pasar `biometricReason: l10n.registerBiometricReason`, y en esa pantalla añadir un `BlocListener` con `listenWhen: (p, c) => !p.biometricEnrollFailed && c.biometricEnrollFailed` que muestre `l10n.registerBiometricLater` en un `SnackBar`.

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Run tests and analyze**

Run: `cd apps/mobile && flutter test && cd ../.. && flutter analyze`
Expected: PASS, `No issues found!`.

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib apps/mobile/test
git commit -m "feat(app): el registro activa la huella si quedó encendida"
```

---

### Task 17: Documentación y verificación final

**Files:**
- Modify: `CLAUDE.md`, `docs/modelo-datos.md`, `docs/verificacion-manual.md`

- [ ] **Step 1: CLAUDE.md**

En "Lo implementado hoy", añadir a la lista:

```markdown
- Perfil: datos personales (solo lectura), alias, cambio de PIN con sesión
  abierta (cierra los otros teléfonos), dispositivos vinculados y acceso
  biométrico real: la huella libera una credencial emitida por el servidor
  (`/v1/auth/sessions/biometric`), revocable al desvincular o cambiar el PIN.
```

En "Features actuales", añadir `profile`, `security`, `biometric`. En "SLA comprometidos", tras la línea de autenticación biométrica: "La huella usa una sola petición con SHA-256; **sin medición automatizada** del 1.5 s." Añadir a "Lo que no se ha comprobado": "El diálogo real de `local_auth` (Android/iOS) no se ha probado en un teléfono; los tests usan `MemoryBiometricGate`."

- [ ] **Step 2: docs/modelo-datos.md**

Documentar `devices.nombre`, `devices.plataforma` y la tabla `biometric_credentials` (columnas, y que revocar es poner `revoked_at`), siguiendo el formato de las tablas ya descritas en ese archivo. Añadir la nota de que esas columnas exigen `scripts/reset_schema.py` en bases creadas antes.

- [ ] **Step 3: docs/verificacion-manual.md**

Añadir una sección "Perfil y huella (no ejecutado)" con estos pasos, marcados como inferidos del código:
1. Perfil → Datos personales: ver nombres, DNI y correo enmascarado.
2. Editar alias a `prueba_01`: el saludo del inicio cambia.
3. Cambiar PIN: `PIN actual → nuevo → confirmar`; salir y entrar con el nuevo.
4. Acceso biométrico: encender (PIN + huella del sistema); cerrar la app y entrar con la huella desde el acceso rápido.
5. Desde un segundo teléfono vinculado, desvincular el primero: el primero vuelve al login y su huella deja de funcionar (aviso "Tu acceso con huella ya no es válido").
6. Cambiar el PIN desde el segundo teléfono: la huella del primero deja de funcionar.

- [ ] **Step 4: Full verification**

Run:
```bash
cd services/api && .venv/bin/python -m pytest -q
cd ../.. && flutter analyze && flutter test
```
Expected: backend todo PASS; `No issues found!`; app todo PASS.

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md docs/modelo-datos.md docs/verificacion-manual.md
git commit -m "docs: perfil, huella y dispositivos en CLAUDE.md, modelo de datos y guion manual"
```
