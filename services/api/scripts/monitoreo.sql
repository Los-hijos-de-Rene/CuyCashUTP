-- CuyCash · consultas de administración y monitoreo de la base en producción
-- (APF2 · criterio 3.4). Para la consola SQL de Neon o `psql "$DATABASE_URL"`.
-- Todas son de SOLO LECTURA.

-- 1. Tamaño de la base frente al tope del plan gratuito (0.5 GB por proyecto).
SELECT pg_size_pretty(pg_database_size(current_database())) AS tamano_base;

-- 2. Tamaño y filas por tabla (las de dinero deberían liderar).
SELECT relname                                         AS tabla,
       n_live_tup                                      AS filas_vivas,
       pg_size_pretty(pg_total_relation_size(relid))   AS tamano_total
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

-- 3. Conexiones abiertas por estado (el servicio usa un pool; muchas "idle"
--    sostenidas indican fuga de conexiones).
SELECT state, count(*) FROM pg_stat_activity
WHERE datname = current_database()
GROUP BY state;

-- 4. Consultas que llevan más de 5 s (posible bloqueo de fila retenido).
SELECT pid, now() - query_start AS duracion, state, left(query, 120) AS consulta
FROM pg_stat_activity
WHERE datname = current_database()
  AND state <> 'idle'
  AND now() - query_start > interval '5 seconds';

-- 5. Bloqueos en espera (el libro mayor usa SELECT … FOR UPDATE).
SELECT bloqueado.pid AS espera, bloqueante.pid AS retiene,
       left(bloqueado.query, 80) AS consulta_en_espera
FROM pg_stat_activity bloqueado
JOIN pg_stat_activity bloqueante
  ON bloqueante.pid = ANY (pg_blocking_pids(bloqueado.pid));

-- 6. Integridad del libro mayor: por cada transacción, débitos = créditos.
--    Debe devolver CERO filas.
SELECT transaction_id,
       sum(CASE WHEN direccion = 'debito'  THEN monto ELSE 0 END) AS debitos,
       sum(CASE WHEN direccion = 'credito' THEN monto ELSE 0 END) AS creditos
FROM ledger_entries
GROUP BY transaction_id
HAVING sum(CASE WHEN direccion = 'debito'  THEN monto ELSE 0 END)
    <> sum(CASE WHEN direccion = 'credito' THEN monto ELSE 0 END);

-- 7. Integridad del saldo: la columna (caché) coincide con la suma de asientos.
--    Debe devolver CERO filas.
SELECT a.id, a.numero, a.saldo_contable,
       coalesce(sum(CASE WHEN e.direccion = 'credito' THEN e.monto ELSE -e.monto END), 0) AS segun_asientos
FROM accounts a
LEFT JOIN ledger_entries e ON e.account_id = a.id
GROUP BY a.id, a.numero, a.saldo_contable
HAVING a.saldo_contable
    <> coalesce(sum(CASE WHEN e.direccion = 'credito' THEN e.monto ELSE -e.monto END), 0);

-- 8. Actividad de seguridad de las últimas 24 h: intentos fallidos y bloqueos.
SELECT count(*) FILTER (WHERE succeeded = false) AS intentos_fallidos,
       count(*) FILTER (WHERE succeeded = true)  AS ingresos
FROM login_attempts
WHERE created_at > now() - interval '24 hours';

SELECT subject_type, count(*) AS bloqueos_vigentes
FROM lockouts
WHERE locked_until > now()
GROUP BY subject_type;
