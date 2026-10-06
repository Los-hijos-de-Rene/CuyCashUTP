from tests.test_registro_y_login import autenticar, registrar


async def test_un_telefono_barriendo_muchos_dni_termina_bloqueado(client):
    # El contador por DNI no frena esto: cada DNI empieza limpio. Es el hueco
    # que cubre el contador por dispositivo.
    for i in range(10):
        await autenticar(client, dni=f"1000000{i}", pin="999999", device="ladron")

    respuesta = await autenticar(client, dni="20000000", pin="999999", device="ladron")

    assert respuesta.status_code == 423
    assert respuesta.json()["code"] == "DEVICE_LOCKED"


async def test_el_bloqueo_de_un_telefono_no_afecta_a_otro(client):
    for i in range(10):
        await autenticar(client, dni=f"1000000{i}", pin="999999", device="ladron")

    respuesta = await autenticar(client, dni="20000000", pin="999999", device="honesto")

    assert respuesta.status_code == 401  # cuenta el intento, pero no bloquea


async def test_un_login_correcto_no_reinicia_el_contador_del_telefono(client):
    """
    La ventana es deslizante a propósito.

    Si un ingreso válido pusiera el contador a cero, bastaría con intercalar
    una entrada propia cada 9 intentos para barrer cuentas indefinidamente.
    """
    await registrar(client)
    for i in range(9):
        await autenticar(client, dni=f"1000000{i}", pin="999999", device="ladron")

    # Entrada legítima intercalada.
    assert (await autenticar(client, device="ladron")).status_code == 200

    for _ in range(2):
        respuesta = await autenticar(client, dni="20000000", pin="999999", device="ladron")

    assert respuesta.status_code == 423
    assert respuesta.json()["code"] == "DEVICE_LOCKED"


async def test_un_login_correcto_si_limpia_el_contador_del_dni(client):
    await registrar(client)
    await autenticar(client, pin="999999")
    await autenticar(client, pin="999999")

    assert (await autenticar(client)).status_code == 200

    # Con el contador limpio, dos fallos más no alcanzan para bloquear.
    await autenticar(client, pin="999999")
    respuesta = await autenticar(client, pin="999999")
    assert respuesta.status_code == 401
