#!/usr/bin/env bash
# Genera el PDF de entrega de APF3 uniendo docs/apf3/capitulos/*.md en orden.
# Usa Python (markdown) y Chrome sin cabeza: no necesita LaTeX ni pandoc.
#
# Uso:  scripts/apf3/build_pdf.sh [salida.pdf]      (por defecto build/APF3-CuyCash.pdf)
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"
SALIDA="${1:-$RAIZ/build/APF3-CuyCash.pdf}"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
[ -x "$CHROME" ] || CHROME="$(command -v google-chrome || command -v chromium || true)"
[ -n "$CHROME" ] || { echo "No encontré Chrome/Chromium (variable CHROME)."; exit 1; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
python3 -m venv "$TMP/venv"
"$TMP/venv/bin/pip" install -q "markdown>=3.5,<4"
mkdir -p "$(dirname "$SALIDA")"

"$TMP/venv/bin/python" - "$RAIZ" "$TMP/APF3.html" <<'PY'
import sys, pathlib, re, markdown
raiz, destino = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
caps = sorted((raiz / "docs/apf3/capitulos").glob("[0-9]*.md"))
if not caps:
    sys.exit("No hay capítulos en docs/apf3/capitulos/")
md = markdown.Markdown(extensions=["tables", "fenced_code", "toc", "sane_lists"])
partes, pendientes = [], 0
for c in caps:
    texto = c.read_text(encoding="utf-8")
    pendientes += len(re.findall(r"PENDIENTE", texto))
    # Las imágenes relativas (evidencias/...) se resuelven desde la carpeta del capítulo.
    html = md.reset().convert(texto)
    html = re.sub(r'src="(?!https?:|file:|data:)([^"]+)"',
                  lambda m: f'src="file://{(c.parent / m.group(1)).resolve()}"', html)
    partes.append(f'<section class="capitulo">{html}</section>')
css = """
@page { size: A4; margin: 18mm 16mm; }
body { font: 10.5pt/1.45 -apple-system, "Segoe UI", Helvetica, Arial, sans-serif; color: #1b1f23; }
h1 { font-size: 20pt; border-bottom: 2px solid #1a6b4a; padding-bottom: 4px; }
h2 { font-size: 14pt; color: #1a6b4a; margin-top: 18px; } h3 { font-size: 11.5pt; }
section.capitulo { page-break-before: always; } section.capitulo:first-of-type { page-break-before: avoid; }
table { border-collapse: collapse; width: 100%; font-size: 8.8pt; margin: 8px 0; page-break-inside: auto; }
th, td { border: 1px solid #c9d1d9; padding: 3px 5px; vertical-align: top; } th { background: #eef4f1; }
tr { page-break-inside: avoid; } code { font: 8.8pt Menlo, monospace; background: #f3f4f6; padding: 0 2px; }
pre { background: #f3f4f6; padding: 6px; overflow-wrap: anywhere; white-space: pre-wrap; font-size: 8.5pt; }
img { max-width: 100%; border: 1px solid #d0d7de; } blockquote { border-left: 3px solid #1a6b4a; margin-left: 0; padding-left: 10px; color: #444; }
"""
destino.write_text(f'<!doctype html><meta charset="utf-8"><title>APF3 CuyCash</title><style>{css}</style>' + "".join(partes), encoding="utf-8")
print(f"{len(caps)} capítulos; marcas PENDIENTE sin resolver: {pendientes}", file=sys.stderr)
PY

"$CHROME" --headless=new --disable-gpu --no-pdf-header-footer --print-to-pdf="$SALIDA" "file://$TMP/APF3.html" >/dev/null 2>&1
echo "PDF: $SALIDA"
