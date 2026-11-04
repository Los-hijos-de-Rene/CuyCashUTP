# Sesión 13 — Seguridad de la información y controles
PDF: `apf2/clases/diapositivas13.pdf` · Alimenta APF2 criterio 2

**Logro:** diseñar e implementar controles técnicos (cifrado, JWT/OAuth, mitigación OWASP).

## Conceptos
- **CIA:** Confidencialidad (cifrado, permisos), Integridad (hashing, auditorías), Disponibilidad (backups, redundancia, anti-DDoS).
- **AuthN** = ¿quién eres? (contraseña, biometría, MFA, OTP). **AuthZ** = ¿qué puedes hacer? (RBAC roles, ABAC atributos, CORS).
- **JWT** (RFC 7519): header.payload.signature en Base64Url; *stateless*; la firma evita manipulación pero **no cifra** el payload. Sin expiración = vulnerabilidad.
- **OWASP Top 10 (mínimo a mitigar):** inyección SQL (prepared statements/ORM), pérdida de autenticación (JWT sin expiración, sin MFA), XSS (sanitizar), exposición de datos sensibles (HTTP sin TLS).
- **Cifrado vs hashing:** cifrado bidireccional (AES-256, RSA; datos y TLS). Hashing unidireccional para contraseñas (Bcrypt/Argon2 con salt). **Nunca MD5/SHA1**; «cifrar» contraseñas es error crítico.
- **Secretos:** nunca en Git; `.env` en `.gitignore`; el proveedor cloud los inyecta en runtime; debe existir rotación sin reescribir la app.

## Taller pedido
1. Flujo de autenticación (qué va en el payload, expiración). 2. Matriz RBAC con 3 roles y endpoints. 3. Cómo el framework mitiga SQLi y XSS.

## En CuyCash
Ver `docs/seguridad.md`, `docs/catalogo-controles.md`, `docs/apf2-cumplimiento.md`.

**Revisado contra `docs/seguridad.md` y `services/api` (2026-10-20):**
- **No hay JWT.** Hay token de sesión opaco: `secrets.token_urlsafe(32)` (256 bits), la BD guarda solo su SHA-256 (`app/core/security.py`, `app/services/sessions.py`).
- **Expiración: sí.** `SESSION_TTL_SECONDS` = 30 días, deslizante (`config.py:19`, `sessions.py:46`).
- **Hash de contraseña/PIN:** argon2id (cumple «Bcrypt/Argon2»). Descartes: MD5/SHA1 no se usan para PIN.
- **Revocación inmediata** (cambio de PIN, desvincular teléfono): posible justamente por ser token opaco; con JWT stateless no lo sería.
- **RBAC:** un solo rol (titular sobre sus recursos, `current_user`); roles operador/admin quedan pendientes por diseño. La clase pide matriz de **3 roles**: es la brecha real.
- **OWASP:** SQLi (ORM parametrizado), XSS (API JSON + `nosniff`, cliente nativo), HSTS, pip-audit, ZAP: cubiertos.
- **S14 (brechas declaradas):** sin rate limit por IP/WAF; logs sin estructura JSON ni correlation ID; CORS cerrado (sin lista blanca aún).
- **Defensa ante el docente:** token opaco server-side es una alternativa aceptada a JWT (OWASP lo recomienda para sesiones revocables); justificarla por escrito en `seguridad.md` («no JWT» ya aparece en §2). Si la rúbrica literal exige JWT, preguntarlo al docente.
