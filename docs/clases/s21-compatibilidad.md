# Sesión 21 — ISO 25010: Compatibilidad
PDF: `apf2/clases/diapositiva21.pdf` (20 láminas, poco texto) · Alimenta APF3

## Conceptos
- Compatibilidad = **coexistencia** (compartir recursos sin impacto negativo) + **interoperabilidad** (intercambiar información y usarla correctamente).
- Estándares: protocolos HTTP/HTTPS, REST, gRPC, SOAP; datos JSON, XML, Protobuf, CSV.
- Diseño de API interoperable: documentación Swagger/OpenAPI, **versionamiento** (v1, v2), contratos estables.
- Sistemas legados: tecnologías obsoletas, APIs sin documentar → adaptadores/middleware.
- Si falla: pérdida de datos, efecto cascada, inconsistencia de procesos.
- Pruebas: de contrato (consumer-driven), mocks/stubs de integración, caja negra con servicios externos.
- Métricas: tasa de fallos de comunicación (errores de API), tiempo de integración de un sistema nuevo, número de estándares implementados.
- Prácticas: API pensada para el consumidor, manejo robusto de errores de red (retries, timeouts), desacoplamiento (message brokers).

## Taller pedido
Listar sistemas externos, un riesgo de interoperabilidad por cada uno, plan de mitigación (p. ej. API Gateway).

## En CuyCash
Externos reales: microservicio KYC (`CuyCashKYC`, vía proxy; ADR 0001), Render/Postgres, ML Kit/`local_auth` en el teléfono. La API ya está versionada (`/v1/...`). No hay pasarelas de pago ni interbancario.
