# Esqueleto del PDF de entrega (#106)

Debe responder **explícitamente** a la rúbrica (`apf3/APF3.pdf`). Un capítulo
con todos sus artefactos numerados vale más que uno largo pero desordenado.

| Sección | Contenido | Fuente | Dueño |
|---|---|---|---|
| Portada y resumen | Equipo, URL de producción, commit v2, enlace al repo | `/health` | Jair C. |
| **A** Observaciones APF2 | Cuadro + evidencia | [capitulo-a-observaciones.md](capitulo-a-observaciones.md) | Jair C. |
| **B** Funcionales | B.1 Frameworks · B.2 Casos · B.3 Capturas · B.4 Cobertura · B.5 Métricas | [spec-gian-piero](spec-gian-piero-funcionales.md) | Gian Piero |
| **C** Integración | C.1 Sistemas · C.2 Frameworks · C.3 Casos · C.4 Capturas · C.5 Reportes · C.6 Métricas | [spec-jeremy](spec-jeremy-integracion.md) | Jeremy, Andersson |
| **D** Usabilidad | D.1 Informe · D.2 Frameworks · D.3 Casos · D.4 Capturas · D.5 Reportes · D.6 Métricas | specs de Jheampierre y Jair L. | Jheampierre, Jair L. |
| **E** Validación en la nube | URL, humo, UAT contra producción, SQL de cuadre | [spec-andersson](spec-andersson-cloud-y-coexistencia.md) | Andersson |
| Anexos | Enlaces: repo, workflows, scripts; acta UAT; matriz RTM | — | Jair C. |

## Lista de verificación contra la rúbrica
- [ ] B tiene los 5 artefactos rotulados B.1–B.5.
- [ ] C tiene los 6 rotulados C.1–C.6 y nombra cada sistema externo.
- [ ] D tiene los 6 rotulados D.1–D.6 (el informe D.1 es el de Jair L.).
- [ ] Cada capítulo tiene capturas **con fecha** y un % de cumplimiento.
- [ ] Enlaces al repo y a los scripts de automatización (obligatorio, ver guía §1).
- [ ] Capítulo A con el 100 % de observaciones y su evidencia.
- [ ] La v2 mostrada en la nube coincide con el commit del PDF.

## Cómo generar el PDF
Cada dueño redacta **su** capítulo en `docs/apf3/capitulos/` (ya están creados con
la numeración exacta de la rúbrica: `01-A`, `02-B`, `03-C`, `04-D`, `05-E`,
`06-anexos`) y reemplaza cada marca `PENDIENTE`. Las imágenes van en
`docs/apf3/evidencias/<nombre>/` y se enlazan con ruta relativa
(`![pytest](../evidencias/gian-piero/pytest.png)`).

```sh
scripts/apf3/build_pdf.sh            # genera build/APF3-CuyCash.pdf
```
Usa Python y Chrome sin cabeza (no hace falta LaTeX). El script informa cuántas
marcas `PENDIENTE` quedan: **deben ser 0 antes de entregar**.
