# Ficha del proyecto

**Versión evaluada:** v2. Lo aún no ejecutado figura, con responsable, en «Plan de cierre» (Anexos).

| | |
|---|---|
| Repositorio | <https://github.com/Los-hijos-de-Rene/CuyCashUTP> |
| Producción (API) | <https://cuycashutp.onrender.com> · `GET /health` devuelve el commit desplegado |
| Tablero de trabajo | <https://github.com/orgs/Los-hijos-de-Rene/projects/1> |
| Commit en producción | `e226dd5` (verificado en `/health` el 05/11/2026); resultados de humo sobre `f9db8cd` |
| Corte y sustentación | 04/11/2026 · viernes 06/11/2026 |

## Equipo
| Integrante | Aporte en APF3 | Capítulo |
|---|---|---|
| Jair Pool Conislla Bocangel | Observaciones APF2, evidencia automática en CI, contrato app↔API, consolidación | A, anexos |
| Gian Piero Gonzales Flores | Pruebas funcionales y UAT | B |
| Jeremy Piero Rojas Egusquiza | Pruebas de integración con sistemas externos | C |
| Jheampierre Johayro Ralli Peralta | Suite automatizada de usabilidad | D |
| Jair Abdel Linares Carbajal | Sesión de usabilidad con usuarios | D.1 |
| Andersson Junior Espinoza Medina | Validación en la nube y coexistencia | E, C.7 |

## Resumen de resultados al corte
| Indicador | Resultado |
|---|---|
| Pruebas funcionales backend (PostgreSQL 16, CI) | 500 de 500 aprobadas · cobertura 96.41 % |
| Pruebas de la app (CI) | 973 aprobadas, 2 omitidas · cobertura 76.45 % |
| Integración y contrato | 47 de 47 aprobadas |
| Usabilidad automatizada | 39 de 39 aprobadas en 8 pantallas |
| Completitud funcional (ISO/IEC 25023) | 13 de 96 CA (13.5 %) |

## Correspondencia con la rúbrica
| Criterio | Sección | Artefactos |
|---|---|---|
| 1. Pruebas funcionales | B | B.1 Frameworks · B.2 Casos · B.3 Capturas · B.4 Cobertura · B.5 Métricas |
| 2. Integración | C | C.1 Sistemas · C.2 Frameworks · C.3 Casos · C.4 Capturas · C.5 Reportes · C.6 Métricas |
| 3. Usabilidad | D | D.1 Informe · D.2 Frameworks · D.3 Casos · D.4 Capturas · D.5 Reportes · D.6 Métricas |
| 4. Observaciones APF2 | A | Cuadro y evidencia |
| 5. Validación en Cloud | E | Humo, seguridad de borde, despliegue y UAT |
