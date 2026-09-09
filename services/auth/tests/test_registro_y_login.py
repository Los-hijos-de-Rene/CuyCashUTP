DNI = "12345678"
PIN = "024689"
DEVICE = "device-abc"


async def registrar(client, dni=DNI, pin=PIN, email="juan@correo.com"):
    return await client.post(
        "/v1/auth/register",
        json={
            "dni": dni,
            "nombres": "Juan Carlos",
            "apellidos": "Pérez",
            "email": email,
            "pin": pin,
        },
    )


async def autenticar(client, pin=PIN, dni=DNI, device=DEVICE):
    return await client.post(
        "/v1/auth/authenticate",
        json={"identifier": dni, "pin": pin},
        headers={"X-Device-Id": device},
    )


async def test_registro_crea_la_cuenta_pero_no_abre_sesion(client):
    respuesta = await registrar(client)

    assert respuesta.status_code == 201
    cuerpo = respuesta.json()
    assert cuerpo["alias"] == "@juan"
    # Registrarse no otorga sesión: la app la activa tras la pantalla de éxito.
    assert "session_token" not in cuerpo


async def test_el_pin_previsible_se_rechaza(client):
    respuesta = await registrar(client, pin="111111")

    assert respuesta.json()["code"] == "WEAK_PIN"


async def test_dni_repetido_se_rechaza(client):
    await registrar(client)
    respuesta = await registrar(client, email="otro@correo.com")

    assert respuesta.json()["code"] == "IDENTIFIER_TAKEN"


async def test_telefono_desconocido_exige_verificar_el_dispositivo(client):
    await registrar(client)

    respuesta = await autenticar(client)

    cuerpo = respuesta.json()
    # El PIN correcto NO basta desde un teléfono que no conocemos.
    assert cuerpo["result"] == "device_verification_required"
    assert cuerpo["masked_email"] == "j•••••@correo.com"
    assert "session_token" not in cuerpo


async def test_el_error_no_distingue_dni_inexistente_de_pin_equivocado(client):
    await registrar(client)

    pin_malo = await autenticar(client, pin="999999")
    dni_inexistente = await autenticar(client, dni="87654321", pin=PIN)

    # Mismo código, mismo estado y mismo texto: decir cuál falló permitiría
    # averiguar qué DNI están registrados.
    assert pin_malo.status_code == dni_inexistente.status_code == 401
    assert pin_malo.json()["code"] == dni_inexistente.json()["code"] == "INVALID_CREDENTIALS"
    assert pin_malo.json()["detail"] == dni_inexistente.json()["detail"]


async def test_el_contador_corre_igual_para_un_dni_que_no_existe(client):
    # Si solo contara para cuentas reales, el propio bloqueo delataría cuáles
    # lo son.
    for _ in range(3):
        respuesta = await autenticar(client, dni="99999999", pin="999999")

    assert respuesta.status_code == 423
    assert respuesta.json()["code"] == "IDENTIFIER_LOCKED"


async def test_tres_fallos_bloquean_el_dni_y_ni_el_pin_correcto_entra(client):
    await registrar(client)
    for _ in range(3):
        await autenticar(client, pin="999999")

    respuesta = await autenticar(client)  # ahora con el PIN bueno

    assert respuesta.status_code == 423
    assert respuesta.json()["code"] == "IDENTIFIER_LOCKED"
    assert "locked_until" in respuesta.json()


async def test_el_bloqueo_sigue_al_dni_aunque_cambie_el_telefono(client):
    await registrar(client)
    for _ in range(3):
        await autenticar(client, pin="999999", device="telefono-1")

    # Otro teléfono, mismo DNI: si el contador viviera en el dispositivo, aquí
    # entraría.
    respuesta = await autenticar(client, device="telefono-2")

    assert respuesta.status_code == 423


async def test_bloquear_un_dni_no_bloquea_a_otro(client):
    await registrar(client)
    await registrar(client, dni="87654321", email="ana@correo.com")
    for _ in range(3):
        await autenticar(client, pin="999999", device="telefono-1")

    respuesta = await autenticar(client, dni="87654321", device="telefono-2")

    assert respuesta.status_code == 200
