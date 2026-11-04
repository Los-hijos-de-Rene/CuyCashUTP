# Sesión 16 — Despliegue en la nube y pipelines CI/CD
PDF: `apf2/clases/diapositiva16.pdf` · Alimenta APF2 criterio 4

**Logro:** pipeline automatizado conectado al repo, con patrón Blue-Green o Canary hacia la nube.

## Conceptos
- **Requisito obligatorio APF2:** app desplegada y funcional en nube pública; cada merge a la rama principal actualiza producción v1.
- Pipeline: commit/PR → build & lint (SAST) → tests (unit/integration) → registry (imagen Docker) → deploy. Si falla un test, se aborta.
- CI valida en entorno limpio; CD orquesta el contenedor validado sin intervención humana.
- **Blue-Green:** dos entornos idénticos, el balanceador cambia el puntero; rollback instantáneo. **Canary:** 5–10 % del tráfico a la versión nueva. **Rolling:** reemplazo gradual, conviven dos versiones.
- **Paridad dev/prod (12-factor):** antipatrón SQLite local + PostgreSQL en prod. Docker asegura que lo probado en CI = lo desplegado.
- Secretos: nunca en Git; GitHub Encrypted Secrets o del proveedor. **Health check** (`/health`) antes de enrutar tráfico.
- Métricas DORA; metacognición: ¿rollback en < 2 min?

## Taller pedido
`.github/workflows/deploy.yml` en push a `main` con tests; despliegue a Render/Railway/AWS/Azure con secretos; `/health` + simulacro de commit fallido.

## En CuyCash
Ver `docs/despliegue.md`. Despliegue solo por GitHub Actions (`cd-backend.yml`, `rollback-backend.yml`, Render con autodeploy off); `GET /health` devuelve el commit.
Ojo: la clase critica SQLite-vs-Postgres; en CuyCash la suite local usa SQLite pero CI corre toda contra Postgres 16 (mitiga el antipatrón).
