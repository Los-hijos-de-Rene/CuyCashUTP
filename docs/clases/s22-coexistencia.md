# Sesión 22 — ISO 25010: Coexistencia
PDF: `apf2/clases/diapositiva22.pdf` · Alimenta APF3

## Conceptos
- Definición: realizar sus funciones eficientemente compartiendo entorno con otros productos, **sin degradar** su rendimiento o estabilidad.
- Conflictos típicos: exceso de RAM/CPU, bloqueo de puertos, conflicto de librerías (DLL/Jar Hell), escritura en archivos comunes/temporales.
- Aislamiento: contenedores (Docker), VMs, namespaces del kernel.
- Gestión de recursos: *limits* en Docker/Kubernetes, pooling de conexiones a BD, monitoreo de ancho de banda.
- Independencia de instalación: sin cambiar el sistema base, desinstalar sin rastros, variables de entorno aisladas. Dependencias con gestor de paquetes, vendoring, virtualenv.
- Seguridad: permisos de archivo, no ejecutar como root, sandboxing.
- Métricas («buen vecino»): memoria tras 24 h (leaks), latencia de otros servicios en el host, frecuencia de crashes por conflictos.
- Checklist: contenedores, limpiar temporales, no asumir rutas fijas, configuración externa. Nube: multi-tenancy, auto-scaling sin agotar el host.

## Taller pedido
Librerías que podrían chocar; cómo asegurar que no se agote la memoria del servidor; ¿dos instancias en el mismo host?

## En CuyCash
Docker compose (`services/api`) con tope de 512 MB al KYC (igual que Render); pool de conexiones a Postgres; config por variables de entorno (`config.<env>.json`, `.env`). Dos instancias en el mismo host: puertos `8001` (API) configurables; no medido.
