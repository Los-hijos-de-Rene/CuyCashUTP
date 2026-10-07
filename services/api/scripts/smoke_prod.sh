#!/usr/bin/env bash
# Prueba de humo del despliegue (APF2 · criterio 3.3).
#
# SOLO LECTURA: no registra usuarios ni mueve dinero, así que se puede correr
# contra producción cuantas veces haga falta. Cada línea dice qué se esperaba
# y qué llegó; termina con código 1 si algo no cuadra.
#
# Uso:  scripts/smoke_prod.sh [URL]      (por defecto, el servicio de Render)

set -u
BASE="${1:-https://cuycashutp.onrender.com}"
HOST="${BASE#https://}"
fallos=0

check() { # descripción, esperado, obtenido
  if [ "$2" = "$3" ]; then echo "OK    $1 ($3)"; else echo "FALLO $1: esperaba $2, llegó $3"; fallos=$((fallos+1)); fi
}

echo "== $BASE  $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# El plan gratuito duerme el servicio: la primera petición puede tardar ~1 min.
codigo=$(curl -s -m 90 -o /dev/null -w '%{http_code}' "$BASE/health")
check "API viva (/health)" 200 "$codigo"
echo "      versión desplegada: $(curl -s -m 30 "$BASE/health" | sed -n 's/.*"version":"\([^"]*\)".*/\1/p')"

cuerpo=$(curl -s -m 60 "$BASE/health/db")
check "Base de datos responde (/health/db)" ok "$(echo "$cuerpo" | sed -n 's/.*"status":"\([a-z]*\)".*/\1/p')"
echo "      $cuerpo"

check "HTTP redirige a HTTPS" 301 "$(curl -s -m 30 -o /dev/null -w '%{http_code}' "http://$HOST/health")"
check "Ruta protegida sin token" 401 "$(curl -s -m 30 -o /dev/null -w '%{http_code}' "$BASE/v1/me")"
check "Token inventado" 401 "$(curl -s -m 30 -o /dev/null -w '%{http_code}' -H 'Authorization: Bearer inventado' "$BASE/v1/accounts")"

cabeceras=$(curl -sI -m 30 "$BASE/health" | tr -d '\r' | tr 'A-Z' 'a-z')
for c in strict-transport-security x-content-type-options x-frame-options; do
  if echo "$cabeceras" | grep -q "^$c:"; then echo "OK    cabecera $c"; else echo "FALLO falta la cabecera $c"; fallos=$((fallos+1)); fi
done
if echo "$cabeceras" | grep -q "^access-control-allow-origin:"; then
  echo "FALLO la API concede CORS"; fallos=$((fallos+1))
else
  echo "OK    sin CORS abierto"
fi

tiempo=$(curl -s -m 30 -o /dev/null -w '%{time_total}' "$BASE/health")
echo "INFO  latencia de /health en caliente: ${tiempo}s"

echo "== $fallos fallo(s)"
[ "$fallos" -eq 0 ]
