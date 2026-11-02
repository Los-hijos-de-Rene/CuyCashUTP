# Sesión 14 — Mecanismos de seguridad, trazabilidad y defensa web
PDF: `apf2/clases/diapositivas14.pdf` · Alimenta APF2 criterio 2

**Logro:** mecanismos avanzados de defensa y trazabilidad (cifrado asimétrico, CORS/CSP, auditoría).

## Conceptos
- **Simétrico** (una llave, rápido, AES-256) vs **asimétrico** (par pública/privada, lento, RSA/ECC).
- **TLS/HTTPS:** handshake asimétrico → llave de sesión simétrica → tráfico con AES. Mejor práctica: nunca aceptar puerto 80; redirigir a 443 con **HSTS** desde el balanceador.
- **CORS:** cabecera `Access-Control-Allow-Origin` en el back; lista blanca. Error típico: `Origin: *` en producción. Poner orígenes exactos.
- **XSS / CSP:** sanitizar/escapar entradas (React/Angular lo hacen por defecto); CSP restringe de dónde cargar scripts (bloquear *inline*).
- **Trazabilidad:** ¿quién hizo qué, cuándo, cómo falló? Logs **estructurados JSON**, **Correlation ID** (UUID desde el front que viaja por todos los servicios), agregador (ELK, Splunk, Datadog).
- **Rate limiting** (p. ej. 5 logins/min, en gateway o middleware/Redis) y **WAF** (Cloudflare, AWS WAF).
- Metacognición: asumir red interna comprometida (Zero Trust).

## Taller pedido
1. Dominios CORS exactos (demostrar en código). 2. Herramienta de logs y ejemplo JSON de «Error de Autenticación». 3. Endpoint más crítico y su límite de tasa (req/min).

## En CuyCash
Ver `docs/seguridad.md` y `docs/catalogo-controles.md`. El bloqueo por intentos
(login/acceso rápido) ya existe (`IDENTIFIER_MAX_ATTEMPTS`); verificar ahí CORS, logs y rate limit.
