
# APF3-C — Informe de pruebas de integración

**Proyecto:** CuyCashUTP
**Responsable:** jeremy16R
**Issue:** #100
**Fecha:** 4 de noviembre de 2026

## 1. Objetivo

Verificar la integración del backend con los servicios de
Telegram, KYC y base de datos, comprobando respuestas exitosas,
errores controlados, protección de información y recuperación
de conexiones.

## 2. Herramientas utilizadas

- Python 3.12.10
- pytest 8.3.3
- pytest-asyncio 0.24.0
- httpx.MockTransport
- SQLAlchemy
- SQLite para pruebas locales
- PostgreSQL 16 configurado en GitHub Actions
- pytest-cov para métricas de cobertura

## 3. Sistemas externos y compatibilidad

| Sistema | Integración | Validación |
|---|---|---|
| Telegram | Envío de OTP mediante API HTTP | MockTransport: éxito, fallos y seguridad |
| Servicio KYC | Verificación de identidad y DNI | MockTransport: reintentos, contrato y tickets |
| PostgreSQL 16 | Persistencia de datos | CI configurado; reconexión pendiente de confirmar |
| Neon | PostgreSQL gestionado | Configuración revisada; sin prueba directa contra Neon |
| Render | Alojamiento del servicio KYC | Escenarios de fallo simulados |
| ML Kit / local_auth | Funciones de la aplicación móvil | Fuera del alcance de esta batería backend |
| GitHub Actions | Integración continua | Configuración PostgreSQL 16 verificada |

## 4. Resultados locales

| Grupo | Aprobadas | Omitidas |
|---|---:|---:|
| Telegram | 9 | 0 |
| KYC | 20 | 0 |
| Base de datos | 2 | 1 |
| Total | 31 | 1 |

Pruebas fallidas: 0.

Suite completa del backend:
510 aprobadas, 7 omitidas y 22 advertencias.

## 5. Incidencias detectadas y corregidas

- Telegram: se detectó que una excepción podía revelar
  el token del bot en los registros. Se corrigió el manejo
  de errores y se comprobó mediante pruebas automatizadas.
- KYC: se detectó que un JSON malformado podía llegar al
  cliente con HTTP 200. Se añadió validación de respuestas
  exitosas y un error controlado HTTP 502.

## 6. Cobertura de código

| Módulo | Cobertura |
|---|---:|
| app/services/notifier.py | 97 % |
| app/api/v1/routers/kyc.py | 94 % |
| app/services/kyc_tickets.py | 72 % |
| app/db/base.py | 70 % |
| Total seleccionado | 85 % |

El 85 % corresponde solamente a estos cuatro módulos,
no a la cobertura global del backend.

## 7. Limitaciones

Telegram y KYC se probaron con respuestas simuladas,
sin realizar llamadas a sus servicios reales.

Las pruebas D1 y D2 se ejecutaron localmente usando SQLite
y simulación de fallos, respectivamente.

La prueba D3 requiere PostgreSQL real y fue omitida en
Windows. GitHub Actions dispone de PostgreSQL 16, pero
su resultado debe verificarse después de subir la rama.

## 8. Evidencias

- junit-telegram.xml
- junit-integracion-kyc-telegram.xml
- junit-integracion-final.xml
- coverage-integracion.xml
- Capturas de terminal de las pruebas ejecutadas

## 9. Conclusión

Las pruebas locales de Telegram, KYC y salud de base de
datos finalizaron sin fallos. Se identificaron y corrigieron
dos defectos mediante pruebas automatizadas.

Queda pendiente confirmar INT-D3 con PostgreSQL 16 y
verificar el resultado final de GitHub Actions.
