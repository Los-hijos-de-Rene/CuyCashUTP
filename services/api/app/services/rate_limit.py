"""
Tope de consultas de destinatario por usuario.

POR QUÉ EXISTE. Toda ruta que contesta "¿este DNI es cliente de CuyCash?"
-- `GET /v1/directory/resolve`, la búsqueda del destinatario de
`POST /v1/transfers` y el alta de `POST /v1/beneficiaries` -- es un oráculo del
padrón: iterando DNIs se arma el mapa de quién es cliente. La de transferencias
era la peor, porque responde 404 ANTES de verificar el PIN y por tanto no gasta
intentos de bloqueo.

UN SOLO PRESUPUESTO, NO UNO POR RUTA. Si cada ruta tuviera su contador, el
atacante gastaría el cupo de una y seguiría con la otra: el límite efectivo
sería la suma y bastaría con que una ruta quedara sin límite para anularlo.
Todas las rutas llaman a `consumir_consulta_de_destinatario`, que descuenta del
mismo cubo.

POR QUÉ POR USUARIO Y NO POR SESIÓN. Cerrar sesión y volver a entrar crea una
sesión nueva; un tope por sesión se reiniciaría con cada login y sería
decorativo. El `user_id` sobrevive a eso.

QUÉ PROTEGE HOY. Un contador en un dict del proceso: frena a un titular que
itera DNIs contra UN proceso en marcha (20 consultas cada 10 minutos, unas
2 880 al día por cuenta).

QUÉ NO PROTEGE (limitaciones conocidas, no implementadas a propósito):
- Varias réplicas: cada proceso tiene su contador, así que el cupo real es
  CUPO x N réplicas y el balanceador reparte las peticiones entre ellos.
- Reinicios y despliegues: el contador se pierde; Render reinicia el servicio
  al desplegar y al dormir el plan gratuito, y eso devuelve el cupo completo.
- Cuentas múltiples: el tope es por usuario; quien registre muchas cuentas
  tiene un cupo por cada una. Lo frena el costo del registro (KYC/OTP), no
  este módulo.
Para que proteja de verdad hace falta un contador compartido y durable: una
tabla en Postgres (fila por usuario y ventana, `INSERT ... ON CONFLICT DO
UPDATE` y comprobar el total en la misma sentencia) o Redis (`INCR` + `EXPIRE`
sobre `lookups:{user_id}`). La interfaz de abajo está pensada para sustituirse
sin tocar los routers.

CONCURRENCIA. `consumir` es síncrona y sin `await`: dentro del bucle de eventos
de un proceso es atómica. Si se moviera a hilos habría que añadir un cerrojo.
"""

import time
from collections import deque
from typing import Callable, Deque, Dict

from fastapi import status

from app.core.errors import ApiError, ErrorCode

CONSULTAS_MAXIMAS = 20
VENTANA_SEGUNDOS = 600

# Por encima de este número de claves se barren las ventanas ya vencidas, para
# que el dict no crezca con cada usuario que consultó una sola vez.
_BARRIDO_DESDE = 10_000


class VentanaDeslizante:
    def __init__(
        self,
        maximo: int,
        ventana_segundos: float,
        reloj: Callable[[], float] = time.monotonic,
    ) -> None:
        self.maximo = maximo
        self.ventana = ventana_segundos
        self._reloj = reloj
        self._marcas: Dict[str, Deque[float]] = {}

    def _podar(self, marcas: Deque[float], ahora: float) -> None:
        while marcas and ahora - marcas[0] >= self.ventana:
            marcas.popleft()

    def _barrer(self, ahora: float) -> None:
        for clave in list(self._marcas):
            marcas = self._marcas[clave]
            self._podar(marcas, ahora)
            if not marcas:
                del self._marcas[clave]

    def consumir(self, clave: str) -> int:
        """
        Descuenta una consulta. Devuelve 0 si cabía, o los segundos que faltan
        para que se libere cupo. Una consulta rechazada NO se anota: si se
        anotara, insistir mantendría el bloqueo para siempre.
        """
        ahora = self._reloj()
        if len(self._marcas) > _BARRIDO_DESDE:
            self._barrer(ahora)
        marcas = self._marcas.setdefault(clave, deque())
        self._podar(marcas, ahora)
        if len(marcas) >= self.maximo:
            return max(1, int(self.ventana - (ahora - marcas[0])) + 1)
        marcas.append(ahora)
        return 0

    def reiniciar(self) -> None:
        self._marcas.clear()


# El presupuesto compartido. Único a propósito: ver el docstring del módulo.
_consultas_de_destinatario = VentanaDeslizante(CONSULTAS_MAXIMAS, VENTANA_SEGUNDOS)


def consumir_consulta_de_destinatario(user_id: str) -> None:
    """
    Descuenta una consulta de destinatario del presupuesto del usuario o lanza
    429 `RATE_LIMITED`. Llamarla ANTES de tocar la tabla de usuarios: el 404 y
    el 200 deben costar lo mismo, o el tope solo frenaría los aciertos.
    """
    espera = _consultas_de_destinatario.consumir(user_id)
    if espera:
        raise ApiError(
            ErrorCode.RATE_LIMITED,
            "Hiciste demasiadas búsquedas de destinatario. Espera un momento.",
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            extra={"retry_after_seconds": espera},
        )


def reiniciar_para_pruebas() -> None:
    _consultas_de_destinatario.reiniciar()
