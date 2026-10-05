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
from app.db.base import get_session
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


async def test_ausente_inventado_y_vencido_responden_exactamente_igual(
    sonda, registrado
):
    # Si se distinguieran, quien sondea sabría qué tokens existieron.
    async for db in app.dependency_overrides[get_session]():
        await db.execute(
            update(SessionRow).values(expires_at=utcnow() - timedelta(seconds=1))
        )
        await db.commit()

    ausente = await sonda.get("/protegida")
    inventado = await sonda.get("/protegida", headers={"Authorization": "Bearer x"})
    vencido = await sonda.get("/protegida", headers=registrado.auth)

    assert ausente.status_code == inventado.status_code == vencido.status_code == 401
    assert ausente.json() == inventado.json() == vencido.json()
    assert ausente.json()["code"] == "UNAUTHENTICATED"


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
