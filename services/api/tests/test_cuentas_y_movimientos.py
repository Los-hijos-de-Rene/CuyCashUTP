"""
HU05: consulta de saldos y movimientos, < 1 s.

La paginación es por CURSOR y no por offset: con offset, un movimiento nuevo
mientras el usuario hace scroll duplica o salta filas.

Los movimientos se siembran a mano con `db_de_client`: el motor que los crea
(`ledger.post`) y los endpoints que lo usan son de tareas posteriores, y estas
pruebas cubren solo la LECTURA.
"""

from datetime import datetime, timedelta, timezone

from sqlalchemy import select

from app.db.models import Account, LedgerEntry, Transaction, Transfer

BASE = datetime(2026, 10, 1, 12, 0, 0, tzinfo=timezone.utc)


async def _cuenta_id(client, titular) -> str:
    r = await client.get("/v1/accounts", headers=titular.auth)
    return r.json()["cuentas"][0]["id"]


async def _sembrar(db, cuenta_id, *, n, contraparte_id=None, desde=0, mismo_instante=False):
    """
    Inserta `n` movimientos de la cuenta; devuelve los transaction_id en orden
    de creación. Cada uno es un crédito de 1000 céntimos más su índice.

    Con `contraparte_id` es una transferencia recibida (con su fila Transfer);
    sin él, una recarga. Con `mismo_instante`, todos comparten `created_at`,
    para forzar que el desempate por id sea lo único que los ordene.
    """
    ids = []
    for i in range(desde, desde + n):
        momento = BASE if mismo_instante else BASE + timedelta(minutes=i)
        tx = Transaction(
            tipo="transferencia" if contraparte_id else "recarga",
            idempotency_key=f"sem-{cuenta_id[:8]}-{i}",
            created_at=momento,
        )
        db.add(tx)
        await db.flush()
        db.add(
            LedgerEntry(
                transaction_id=tx.id,
                account_id=cuenta_id,
                direccion="credito",
                monto=1000 + i,
                saldo_posterior=1000 + i,
                created_at=momento,
            )
        )
        if contraparte_id:
            db.add(
                Transfer(
                    transaction_id=tx.id,
                    cuenta_origen=contraparte_id,
                    cuenta_destino=cuenta_id,
                    monto=1000 + i,
                    motivo="Almuerzo",
                )
            )
        ids.append(tx.id)
    await db.commit()
    return ids


async def _recorrer(client, titular, cuenta_id, limit):
    """Sigue next_cursor hasta el final; devuelve las páginas."""
    paginas, cursor = [], None
    for _ in range(50):  # tope: un cursor que no avanza no debe colgar el test
        url = f"/v1/accounts/{cuenta_id}/movements?limit={limit}"
        if cursor:
            url += f"&cursor={cursor}"
        r = await client.get(url, headers=titular.auth)
        assert r.status_code == 200, r.text
        paginas.append(r.json()["movimientos"])
        cursor = r.json()["next_cursor"]
        if cursor is None:
            return paginas
    raise AssertionError("el cursor nunca terminó")


async def test_solo_devuelve_las_cuentas_propias(
    client, otp_codes, registrado, otro_registrado
):
    r = await client.get("/v1/accounts", headers=registrado.auth)
    numeros = [c["numero"] for c in r.json()["cuentas"]]

    otra = await client.get("/v1/accounts", headers=otro_registrado.auth)
    numeros_ajenos = [c["numero"] for c in otra.json()["cuentas"]]

    assert len(numeros) == 1 and len(numeros_ajenos) == 1
    assert set(numeros).isdisjoint(numeros_ajenos)


async def test_el_historial_de_una_cuenta_ajena_responde_404(
    client, otp_codes, registrado, otro_registrado
):
    """No 403: confirmar que la cuenta existe ya es filtrar información."""
    ajena_id = await _cuenta_id(client, otro_registrado)

    r = await client.get(f"/v1/accounts/{ajena_id}/movements", headers=registrado.auth)
    assert r.status_code == 404
    assert r.json()["code"] == "ACCOUNT_NOT_FOUND"

    # Idéntico a una cuenta que no existe: no hay forma de distinguirlas.
    inexistente = await client.get(
        "/v1/accounts/no-existe/movements", headers=registrado.auth
    )
    assert inexistente.status_code == 404
    assert inexistente.json() == r.json()


async def test_las_rutas_de_consulta_exigen_sesion(client):
    for ruta in ("/v1/accounts", "/v1/accounts/x/movements", "/v1/movements/x"):
        r = await client.get(ruta)
        assert r.status_code == 401, ruta
        assert r.json()["code"] == "UNAUTHENTICATED"


