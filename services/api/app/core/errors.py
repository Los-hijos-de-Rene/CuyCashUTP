from typing import Any, Dict, Optional

from fastapi import HTTPException, status


class ErrorCode:
    """
    Códigos estables, independientes del texto.

    Existen porque el servicio de KYC enseñó la lección al revés: allí los
    casos de negocio se distinguen leyendo el `detail` en español, así que
    reescribir un mensaje rompe al cliente en silencio. Aquí el cliente
    programa contra `code` y el `detail` queda libre para redactarse mejor.
    """

    INVALID_CREDENTIALS = "INVALID_CREDENTIALS"
    IDENTIFIER_LOCKED = "IDENTIFIER_LOCKED"
    DEVICE_LOCKED = "DEVICE_LOCKED"
    IDENTIFIER_TAKEN = "IDENTIFIER_TAKEN"
    WEAK_PIN = "WEAK_PIN"
    PIN_UNCHANGED = "PIN_UNCHANGED"
    CHALLENGE_EXPIRED = "CHALLENGE_EXPIRED"
    CHALLENGE_CANCELLED = "CHALLENGE_CANCELLED"
    INVALID_TICKET = "INVALID_TICKET"
    UNAUTHENTICATED = "UNAUTHENTICATED"
    SERVICE_UNAVAILABLE = "SERVICE_UNAVAILABLE"
    ACCOUNT_NOT_FOUND = "ACCOUNT_NOT_FOUND"
    MOVEMENT_NOT_FOUND = "MOVEMENT_NOT_FOUND"
    INSUFFICIENT_FUNDS = "INSUFFICIENT_FUNDS"
    IDEMPOTENCY_KEY_REUSED = "IDEMPOTENCY_KEY_REUSED"


class ApiError(HTTPException):
    def __init__(
        self,
        code: str,
        detail: str,
        status_code: int = status.HTTP_400_BAD_REQUEST,
        extra: Optional[Dict[str, Any]] = None,
    ):
        payload: Dict[str, Any] = {"code": code, "detail": detail}
        if extra:
            payload.update(extra)
        super().__init__(status_code=status_code, detail=payload)
