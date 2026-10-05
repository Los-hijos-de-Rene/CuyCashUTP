"""
La dependencia que protege todo lo que mueve dinero.

Vive en un solo sitio a propósito: repetida en cada router, el día que alguien
añada una ruta se olvidará de ponerla, y esa ruta quedará abierta.
"""

from datetime import timedelta

import pytest
from fastapi import Depends, FastAPI
from httpx import ASGITransport, AsyncClient
from sqlalchemy import update

from app.core.deps import current_user
from app.core.errors import ApiError
from app.db.models import Session as SessionRow
from app.db.models import User, utcnow
from app.main import api_error_handler, app


@pytest.fixture
async def sonda(client):
    """
    Una ruta mínima protegida con `current_user`, sobre la misma base de `client`.

    Prueba la dependencia ya, sin esperar a que existan los routers de dinero.
    """
    probe = FastAPI()
    probe.add_exception_handler(ApiError, api_error_handler)

    @probe.get("/protegida")
    async def protegida(user: User = Depends(current_user)):
        return {"id": user.id}

    probe.dependency_overrides.update(app.dependency_overrides)
    async with AsyncClient(transport=ASGITransport(app=probe), base_url="http://test") as c:
        yield c


async def test_sin_cabecera_responde_401(sonda):
    r = await sonda.get("/protegida")
    assert r.status_code == 401
    assert r.json()["code"] == "UNAUTHENTICATED"


async def test_con_token_inventado_responde_401(sonda):
    r = await sonda.get("/protegida", headers={"Authorization": "Bearer inventado"})
    assert r.status_code == 401
    assert r.json()["code"] == "UNAUTHENTICATED"


@pytest.mark.xfail(reason="/v1/accounts llega en la Tarea 5")
async def test_con_token_valido_devuelve_el_usuario(client, registrado):
    r = await client.get("/v1/accounts", headers=registrado.auth)
    assert r.status_code == 200


async def test_la_sonda_acepta_un_token_valido(sonda, registrado):
    r = await sonda.get("/protegida", headers=registrado.auth)
    assert r.status_code == 200
    assert r.json()["id"] == registrado.user_id


async def test_los_casos_de_401_responden_exactamente_igual(
    client, sonda, registrado, otro_registrado, db_de_client
):
    # Si se distinguieran desde fuera, quien sondea sabría qué tokens existieron.
    # Vencido: la sesión de `registrado`.
    await db_de_client.execute(
        update(SessionRow)
        .where(SessionRow.user_id == registrado.user_id)
        .values(expires_at=utcnow() - timedelta(seconds=1))
    )
    await db_de_client.commit()
    # Revocado: la de `otro_registrado`, por el endpoint real.
    salir = await client.delete("/v1/auth/sessions/current", headers=otro_registrado.auth)
    assert salir.status_code == 204

    ausente = await sonda.get("/protegida")
    inventado = await sonda.get("/protegida", headers={"Authorization": "Bearer x"})
    vencido = await sonda.get("/protegida", headers=registrado.auth)
    revocado = await sonda.get("/protegida", headers=otro_registrado.auth)

    respuestas = [ausente, inventado, vencido, revocado]
    assert {r.status_code for r in respuestas} == {401}
    assert all(r.json() == ausente.json() for r in respuestas)
    assert ausente.json()["code"] == "UNAUTHENTICATED"

    # Caso "usuario borrado" (rama `user is None` de `current_user`): NO se
    # prueba a propósito. En producción (Postgres) `sessions.user_id` es una FK
    # sin ON DELETE, así que no se puede borrar un usuario con sesiones; y si se
    # borran antes las sesiones, ya no hay token que resuelva a ese usuario. La
    # rama es defensa en profundidad, inalcanzable por FK. Solo se podría
    # ejercitar aquí porque SQLite no activa `PRAGMA foreign_keys` por defecto
    # (el motor de tests no lo enciende), y ese test fingiría cubrir un
    # escenario que la base real impide.


async def test_esquema_distinto_de_bearer_o_token_vacio_responde_401(sonda, registrado):
    for cabecera in (f"Basic {registrado.token}", "Bearer ", "Bearer", registrado.token):
        r = await sonda.get("/protegida", headers={"Authorization": cabecera})
        assert r.status_code == 401, cabecera


async def test_cerrar_sesion_revoca_el_token(client, sonda, registrado):
    salir = await client.delete("/v1/auth/sessions/current", headers=registrado.auth)
    assert salir.status_code == 204

    r = await sonda.get("/protegida", headers=registrado.auth)
    assert r.status_code == 401


async def test_cerrar_sesion_sigue_siendo_idempotente_sin_token_valido(client):
    # Salir con una sesión ya muerta no debe fallar: es lo que espera la app.
    sin = await client.delete("/v1/auth/sessions/current")
    malo = await client.delete(
        "/v1/auth/sessions/current", headers={"Authorization": "Bearer inventado"}
    )
    assert sin.status_code == malo.status_code == 204


async def test_cada_token_resuelve_a_su_propio_titular(sonda, registrado, otro_registrado):
    a = await sonda.get("/protegida", headers=registrado.auth)
    b = await sonda.get("/protegida", headers=otro_registrado.auth)
    assert a.json()["id"] == registrado.user_id
    assert b.json()["id"] == otro_registrado.user_id
    assert registrado.user_id != otro_registrado.user_id