async def test_una_cuenta_recien_abierta_no_tiene_movimientos(
    client, otp_codes, registrado
):
    cuenta_id = await _cuenta_id(client, registrado)

    r = await client.get(f"/v1/accounts/{cuenta_id}/movements", headers=registrado.auth)
    assert r.status_code == 200
    assert r.json() == {"movimientos": [], "next_cursor": None}


async def test_un_cursor_corrupto_no_rompe_la_pantalla(client, otp_codes, registrado):
    """Un cursor que no se puede leer devuelve la primera página, no un 500."""
    cuenta_id = await _cuenta_id(client, registrado)

    r = await client.get(
        f"/v1/accounts/{cuenta_id}/movements?cursor=basura",
        headers=registrado.auth,
    )
    assert r.status_code == 200


async def test_un_cursor_corrupto_equivale_a_no_mandar_cursor(
    client, otp_codes, registrado, db_de_client
):
    cuenta_id = await _cuenta_id(client, registrado)
    await _sembrar(db_de_client, cuenta_id, n=3)

    sin = await client.get(f"/v1/accounts/{cuenta_id}/movements", headers=registrado.auth)
    for malo in ("basura", "AAAA", "%20"):
        con = await client.get(
            f"/v1/accounts/{cuenta_id}/movements?cursor={malo}", headers=registrado.auth
        )
        assert con.status_code == 200
        assert con.json() == sin.json()


async def test_la_paginacion_recorre_tres_paginas_sin_repetir_ni_saltar(
    client, otp_codes, registrado, db_de_client
):
    """
    7 movimientos con limit=3 -> páginas de 3, 3 y 1. Una sola página no
    prueba nada: el fallo de un cursor está en el borde entre páginas.
    """
    cuenta_id = await _cuenta_id(client, registrado)
    ids = await _sembrar(db_de_client, cuenta_id, n=7)

    paginas = await _recorrer(client, registrado, cuenta_id, limit=3)

    assert [len(p) for p in paginas] == [3, 3, 1]
    vistos = [m["transaction_id"] for p in paginas for m in p]
    # Del más reciente al más antiguo, todos, una sola vez cada uno.
    assert vistos == list(reversed(ids))
    montos = [m["monto"] for p in paginas for m in p]
    assert montos == [1006, 1005, 1004, 1003, 1002, 1001, 1000]
    assert all(isinstance(m, int) for m in montos)


async def test_la_ultima_pagina_exacta_no_anuncia_otra(
    client, otp_codes, registrado, db_de_client
):
    """6 movimientos con limit=3: dos páginas y la segunda ya sin cursor."""
    cuenta_id = await _cuenta_id(client, registrado)
    await _sembrar(db_de_client, cuenta_id, n=6)

    paginas = await _recorrer(client, registrado, cuenta_id, limit=3)
    assert [len(p) for p in paginas] == [3, 3]


async def test_con_el_mismo_instante_el_cursor_desempata_por_id(
    client, otp_codes, registrado, db_de_client
):
    """
    Movimientos con idéntico created_at: solo el id los ordena. Si el cursor
    comparara únicamente la fecha, el borde de página repetiría o saltaría.
    """
    cuenta_id = await _cuenta_id(client, registrado)
    ids = await _sembrar(db_de_client, cuenta_id, n=8, mismo_instante=True)

    paginas = await _recorrer(client, registrado, cuenta_id, limit=3)

    vistos = [m["transaction_id"] for p in paginas for m in p]
    assert [len(p) for p in paginas] == [3, 3, 2]
    assert len(vistos) == len(set(vistos)) == 8
    assert set(vistos) == set(ids)


async def test_un_movimiento_nuevo_durante_el_scroll_no_duplica_ni_salta(
    client, otp_codes, registrado, db_de_client
):
    """La razón de ser del cursor frente al offset."""
    cuenta_id = await _cuenta_id(client, registrado)
    ids = await _sembrar(db_de_client, cuenta_id, n=6)

    primera = await client.get(
        f"/v1/accounts/{cuenta_id}/movements?limit=3", headers=registrado.auth
    )
    cursor = primera.json()["next_cursor"]

    # Llega un movimiento nuevo (el más reciente) entre página y página.
    await _sembrar(db_de_client, cuenta_id, n=1, desde=100)

    segunda = await client.get(
        f"/v1/accounts/{cuenta_id}/movements?limit=3&cursor={cursor}",
        headers=registrado.auth,
    )
    pedidos = [m["transaction_id"] for m in segunda.json()["movimientos"]]
    assert pedidos == list(reversed(ids))[3:]


async def test_el_limite_fuera_de_rango_se_rechaza(client, otp_codes, registrado):
    cuenta_id = await _cuenta_id(client, registrado)
    for limite in (0, 51):
        r = await client.get(
            f"/v1/accounts/{cuenta_id}/movements?limit={limite}", headers=registrado.auth
        )
        assert r.status_code == 422


