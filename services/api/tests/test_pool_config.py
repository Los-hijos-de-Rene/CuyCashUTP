import pytest
from pydantic import ValidationError
from app.core.config import Settings, settings
from app.db.base import pool_options, _engine_config


def test_pool_reads_configured_values(monkeypatch):
    monkeypatch.setattr(settings, "DB_POOL_SIZE", 3)
    monkeypatch.setattr(settings, "DB_MAX_OVERFLOW", 1)
    monkeypatch.setattr(settings, "DB_POOL_TIMEOUT", 12)
    url, args = _engine_config("postgresql://u:p@example.neon.tech/db?sslmode=require")
    assert args == {"ssl": True}
    assert pool_options(url) == {"pool_size": 3, "max_overflow": 1, "pool_timeout": 12}
    assert pool_options("sqlite+aiosqlite:///:memory:") == {}


@pytest.mark.parametrize("values", [{"DB_POOL_SIZE": 0}, {"DB_MAX_OVERFLOW": -1}, {"DB_POOL_TIMEOUT": 0}])
def test_pool_rejects_unbounded_config(values):
    with pytest.raises(ValidationError):
        Settings(**values)
