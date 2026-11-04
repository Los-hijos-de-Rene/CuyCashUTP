import pytest
from httpx import ASGITransport, AsyncClient
from pydantic import ValidationError
from app.core.config import Settings


@pytest.mark.parametrize("origin", ["*", "https://*.example.test", "https://panel.test/", "null", "https://u:p@panel.test", "https://panel.test?x=1"])
def test_reject_unsafe_origins(origin):
    with pytest.raises(ValidationError):
        Settings(ADMIN_CORS_ORIGINS=origin)


async def test_exact_origin_and_read_only_preflight():
    from app.core.config import settings
    # Misma configuración de middleware que registra la aplicación real.
    from importlib import reload
    import app.main as main
    previous = settings.ADMIN_CORS_ORIGINS
    try:
        settings.ADMIN_CORS_ORIGINS = "https://panel.example.test"
        configured = reload(main).app
        async with AsyncClient(transport=ASGITransport(app=configured), base_url="http://test") as client:
            for origin, allowed in [("https://panel.example.test", True), ("https://panel.example.test.evil.test", False), ("http://panel.example.test", False)]:
                response = await client.options("/v1/admin/registrations", headers={"Origin": origin, "Access-Control-Request-Method": "GET", "Access-Control-Request-Headers": "authorization"})
                assert response.status_code == (200 if allowed else 400)
                assert response.headers.get("access-control-allow-origin") == (origin if allowed else None)
            response = await client.options("/v1/admin/registrations", headers={"Origin": "https://panel.example.test", "Access-Control-Request-Method": "POST"})
            assert response.status_code == 400
            response = await client.get("/v1/admin/registrations", headers={"Origin": "https://panel.example.test"})
            assert response.status_code == 401
    finally:
        settings.ADMIN_CORS_ORIGINS = previous
        reload(main)