async def test_el_historial_trae_el_nombre_completo_de_la_contraparte(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    mia = await _cuenta_id(client, registrado)
    suya = await _cuenta_id(client, otro_registrado)
    await _sembrar(db_de_client, mia, n=1, contraparte_id=suya)

    r = await client.get(f"/v1/accounts/{mia}/movements", headers=registrado.auth)
    mov = r.json()["movimientos"][0]

    # Completo, sin enmascarar: el enmascarado es del directorio (tarea 8).
    assert mov["contraparte"] == "Luis Alberto Quispe"
    assert mov["motivo"] == "Almuerzo"
    assert mov["tipo"] == "transferencia"
    assert mov["direccion"] == "credito"
    assert mov["monto"] == 1000
    assert mov["saldo_posterior"] == 1000


async def test_una_recarga_se_muestra_como_recarga_de_saldo(
    client, otp_codes, registrado, db_de_client
):
    cuenta_id = await _cuenta_id(client, registrado)
    await _sembrar(db_de_client, cuenta_id, n=1)

    r = await client.get(f"/v1/accounts/{cuenta_id}/movements", headers=registrado.auth)
    mov = r.json()["movimientos"][0]
    assert mov["tipo"] == "recarga"
    assert mov["contraparte"] == "Recarga de saldo"
    assert mov["motivo"] is None


async def test_el_historial_no_mezcla_movimientos_de_otras_cuentas(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    mia = await _cuenta_id(client, registrado)
    suya = await _cuenta_id(client, otro_registrado)
    await _sembrar(db_de_client, mia, n=2)
    await _sembrar(db_de_client, suya, n=5)

    r = await client.get(f"/v1/accounts/{mia}/movements", headers=registrado.auth)
    assert len(r.json()["movimientos"]) == 2


async def test_la_ficha_de_un_movimiento_propio(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    mia = await _cuenta_id(client, registrado)
    suya = await _cuenta_id(client, otro_registrado)
    [tx_id] = await _sembrar(db_de_client, mia, n=1, contraparte_id=suya)

    r = await client.get(f"/v1/movements/{tx_id}", headers=registrado.auth)
    assert r.status_code == 200
    cuerpo = r.json()
    assert cuerpo["transaction_id"] == tx_id
    assert cuerpo["contraparte"] == "Luis Alberto Quispe"

    # Se enmascara el número de la cuenta destino (la propia, en este asiento).
    numero = (
        await db_de_client.execute(select(Account.numero).where(Account.id == mia))
    ).scalar_one()
    assert cuerpo["cuenta_destino_masked"] == f"••••{numero[-4:]}"
    assert numero not in str(cuerpo)


async def test_la_ficha_de_una_recarga_no_trae_cuenta_destino(
    client, otp_codes, registrado, db_de_client
):
    cuenta_id = await _cuenta_id(client, registrado)
    [tx_id] = await _sembrar(db_de_client, cuenta_id, n=1)

    r = await client.get(f"/v1/movements/{tx_id}", headers=registrado.auth)
    assert r.status_code == 200
    assert "cuenta_destino_masked" not in r.json()


async def test_la_ficha_de_un_movimiento_ajeno_responde_404(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    """404 y no 403: distinguirlos confirmaría que la transacción existe."""
    suya = await _cuenta_id(client, otro_registrado)
    [tx_ajena] = await _sembrar(db_de_client, suya, n=1)

    ajeno = await client.get(f"/v1/movements/{tx_ajena}", headers=registrado.auth)
    inexistente = await client.get("/v1/movements/no-existe", headers=registrado.auth)

    assert ajeno.status_code == inexistente.status_code == 404
    assert ajeno.json()["code"] == "MOVEMENT_NOT_FOUND"
    assert ajeno.json() == inexistente.json()


async def test_el_emisor_tambien_ve_la_ficha_de_su_transferencia(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    """Una transferencia toca dos cuentas: ambos titulares la ven; un tercero, no."""
    mia = await _cuenta_id(client, registrado)
    suya = await _cuenta_id(client, otro_registrado)
    [tx_id] = await _sembrar(db_de_client, mia, n=1, contraparte_id=suya)
    # El asiento de débito de la contraparte (emisor).
    db_de_client.add(
        LedgerEntry(
            transaction_id=tx_id, account_id=suya, direccion="debito",
            monto=1000, saldo_posterior=0, created_at=BASE,
        )
    )
    await db_de_client.commit()

    emisor = await client.get(f"/v1/movements/{tx_id}", headers=otro_registrado.auth)
    assert emisor.status_code == 200
    assert emisor.json()["direccion"] == "debito"
    assert emisor.json()["contraparte"] == "Jenny Marisol Ruiz"
