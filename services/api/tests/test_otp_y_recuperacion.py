from tests.test_registro_y_login import DEVICE, DNI, PIN, autenticar, registrar

EMAIL = "juan@correo.com"


async def abrir_reto(client, purpose="recovery", identifier=EMAIL):
    respuesta = await client.post(
        "/v1/otp/challenges", json={"purpose": purpose, "identifier": identifier}
    )
    return respuesta.json()


async def verificar(client, challenge_id, code):
    return await client.post(
        f"/v1/otp/challenges/{challenge_id}/verify", json={"code": code}
    )


async def test_la_respuesta_es_identica_exista_o_no_la_cuenta(client, otp_codes):
    await registrar(client)

    con_cuenta = await abrir_reto(client, identifier=EMAIL)
    sin_cuenta = await abrir_reto(client, identifier="nadie@correo.com")

    # Mismos campos y misma forma: decir "ese correo no existe" permitiría
    # averiguar qué cuentas hay probando correos.
    assert con_cuenta.keys() == sin_cuenta.keys()
    assert sin_cuenta["masked_email"] == "n•••••@correo.com"
    # Pero el código solo se envía si hay a quién.
    assert len(otp_codes) == 1


async def test_el_codigo_correcto_entrega_un_ticket_y_se_consume(client, otp_codes):
    await registrar(client)
    reto = await abrir_reto(client)
    code = otp_codes[0]["code"]

    primera = await verificar(client, reto["challenge_id"], code)
    segunda = await verificar(client, reto["challenge_id"], code)

    assert primera.status_code == 200
    assert primera.json()["otp_ticket"]
    # Un código de un solo uso no se puede reutilizar.
    assert segunda.json()["code"] == "CHALLENGE_EXPIRED"


async def test_el_codigo_equivocado_descuenta_intentos(client, otp_codes):
    await registrar(client)
    reto = await abrir_reto(client)

    respuesta = await verificar(client, reto["challenge_id"], "000000")

    assert respuesta.json()["code"] == "INVALID_CREDENTIALS"
    assert respuesta.json()["attempts_left"] == 2


async def test_tres_codigos_malos_cancelan_el_flujo_sin_reenvio(client, otp_codes):
    await registrar(client)
    reto = await abrir_reto(client)
    for _ in range(3):
        respuesta = await verificar(client, reto["challenge_id"], "000000")

    assert respuesta.json()["code"] == "CHALLENGE_CANCELLED"
    assert respuesta.json()["reason"] == "attempts"

    # Después de cancelar NO hay camino de reenvío.
    reenvio = await client.post(f"/v1/otp/challenges/{reto['challenge_id']}/resend")
    assert reenvio.json()["code"] == "CHALLENGE_CANCELLED"


async def test_tras_cancelar_el_identificador_queda_enfriado(client, otp_codes):
    await registrar(client)
    reto = await abrir_reto(client)
    for _ in range(3):
        await verificar(client, reto["challenge_id"], "000000")

    nuevo = await client.post(
        "/v1/otp/challenges", json={"purpose": "recovery", "identifier": EMAIL}
    )

    assert nuevo.json()["code"] == "CHALLENGE_CANCELLED"


async def test_reenviar_cambia_el_codigo_y_reinicia_el_vencimiento(client, otp_codes):
    await registrar(client)
    reto = await abrir_reto(client)
    primero = otp_codes[0]["code"]

    await client.post(f"/v1/otp/challenges/{reto['challenge_id']}/resend")

    assert len(otp_codes) == 2
    segundo = otp_codes[1]["code"]
    # El código viejo deja de servir.
    fallido = await verificar(client, reto["challenge_id"], primero)
    assert fallido.json()["code"] == "INVALID_CREDENTIALS"
    assert (await verificar(client, reto["challenge_id"], segundo)).status_code == 200


async def test_restablecer_el_pin_revoca_todas_las_sesiones(client, otp_codes):
    await registrar(client)
    # Se abre una sesión: teléfono verificado por OTP de dispositivo.
    pendiente = (await autenticar(client)).json()["pending_token"]
    reto_disp = await abrir_reto(client, purpose="device", identifier=DNI)
    ticket_disp = (
        await verificar(client, reto_disp["challenge_id"], otp_codes[-1]["code"])
    ).json()["otp_ticket"]
    sesion = await client.post(
        "/v1/auth/sessions",
        json={"pending_token": pendiente, "otp_ticket": ticket_disp},
        headers={"X-Device-Id": DEVICE},
    )
    assert sesion.status_code == 200

    reto = await abrir_reto(client)
    ticket = (
        await verificar(client, reto["challenge_id"], otp_codes[-1]["code"])
    ).json()["otp_ticket"]
    respuesta = await client.post(
        "/v1/auth/pin/reset", json={"otp_ticket": ticket, "new_pin": "314159"}
    )

    # Cambiar el PIN cierra TODAS las sesiones, incluida la de este teléfono:
    # restablecer no otorga acceso.
    assert respuesta.json()["revoked_sessions"] == 1
    # Y el PIN nuevo sí sirve para entrar.
    assert (await autenticar(client, pin="314159")).status_code == 200


async def test_el_pin_igual_al_actual_se_rechaza(client, otp_codes):
    await registrar(client)
    reto = await abrir_reto(client)
    ticket = (
        await verificar(client, reto["challenge_id"], otp_codes[-1]["code"])
    ).json()["otp_ticket"]

    respuesta = await client.post(
        "/v1/auth/pin/reset", json={"otp_ticket": ticket, "new_pin": PIN}
    )

    assert respuesta.json()["code"] == "PIN_UNCHANGED"


async def test_no_se_puede_cambiar_el_pin_sin_pasar_por_el_codigo(client):
    await registrar(client)

    respuesta = await client.post(
        "/v1/auth/pin/reset", json={"otp_ticket": "inventado", "new_pin": "314159"}
    )

    assert respuesta.status_code == 401
    assert respuesta.json()["code"] == "INVALID_TICKET"


async def test_check_current_exige_ticket_y_tiene_tope(client, otp_codes):
    await registrar(client)
    reto = await abrir_reto(client)
    ticket = (
        await verificar(client, reto["challenge_id"], otp_codes[-1]["code"])
    ).json()["otp_ticket"]

    actual = await client.post(
        "/v1/auth/pin/check-current", json={"otp_ticket": ticket, "pin": PIN}
    )
    otro = await client.post(
        "/v1/auth/pin/check-current", json={"otp_ticket": ticket, "pin": "314159"}
    )

    assert actual.json()["is_current"] is True
    assert otro.json()["is_current"] is False

    # Sin tope sería un oráculo del PIN: se agota el ticket.
    for _ in range(5):
        ultima = await client.post(
            "/v1/auth/pin/check-current", json={"otp_ticket": ticket, "pin": "000001"}
        )
    assert ultima.status_code == 401
