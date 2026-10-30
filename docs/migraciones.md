# Migraciones versionadas (#40)

El servicio verifica que la base esté en la revisión Alembic actual. No ejecuta
`create_all` ni modifica tablas al arrancar. El operador aplica migraciones antes
del despliegue, con respaldo y restauración comprobados. Este cambio no ejecuta
comandos contra producción ni modifica el pipeline para hacerlo automáticamente.

Desde `services/api`, con `DATABASE_URL` en el entorno y dependencias instaladas:

```sh
# Base vacía nueva:
.venv/bin/python -m alembic upgrade head
# Consultar revisión actual y diferencias respecto al modelo:
.venv/bin/python -m alembic current
.venv/bin/python -m alembic check
```

Para adoptar una base anterior creada mediante `create_all`:

1. Respaldar y probar la restauración en una base aislada; registrar la revisión.
2. Pausar escrituras durante la adopción/migración.
3. Ejecutar `.venv/bin/python -m scripts.adopt_schema`. Compara el esquema con la
   instantánea inmutable `0001`, incluidos tipos, nulabilidad, defaults, claves,
   índices y predicados parciales y CHECK. Solo si coincide registra `0001`.
4. Ejecutar `.venv/bin/python -m alembic upgrade head` y `alembic check`.
5. Comprobar saldos/asientos, revisión y humo antes de reabrir las escrituras.

Una diferencia detiene la adopción. No usar `stamp head` para silenciarla ni
`reset_schema.py` para actualizar datos persistentes. Preparar una migración
específica tras identificar la revisión real. Las migraciones no corrigen datos
inconsistentes y nunca los borran para conseguir que un CHECK pase.

`0001` crea la base anterior; `0002` añade el rol (titular por defecto) y tablas
mínimas para integrar desembolso. Son operaciones explícitas e inmutables: no
importan los modelos vivos en las revisiones. Nuevos cambios requieren nuevas
revisiones, revisión del SQL y pruebas con datos previos. Los downgrades que
borrarían identidad, préstamos o roles están bloqueados: usar migración
correctiva o una restauración aprobada considerando escrituras posteriores.

En la imagen están Alembic, su configuración y revisiones; se pueden ejecutar
los mismos comandos con `python -m alembic`. El comando del servicio solo inicia
la API y verifica la revisión. La primera integración en producción requiere el
paso de adopción anterior antes de iniciar esta versión; no basta con aprobar CD.

Referencia de configuración: [documentación oficial de Alembic](https://alembic.sqlalchemy.org/en/latest/cookbook.html#using-asyncio-with-alembic).
SQLite usa BEGIN explícito para evitar confirmaciones accidentales al liberar
savepoints; [patrón oficial de SQLAlchemy](https://docs.sqlalchemy.org/en/20/dialects/sqlite.html#enabling-non-legacy-sqlite-transactional-modes-with-the-sqlite3-or-aiosqlite-driver).
