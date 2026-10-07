#!/usr/bin/env bash
# Espera a que la API desplegada reporte el commit esperado en /health.
#
# Render construye la imagen y la cambia sin cortar el servicio: mientras
# tanto /health sigue respondiendo con la versión anterior. Cuando `version`
# es el commit pedido, el despliegue (o el rollback) terminó.
#
# Uso: esperar_version.sh <URL base> <sha completo> [minutos máx]

set -euo pipefail
BASE="$1"
SHA="$2"
MAX_MIN="${3:-20}"
fin=$(( $(date +%s) + MAX_MIN * 60 ))

while :; do
  actual=$(curl -s -m 60 "$BASE/health" | sed -n 's/.*"version":"\([^"]*\)".*/\1/p' || true)
  echo "$(date -u +%H:%M:%S)  en producción: ${actual:-<sin respuesta>}  esperado: $SHA"
  if [ "$actual" = "$SHA" ]; then
    echo "Despliegue listo."
    exit 0
  fi
  if [ "$(date +%s)" -ge "$fin" ]; then
    echo "::error::En ${MAX_MIN} min la API no llegó a $SHA. Revisa Events y Logs en Render: si el build falló, Render mantiene la versión anterior."
    exit 1
  fi
  sleep 20
done
